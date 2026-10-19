#!/usr/bin/env bash
# Sort a branch's changed files into the areas a PR blast radius covers.
#
# Usage: scan.sh [base-ref]
#
# Compares the merge base of base-ref (default: the repository's default
# branch on origin) with HEAD. Prints changed files grouped by area, then
# signals from the diff itself: Convex schema edits, migrations, data calls
# in front-end code, new dependencies and environment variables.
set -euo pipefail

base="${1:-}"
if [ -z "$base" ]; then
  default="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  base="${default:-origin/main}"
fi
if ! git rev-parse --verify --quiet "$base" >/dev/null; then
  echo "Base '$base' not found. Pass the PR's base branch, e.g. scan.sh origin/main." >&2
  exit 1
fi

range="$(git merge-base "$base" HEAD)...HEAD"
files="$(git diff --name-only "$range")"

echo "Base: $base"
echo "Commits: $(git rev-list --count "$range")"
if [ -n "$(git status --porcelain)" ]; then
  echo "Warning: uncommitted changes aren't included. Commit them first if they belong in the PR."
fi
echo

if [ -z "$files" ]; then
  echo "No changes against $base."
  exit 0
fi

# grep -q on a here-string, not a pipe: with pipefail, a pipe can fail when
# grep exits early.
has() { grep -qE "$1" <<< "$2"; }

# A file defines the Convex database schema if either side of the diff calls
# defineSchema or defineTable. Per-module `schemas.ts` files that only hold
# argument validators don't count.
defines_tables() {
  local both
  both="$(git show "$base:$1" 2>/dev/null || true; cat "$1" 2>/dev/null || true)"
  has 'define(Schema|Table)\(' "$both"
}

area_of() {
  local f="$1"
  case "$f" in
    */_generated/*) echo generated; return ;;
  esac
  case "$f" in
    *.test.*|*.spec.*|*/__tests__/*|*/e2e/*|*/tests/*|tests/*) echo tests; return ;;
  esac
  case "$f" in
    convex/*|*/convex/*)
      if defines_tables "$f"; then echo convex-schema; return; fi
      case "$f" in
        *[Mm]igration*) echo migration; return ;;
        */crons.ts|*/http.ts|*/auth.config.ts|*/convex.config.ts) echo convex-config; return ;;
        *.ts|*.js) echo convex-functions; return ;;
      esac
      ;;
  esac
  case "$f" in
    *[Mm]igration*) echo migration; return ;;
    package.json|*/package.json|pnpm-lock.yaml|*/pnpm-lock.yaml|package-lock.json|yarn.lock|bun.lock*) echo dependencies; return ;;
    .github/*|*.config.*|wrangler.*|*/wrangler.*|Dockerfile*|*.env.example|.env*|turbo.json|nx.json|angular.json|*/project.json|tsconfig*.json|*/tsconfig*.json) echo config; return ;;
    *.md|*.mdx|docs/*) echo docs; return ;;
    *.css|*.scss|*.sass|*.less|*.svg|*.png|*.jpg|*.jpeg|*.webp|*.gif|*.ico|*.woff*|*.ttf) echo frontend-ui; return ;;
    *.html|*.tsx|*.jsx|*.vue|*.svelte|*.astro) echo frontend-ui; return ;;
    backend/*|*/backend/*|server/*|*/server/*|api/*|*/api/*|workers/*|*/workers/*|functions/*) echo backend-other; return ;;
    *.ts|*.js|*.mjs|*.cjs) echo frontend-logic; return ;;
  esac
  echo other
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
while IFS= read -r f; do
  printf '%s\t%s\n' "$(area_of "$f")" "$f" >> "$tmp"
done <<< "$files"

stats="$(git diff --numstat "$range")"
for area in migration convex-schema convex-config convex-functions backend-other \
            frontend-logic frontend-ui dependencies config tests docs generated other; do
  matches="$(awk -F'\t' -v a="$area" '$1 == a { print $2 }' "$tmp")"
  [ -z "$matches" ] && continue
  echo "## $area ($(printf '%s\n' "$matches" | wc -l | tr -d ' '))"
  while IFS= read -r f; do
    line="$(printf '%s\n' "$stats" | awk -F'\t' -v f="$f" '$3 == f { print "+" $1 " -" $2 }')"
    status="$(git diff --name-status "$range" -- "$f" | cut -c1)"
    echo "  $status $f ${line:-}"
  done <<< "$matches"
  echo
done

echo "## Signals"
added="$(git diff "$range" -U0 | grep -E '^\+[^+]' || true)"
removed="$(git diff "$range" -U0 | grep -E '^-[^-]' || true)"

schema_files="$(awk -F'\t' '$1 == "convex-schema" { print $2 }' "$tmp")"
if [ -n "$schema_files" ]; then
  # shellcheck disable=SC2086  # repo paths don't contain spaces
  schema_diff="$(git diff "$range" -U0 -- $schema_files | grep -E '^[+-][^+-]' || true)"
  echo "Convex schema lines changed:"
  sed -n '1,60s/^/  /p' <<< "$schema_diff"
  required="$(grep -E '^\+.*:[[:space:]]*v\.' <<< "$schema_diff" | grep -vE 'v\.optional\(' || true)"
  if [ -n "$required" ]; then
    echo "  ! Adds a required field. Fine in a new table; in an existing table, deploy fails until existing documents are backfilled."
  fi
  if has '^-.*(:[[:space:]]*v\.|defineTable\()' "$schema_diff"; then
    echo "  ! Removes or changes a field or table. Check existing data and every reader."
  fi
  if has '^[+-].*\.(index|searchIndex|vectorIndex)\(' "$schema_diff"; then
    echo "  ! Changes indexes. A new index on a large existing table backfills on deploy."
  fi
else
  echo "No Convex schema files changed."
fi

if has '@convex-dev/migrations|migrations\.define|makeMigration|runMigration|backfill' "$added"; then
  echo "Migration code added (migrations component, migrations.define or a backfill)."
fi
if has '^migration' "$(cat "$tmp")"; then
  echo "Files with 'migration' in the path changed (see the migration group above)."
fi
if has 'useQuery|useMutation|useAction|usePaginatedQuery|injectQuery|injectMutation|(^|[^a-zA-Z_.])api\.[a-zA-Z_]+\.|internal\.[a-zA-Z_]+\.' "$added"; then
  echo "Added lines call Convex functions (useQuery, useMutation, api.*, internal.*)."
fi
if has '(process\.env|import\.meta\.env)\.[A-Z_]+' "$added"; then
  echo "New environment variable reads:"
  printf '%s\n' "$added" | grep -oE '(process\.env|import\.meta\.env)\.[A-Z0-9_]+' | sort -u | sed 's/^/  /'
fi
pkg_diff="$(git diff "$range" -U0 -- '*package.json')"
if has '^[+-][[:space:]]+"[@a-z0-9/._-]+":[[:space:]]*"(workspace:|catalog:|[~^0-9])' "$pkg_diff"; then
  echo "Dependency versions changed in package.json."
fi
if has 'ctx\.auth|getUserIdentity|requireUser|requireAuth|[Cc]lerk' "$added
$removed"; then
  echo "Touches auth checks or Clerk."
fi

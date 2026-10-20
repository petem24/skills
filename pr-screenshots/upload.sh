#!/usr/bin/env bash
# Store images on the repository's pr-screenshots branch and print a markdown
# image link for each one.
#
# Usage: upload.sh [-R owner/repo] [-d folder] image...
#   -R  repository to store them in (default: the current directory's repo)
#   -d  folder on the branch (default: the current git branch name)
#
# Uses the GitHub CLI's login, so it needs no keys. The branch shares no
# history with the code, and the images are only visible to people who can
# see the repository.
set -euo pipefail

branch="pr-screenshots"

usage() {
  echo "Usage: $(basename "$0") [-R owner/repo] [-d folder] image..." >&2
  exit 2
}

repo=""
folder=""
while getopts "R:d:" opt; do
  case "$opt" in
    R) repo="$OPTARG" ;;
    d) folder="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ "$#" -gt 0 ] || usage

if [ -z "$repo" ]; then
  repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)" || {
    echo "Couldn't find the GitHub repository here. Run this inside the project, or pass -R owner/repo." >&2
    exit 1
  }
fi

if [ -z "$folder" ]; then
  folder="$(git branch --show-current 2>/dev/null || true)"
  if [ -z "$folder" ] || [ "$folder" = main ] || [ "$folder" = master ]; then
    echo "Not on a feature branch. Pass -d <folder>, such as the PR's branch name." >&2
    exit 1
  fi
fi

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "Not a file: $file" >&2
    exit 1
  fi
done

# Escape a string for use inside a JSON string.
json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Spaces are the only character likely in a screenshot path that breaks a URL.
url_path() {
  printf '%s' "$1" | sed 's/ /%20/g'
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Create the branch with no history the first time.
if ! gh api "repos/$repo/branches/$branch" --silent 2>/dev/null; then
  cat > "$tmp" <<JSON
{"tree": [{"path": "README.md", "mode": "100644", "type": "blob",
  "content": "Screenshots for pull requests, one folder per branch. Not part of the code.\n"}]}
JSON
  tree="$(gh api "repos/$repo/git/trees" --input "$tmp" -q .sha)"
  printf '{"message": "Start the %s branch", "tree": "%s"}' "$branch" "$tree" > "$tmp"
  commit="$(gh api "repos/$repo/git/commits" --input "$tmp" -q .sha)"
  printf '{"ref": "refs/heads/%s", "sha": "%s"}' "$branch" "$commit" > "$tmp"
  # Someone else may have created it at the same moment, which is fine.
  gh api "repos/$repo/git/refs" --input "$tmp" --silent 2>/dev/null ||
    gh api "repos/$repo/branches/$branch" --silent
fi

for file in "$@"; do
  name="$(basename "$file")"
  path="$(url_path "$folder/$name")"

  # Replacing a file needs its current sha.
  sha=""
  if gh api "repos/$repo/contents/$path?ref=$branch" --silent 2>/dev/null; then
    sha="$(gh api "repos/$repo/contents/$path?ref=$branch" -q .sha)"
  fi

  {
    printf '{"message": "%s", "branch": "%s", ' "$(json_escape "Add $folder/$name")" "$branch"
    [ -n "$sha" ] && printf '"sha": "%s", ' "$sha"
    printf '"content": "'
    base64 < "$file" | tr -d '\n'
    printf '"}'
  } > "$tmp"

  if ! gh api -X PUT "repos/$repo/contents/$path" --input "$tmp" --silent; then
    echo "Upload failed for $file." >&2
    exit 1
  fi

  echo "![${name%.*}](https://github.com/$repo/blob/$branch/$path?raw=true)"
done

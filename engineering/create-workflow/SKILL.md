---
name: create-worktree
description: Start or resume a linked-worktree development environment, wait for it to become healthy, and report its temporary Cloudflare URLs. Use at the beginning of work in a new or existing worktree when the user asks to start, bring up, check, or get URLs for either the frontend-only or isolated full-stack environment.
---

# Start Linked Worktree

Start the requested worktree mode idempotently and return only verified URLs.

## Workflow

1. Resolve the repository root with `git rev-parse --show-toplevel`.
2. Read the repository `AGENTS.md` and `docs/worktree-development.md`.
3. Confirm `.git` is a file. Refuse to run worktree lifecycle commands in the
   primary checkout.
4. Choose the mode:
   - Honor an explicit `frontend` or `full-stack` request.
   - Otherwise use full stack when
     `backend/apps/convex/.env.local` selects a `local:` or `anonymous:`
     deployment; use frontend-only when it does not exist.
   - If the existing selection is ambiguous or non-local, ask the user which
     mode to use. Never delete or overwrite a cloud Convex selection.
5. Start the mode:
   - Frontend-only: ensure dependencies and the shared library are prepared
     using the setup commands in `docs/worktree-development.md`, then run
     `pnpm worktree:up:frontend`.
   - Full stack: run `pnpm worktree:setup:backend` when local setup is absent;
     otherwise run `pnpm worktree:up`.
6. Wait for the selected command to complete its readiness checks. On failure,
   inspect only the log path printed by the command, diagnose the error, and
   retry safe fixes. Never print secrets or the complete generated env files.
7. Read only these safe values from
   `backend/apps/convex/.env.worktree.runtime`:
   - `WORKTREE_PUBLIC_URL`
   - `WORKTREE_PUBLIC_CONVEX_URL`
   - `WORKTREE_PUBLIC_CONVEX_SITE_URL`
   - `TYPESENSE_HOST`
   - `FRONTEND_LOG_FILE` or `FULLSTACK_LOG_FILE`
8. Verify every reported `https://` URL with `curl -fsS`. Do not claim the
   environment is ready unless all URLs for that mode respond successfully.

## Response

Lead with the selected mode and readiness result.

- For frontend-only, report the temporary Cloudflare client URL.
- For full stack, report the temporary Cloudflare client, Convex API, and
  Convex site URLs. Report the loopback Typesense URL separately and label it
  private.
- Include the relevant log path.
- Never expose the Typesense API key, Cloudflare token, tunnel credentials,
  Clerk secrets, cookies, or complete env-file contents.

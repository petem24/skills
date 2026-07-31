---
name: workflow-teardown
description: Safely tear down and remove a linked worktree by stopping its supervised frontend or full-stack processes, deleting its temporary Cloudflare DNS and tunnel routes, and removing the Git worktree without deleting its branch. Use when the user explicitly asks to finish, clean up, remove, or tear down a worktree.
disable-model-invocation: true
---

# Teardown Worktree

Remove exactly one linked worktree while preserving its branch and the primary
checkout.

## Safety preflight

1. Resolve the target from the current linked worktree or an
   explicit path. If invoked from the primary checkout without one exact
   target, ask for it.
2. Read the repository `AGENTS.md`, `docs/git-workflow.md`, and
   `docs/worktree-development.md`.
3. Record:
   - `worktree_root="$(git rev-parse --show-toplevel)"`
   - the absolute Git common directory
   - `primary_root` as the parent of that common directory
   - the current branch
4. Require the target's `.git` to be a file. Refuse the primary checkout,
   paths outside this repository's `git worktree list --porcelain`, and broad
   or unresolved paths.
5. Inspect `git status --short --untracked-files=all`.
   - If tracked or untracked changes exist, stop and ask the user to preserve
     or explicitly discard them.
   - Never use `--force` without a new, explicit instruction that acknowledges
     those exact changes will be lost.

## Teardown

1. From the target worktree, run `pnpm worktree:down`.
2. Require cleanup to succeed. It stops the frontend/full-stack supervisor and
   Typesense, deletes temporary Cloudflare DNS records, unregisters tunnel
   ingress, and restarts the shared named tunnel. Do not remove the worktree
   when cleanup fails, because that can orphan public routes.
3. Change the command working directory to `primary_root`.
4. Run `git worktree remove -- "$worktree_root"` without `--force`.
5. Run `git worktree prune`.
6. Verify the path is absent from `git worktree list --porcelain` and the
   filesystem.

## Response

Report the removed path, stopped environment mode when known, and deleted
temporary hostnames when the cleanup command prints them. State explicitly
that the topic branch was preserved. If cleanup or removal is blocked, report
the exact remaining work without claiming teardown succeeded.

Never delete the topic branch, primary checkout, shared named Cloudflare
tunnel, another worktree's routes, or another worktree's processes.

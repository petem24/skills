---
name: teardown-worktree
description: Safely tear down and remove a linked worktree by resolving its mode from worktrees/worktree-modes.yaml, stopping every service and cleaning every resource configured for that mode, and removing the Git worktree without deleting its branch. Use when the user explicitly asks to finish, clean up, remove, or tear down a worktree. Clarify the mode before cleanup whenever the target state is ambiguous and no universal teardown is explicitly configured.
---

# Teardown Worktree

Remove exactly one linked worktree while preserving its branch and the primary
checkout.

## Safety Preflight

1. Resolve the target from the current linked worktree or an explicit path. If
   invoked from the primary checkout without one exact target, ask for it.
2. Read the repository `AGENTS.md`, when present, and read
   `worktrees/worktree-modes.yaml` completely, including its comments. Treat the
   YAML as the source of truth for mode detection, teardown commands, cleanup
   verification, printable values, and logs. Read any file it explicitly
   references before acting.
3. Record:
   - `worktree_root="$(git rev-parse --show-toplevel)"`
   - the absolute Git common directory
   - `primary_root` as the parent of that common directory
   - the current branch
4. Require the target's `.git` to be a file. Refuse the primary checkout, paths
   outside this repository's `git worktree list --porcelain`, and broad or
   unresolved paths.
5. Inspect `git status --short --untracked-files=all`.
   - If tracked or untracked changes exist, stop and ask the user to preserve or
     explicitly discard them.
   - Never use `--force` without a new, explicit instruction that acknowledges
     those exact changes will be lost.

## Resolve the Cleanup Mode

Do not stop services, delete routes, or mutate generated state until the cleanup
plan is unambiguous.

1. Apply the mode-detection rules and runtime signals from
   `worktrees/worktree-modes.yaml` to the target worktree. Treat a mode named by
   the user as intent, but verify it against the target's state before cleanup.
2. Select exactly one detected mode and its teardown recipe. Alternatively, use
   a global teardown command only when the YAML explicitly declares it safe and
   complete for every mode.
3. If the evidence conflicts, multiple mode-specific recipes may apply, the
   requested mode disagrees with the target, or no safe teardown recipe can be
   resolved, ask the user before changing anything. List the plausible modes
   and concise cleanup differences from the YAML. Never combine recipes or
   guess from stale artifacts.
4. Before running cleanup, tell the user `Mode: <mode>` and briefly state the
   evidence used. For a universal recipe, report `Cleanup: universal` and the
   detected mode separately. Keep the selected cleanup plan fixed for the run.

## Teardown

1. From the target worktree, run the selected mode's teardown commands, or the
   YAML-declared universal teardown command, exactly in the configured order.
   Stop every configured service and clean every configured external resource;
   do not stop after the first successful cleanup step.
2. Run only cleanup commands and shared prerequisites explicitly referenced by
   the selected recipe. Never run another mode's teardown, delete another
   worktree's resources, or invent a fallback command that is absent from the
   YAML and its referenced documentation.
3. Require every configured stopped-state and resource-cleanup check to pass.
   Use only configured diagnostics and log locations on failure. Do not remove
   the worktree when cleanup is incomplete, because that can orphan processes
   or external routes.
4. Change the command working directory to `primary_root`.
5. Run `git worktree remove -- "$worktree_root"` without `--force`.
6. Run `git worktree prune`.
7. Verify the path is absent from `git worktree list --porcelain` and the
   filesystem.

## Response

Lead with the resolved mode and teardown result. Report the removed path, every
stopped service and deleted public resource that the selected recipe marks for
chat, and any relevant configured log path. State explicitly that the topic
branch was preserved. If cleanup or removal is blocked, report the exact
remaining work without claiming teardown succeeded.

Never print secrets, tokens, credentials, API keys, cookies, or complete env
files. Never delete the topic branch, primary checkout, shared infrastructure,
another worktree's routes, or another worktree's processes.

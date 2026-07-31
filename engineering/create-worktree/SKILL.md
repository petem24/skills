---
name: create-worktree
description: Start or resume the correct linked-worktree development mode from worktrees/worktree-modes.yaml, scaffold only that mode, wait for every configured service to become healthy, and report its configured URLs. Use at the beginning of work in a new or existing worktree when the user asks to create, start, bring up, check, resume, or get URLs for a worktree environment. Resolve the mode explicitly and ask the user before making changes whenever the intended mode is not unambiguous.
---

# Start Linked Worktree

Resolve one mode before changing the worktree, execute only that mode, and return
its verified service URLs.

## Establish Context

1. Resolve the repository root with `git rev-parse --show-toplevel`.
2. Read the repository `AGENTS.md`, when present, and read
   `worktrees/worktree-modes.yaml` completely, including its comments. Treat the
   YAML as the source of truth for available modes, selection guidance,
   scaffolding, startup, readiness, printable values, and logs. Read any file it
   explicitly references before acting.
3. Confirm `.git` is a file. Refuse to run worktree lifecycle commands in the
   primary checkout.

## Resolve the Mode Before Acting

Do not install dependencies, generate env files, scaffold resources, or start
services until exactly one mode has been selected.

1. Honor a mode explicitly named by the user when it matches a mode or alias in
   `worktree-modes.yaml`.
2. Otherwise apply only the mode-selection rules and detection signals defined
   in that file. Use the user's requested task and existing worktree state as
   evidence. Do not infer a mode merely because artifacts from a previous mode
   happen to exist.
3. If no mode matches uniquely, multiple modes remain plausible, evidence
   conflicts, or the requested mode is unknown, ask the user which configured
   mode to use. List the relevant mode names and their concise differences from
   the YAML. Make no worktree changes while waiting.
4. Before running commands, tell the user `Mode: <mode>` and briefly state the
   evidence used. Keep that selection fixed for the run. If a later command or
   state conflicts with it, stop and clarify instead of switching or combining
   modes silently.

## Scaffold and Start the Selected Mode

1. Follow the selected mode entry in `worktrees/worktree-modes.yaml` exactly and
   in its declared order. Run only its scaffolding/setup commands and shared
   prerequisites that it explicitly references. Never run scaffolding from a
   different mode or create resources merely because another mode may need
   them.
2. Preserve configured working directories, environment requirements, and
   idempotency checks. Never delete or overwrite an existing cloud or remote
   service selection unless the selected mode explicitly requires it and the
   user has authorized that destructive change.
3. Run every startup command for the selected mode so that all of its configured
   services are started. Do not stop after the first URL-producing service.
4. Wait for every readiness check defined for that mode. On failure, use only
   its configured diagnostic or log locations, apply safe mode-local fixes, and
   retry. Do not borrow fallback commands from another mode.

## Print and Verify the URLs

1. Obtain output using only the selected mode's configured print commands,
   fields, or templates. Print every URL the mode marks for chat, labeled with
   its service name. Include configured log paths when requested by the mode.
2. Run the configured verification for every required service URL. When no
   verification method is specified, verify each HTTP(S) URL with `curl -fsS`.
   Do not claim the environment is ready unless all required services for the
   selected mode pass.
3. Lead the final response with `Mode: <mode>` and the readiness result, then
   list the service URLs and relevant log paths. If startup is partial, identify
   the failed service and omit any readiness claim.
4. Never print secrets, tokens, credentials, API keys, cookies, or complete env
   files. If a configured printable value appears secret-bearing, stop and ask
   rather than exposing it.

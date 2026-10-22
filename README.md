# Skills

Personal agent skills, installed with the [`skills`](https://skills.sh) CLI.

## Install

On each machine, once:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/petem24/skills/main/setup.sh)
```

This installs every skill at user level for every supported agent. It's safe
to rerun.

## Update

After changing this repository:

```bash
npx skills update -g
```

## Skills

| Skill | Purpose | Needs |
| --- | --- | --- |
| [pull-requests](pull-requests/SKILL.md) | Write every PR body the same way: blast radius (UI, feature, back end, schema, migration), summary, the issues it closes on merge, and the `verify-ui` screenshots for visible changes | Nothing (screenshots use `pr-screenshots`) |
| [pr-screenshots](pr-screenshots/SKILL.md) | Store screenshots on the repo's `pr-screenshots` branch and attach them to a pull request, plus the occasional video via `gh --attach` | The GitHub CLI, logged in (2.99+ for video) |
| [verify-ui](verify-ui/SKILL.md) | Check web UI changes in headless Chrome with agent-browser; screenshots by default, video only for motion | The project's `pnpm browser` and `pnpm auth` ([devkit](https://github.com/DevSports/devkit)); ffmpeg for video |

Third-party skills (Convex, Angular, Matt Pocock's grilling and handoff, and
others) aren't copied here. They're on Mission Control's **Skills to sync**
list, which installs them at user level on every machine.

## Global agent instructions

[`global/AGENTS.md`](global/AGENTS.md) holds general rules for every project.
Mission Control's **Sync skills** copies it to each machine's
`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` and `~/.config/opencode/AGENTS.md`.
Edit it here, not on the machines. Project-specific rules stay in each
project's own `AGENTS.md`.

Never commit API keys. This repository is public.

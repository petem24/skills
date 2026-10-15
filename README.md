# Skills

Personal agent skills, installed with the [`skills`](https://skills.sh) CLI.

## Install

On each machine, once:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/petem24/skills/main/setup.sh)
```

This installs every skill at user level for every supported agent, then asks
for the keys the skills need and saves them to `~/.config/secrets.env`
(readable only by you), loaded from your shell profiles. It's safe to rerun,
for example to replace a key.

## Update

After changing this repository:

```bash
npx skills update -g
```

## Skills

| Skill | Purpose | Needs |
| --- | --- | --- |
| [pr-screenshots](pr-screenshots/SKILL.md) | Upload screenshots to ImgBB and attach them to a pull request | `IMGBB_API_KEY` from <https://api.imgbb.com/> |
| [verify-ui](verify-ui/SKILL.md) | Check web UI changes in headless Chrome with agent-browser | The project's `pnpm browser` and sign-in helpers |

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

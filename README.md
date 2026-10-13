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

Never commit API keys. This repository is public.

# Skills

Personal agent skills, installed with the [`skills`](https://skills.sh) CLI.

## Install

On each machine, once:

```bash
npx skills add petem24/skills -g --all
```

This installs every skill at user level for every supported agent.

## Update

After changing this repository:

```bash
npx skills update -g
```

## Skills

| Skill | Purpose | Needs |
| --- | --- | --- |
| [pr-screenshots](pr-screenshots/SKILL.md) | Upload screenshots to ImgBB and attach them to a pull request | `IMGBB_API_KEY` in your shell profile, from <https://api.imgbb.com/> |

Never commit API keys. This repository is public.

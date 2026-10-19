---
name: pr-blast-radius
description: Open every pull request with a short blast-radius summary saying how far the change reaches (front-end UI only, front-end feature, back end, Convex schema, migration), so the reviewer can see at a glance how much testing it needs. Use whenever you create a pull request, or are asked to summarise a PR's risk, scope or blast radius.
---

# PR blast radius

Every pull request body starts with a **Blast radius** section, before
anything else. It answers one question for the reviewer: how carefully does
this need testing? Keep it short enough to read in five seconds.

## 1. Scan the change

Run the scan script from this skill's directory in the checkout you're opening
the PR from, passing the PR's base branch:

```bash
<skill-dir>/scan.sh origin/main
```

It groups the changed files by area (Convex schema, Convex functions, other
back end, front-end logic, front-end UI, dependencies, config, tests, docs)
and lists signals from the diff: schema lines changed, required fields and
index changes, migration code, new Convex calls from the front end, new
environment variables, dependency changes and auth code. Commit everything
first: it only reads commits.

The script sorts by path and pattern, so it can be wrong. Read the diff for
anything it flags, and anything it puts under `other`, before deciding.

## 2. Pick the level

Pick the **highest** level that applies:

| Level | Means | Testing it needs |
| --- | --- | --- |
| 🟢 **No runtime change** | Docs, comments, tests or tooling only | CI passing |
| 🟢 **Front-end UI only** | Looks or layout: styles, markup, copy, icons. No new behaviour, state or data | A visual check of the screens touched |
| 🟡 **Front-end feature** | New or changed behaviour in the app (routes, state, forms, validation, new calls to existing back-end functions) with no back-end change | Click through the flow, including empty, error and loading states |
| 🟠 **Back end** | Convex functions, HTTP actions, crons, auth, other server code or environment variables change. Schema unchanged | Exercise each changed function from the app, check permissions, and run back-end tests |
| 🔴 **Schema change** | Convex tables, fields or indexes change | As for back end, plus check the deploy against real data shapes |
| 🔴 **Migration** | Existing data must be backfilled, transformed or deleted, or the deploy needs steps in a set order | Rehearse on a copy of production data and plan the rollout order |

Judgement calls:

- A `.tsx` or template file that only moves markup is UI; one that adds a
  `useQuery`, a handler or new state is a feature.
- New dependencies, upgraded packages and config changes (build, CI,
  `wrangler`, env) raise the level to at least **Back end** if they change
  what runs in production, and are always listed.
- Within a schema change, say whether it's additive and safe (a new table, an
  optional field, a new index on a small table) or needs care (a required
  field on an existing table, a removed or retyped field, a new index on a
  large table). Convex rejects a deploy when existing documents don't match
  the schema, so a required field on an existing table is a **Migration**
  unless the PR shows it's already backfilled.
- If you can't tell whether something needs a migration, say so and ask; don't
  round down.

## 3. Write the section

Put this at the very top of the PR body, filled in from the scan and your
reading of the diff. Use "No" rather than leaving a row out, so the reviewer
sees every question answered.

```markdown
## Blast radius: 🟡 Front-end feature

| | |
| --- | --- |
| Front-end UI | Yes: new filter bar on the players list |
| Front-end behaviour | Yes: filters update the URL and the query |
| Back end | No (uses the existing `players.list` query) |
| Convex schema | No |
| Migration | No |
| Other | None (dependencies, env vars, config, auth) |

**Test:** filter, clear and reload the players list on desktop and mobile.
```

- The heading carries the level, so the PR list and notifications show it.
- Name the specific screens, functions, tables and fields, not just "yes".
- For a schema change, name each table and field changed and whether it's
  safe. For a migration, say what it does, how to run it, and the order
  relative to the deploy (or point to the project's migration guide, such as
  a `release-migrations.json` entry).
- **Test** is one line on what to check, matching the level. Don't repeat the
  whole testing plan here; the rest of the PR body can.

Then write the rest of the PR body as usual.

## 4. Keep it current

When you push more commits to a PR you opened, rerun the scan and update the
section if the level or any row changed. If the project's `AGENTS.md` sets a
different PR template, keep this section at the top of it.

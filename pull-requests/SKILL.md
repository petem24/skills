---
name: pull-requests
description: Write every pull request body the same way - a Blast radius section at the top saying how far the change reaches (front-end UI only, front-end feature, back end, Convex schema, migration), then the summary, then the issues it closes (so GitHub closes them on merge), then the screenshots taken while verifying any visible change. Use whenever you create or update a pull request, or are asked to summarise a PR's risk, scope or blast radius, link issues to a PR, or add screenshots to a PR.
---

# Pull requests

Every pull request body has this shape:

1. **Blast radius**, before anything else. It answers one question for the
   reviewer: how carefully does this need testing? Keep it short enough to
   read in five seconds.
2. **Summary** of what changed and why, as usual.
3. **Issues**: every related issue from the conversation, linked so that the
   ones this PR resolves close when it merges.
4. **Screenshots** from the `verify-ui` checks, whenever the change is visible,
   plus a video only when `verify-ui` needed to record one.

If the project's `AGENTS.md` sets a different PR template, keep Blast radius
at the top and Issues and Screenshots in it.

# Blast radius

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

Then write the summary as usual.

# Issues

## 4. Collect the related issues

Before you open the PR, go back through the conversation and the work and
list every GitHub issue it relates to:

- issues the user mentioned, by number (`#123`), link or title;
- issues you created, read or commented on during the task;
- issue numbers in the branch name, commit messages or a project tracker the
  user pointed to.

Don't guess or search for loosely related issues to pad the list. Check each
one exists and is open with `gh issue view <number> --json number,title,state`
(add `--repo owner/repo` for another repository). If there are none, leave the
section out.

## 5. Link them

Decide for each issue whether this PR fully resolves it:

- **Resolves it:** `Closes #123`. GitHub links the issue to the PR and closes
  it when the PR is merged.
- **Only part of it, or just related:** `Part of #123` or `Related to #123`.
  This links without closing. Don't use a closing keyword for partial work.
- **Not sure:** link it without closing, and tell the user so they can decide.

Every closing issue needs its own keyword, on its own line; `Closes #1, #2`
only closes #1. For an issue in another repository use
`Closes owner/repo#123`.

```markdown
## Issues

Closes #123
Closes #130
Part of #98 (this adds the filter; sorting is still to do)
```

The keywords only work in the PR body (not a comment), and only close issues
when the PR merges into the repository's default branch. A PR that's closed
without merging closes nothing. For a PR into another branch, such as a layer
in a stack, keep the lines anyway and tell the user the issues won't close
until the change reaches the default branch.

After creating or editing the PR, check that GitHub picked them up:

```bash
gh pr view <number> --json closingIssuesReferences --jq '.closingIssuesReferences[].number'
```

Every `Closes` issue should be listed. If one is missing, fix the line in the
body (a typo, a missing keyword, a wrong repo) and check again.

# Screenshots

Any PR that changes something a user can see includes the screenshots you
took with `verify-ui`. Only a PR with no visible change (back-end only,
tooling, docs) skips this section, and says so in one line: "No visible
change."

## 6. Pick the screenshots

Use the screenshots from this task's `verify-ui` checks, under
`output/agent-browser/`. Include the ones that show the change:

- each screen or state you changed, at every viewport you checked (usually
  desktop and mobile);
- the states that matter for the change, such as empty, error or validation,
  not just the happy path;
- a before and after pair when the change is a fix or a restyle, if you have
  the before shot.

Leave out shots of unrelated pages, sign-in screens and duplicates. If you
haven't verified the change yet, run `verify-ui` first; don't open a PR with a
visible change and no screenshots. If you couldn't take them (the app wouldn't
start, say), write that in the section instead of leaving it out.

## 7. Upload and embed them

GitHub has no API for attaching images, so upload them with the
`pr-screenshots` skill, which commits them to the repository's
`pr-screenshots` branch, and embed the links it prints. In a public
repository anyone can see them, so there only upload shots of seeded or test
data, never real personal data, secrets or tokens.

Put the section after Issues, with a line on what each image shows:

```markdown
## Screenshots

Players list with the new filter bar, desktop (1440px):
![players-filter-1440](https://github.com/<owner>/<repo>/blob/pr-screenshots/<branch>/...)

Same, mobile (390px):
![players-filter-390](https://github.com/<owner>/<repo>/blob/pr-screenshots/<branch>/...)

Empty state when no players match:
![players-filter-empty-1440](https://github.com/<owner>/<repo>/blob/pr-screenshots/<branch>/...)
```

If `verify-ui` recorded a video because the change is motion or a sequence
stills can't show, add it under the screenshots with the `pr-screenshots`
skill's Videos steps (`gh pr create|edit --attach`). Don't record one just
for the PR; screenshots are enough for most changes.

# Keep it current

When you push more commits to a PR you opened, rerun the scan and update the
Blast radius section if the level or any row changed. If the conversation
brings up another issue the PR resolves, add its `Closes` line and check
again. If the new commits
change something visible, verify it again with `verify-ui` and replace the
screenshots that are now out of date.

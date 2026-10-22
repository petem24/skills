---
name: pr-screenshots
description: Attach screenshots, and the occasional screen recording, to a GitHub pull request with the GitHub CLI's --attach, so they show inline like files dragged in on github.com. The pull-requests skill uses it for the Screenshots section. Use after UI verification when a PR changes something visible, or when asked to add screenshots, images, videos, recordings or visual evidence to a PR.
---

# PR screenshots

Upload screenshots and videos with the GitHub CLI's `--attach`, which needs
gh 2.99 or later (`gh --version`). It works like dragging a file into the PR
on github.com: the file goes into GitHub's attachment storage and shows inline,
with videos as a player. It uses the GitHub CLI's login, so there are no keys
to set up.

Attachments follow the repository's visibility, so in a private repository
they stay private. In a public repository anyone can see them, so only attach
screenshots of seeded or test data there, never real personal data, secrets,
tokens or credentials.

## Steps

1. Take screenshots at the sizes that matter, such as desktop and mobile, with
   descriptive file names.
2. Write the section in the body file, referencing each local file under a
   line on what it shows. Write the alt text in the reference:

   ```markdown
   ## Screenshots

   Profile page, desktop (1440px):
   ![Profile page at 1440px](output/agent-browser/profile-1440.png)

   Profile page, mobile (390px):
   ![Profile page at 390px](output/agent-browser/profile-390.png)
   ```

3. Pass every file you referenced to `--attach`, from the project root. Each
   reference is rewritten to the uploaded file:

   ```bash
   gh pr create --title "..." --body-file body.md \
     --attach output/agent-browser/profile-1440.png \
     --attach output/agent-browser/profile-390.png
   ```

   For an existing PR, use `gh pr edit <number> --body-file body.md --attach ...`
   the same way. To post them as a comment instead, use
   `gh pr comment <number> --body-file body.md --attach ...`.

The path in the body must be the same path you pass to `--attach`. gh looks
for it relative to the body file's folder first, then the working directory,
so keep `body.md` in the project root or outside the repository and run gh
from the project root. A file attached without a reference is appended to the
end of the body; for an image, give it alt text after `#`, as in
`--attach 'output/agent-browser/profile-390.png#Profile page at 390px'`.
Up to 50 files go in one command.

Check the result with `gh pr view <number> --json body -q .body`: every
reference should now be a `https://github.com/user-attachments/...` link, and
no local path should be left.

## Replacing screenshots

Uploading again makes a new link; it never replaces the old file. When the
screenshots go out of date, fetch the body with
`gh pr view <number> --json body -q .body > body.md`, swap each stale link
for the new local file's path, and run `gh pr edit` with `--attach` as above.
Don't leave old and new screenshots side by side.

## Videos

Screenshots come first. Only attach a video when `verify-ui` recorded one
because the change is motion or a sequence that stills can't show; never
record one just for the PR. Post its key screenshots too, since they show in
notifications and load faster.

Attach a video exactly as you would a screenshot. A video has no alt text, so
describe what it shows on the line above it. Keep it under 10 MB (shrink it
as `verify-ui` describes).

## The old pr-screenshots branch

This skill used to commit screenshots to a `pr-screenshots` branch. Older PRs
still link to it, so leave that branch alone where it exists, but don't add to
it.

## If the upload fails

If `gh` isn't logged in, stop and ask the user to run `gh auth login`. If
`--attach` isn't recognised, ask them to upgrade the GitHub CLI
(`brew upgrade gh`). If some files upload and others fail, gh still creates or
edits the PR with the ones that worked and exits non-zero; check the body,
then attach the missing ones with `gh pr edit`. Report other failures with the
error message. Don't substitute another image or video host.

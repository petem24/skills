---
name: pr-screenshots
description: Store screenshots on the repository's pr-screenshots branch and attach them to a GitHub pull request, and attach the occasional screen recording as a video GitHub plays inline. The pull-requests skill uses it for the Screenshots section. Use after UI verification when a PR changes something visible, or when asked to add screenshots, images, videos, recordings or visual evidence to a PR.
---

# PR screenshots

GitHub has no API for attaching images to pull requests, so commit them to a
`pr-screenshots` branch in the same repository and embed links to them. The
branch shares no history with the code and is never merged. Each PR's
screenshots go in a folder named after its branch.

It uses the GitHub CLI's login, so there are no keys to set up. The images are
only visible to people who can see the repository, so in a private repository
they stay private. In a public repository anyone can see them, so only commit
screenshots of seeded or test data there, never real personal data, secrets,
tokens or credentials.

## Steps

1. Take screenshots at the sizes that matter, such as desktop and mobile. Give
   each file a descriptive name, because the name becomes the alt text.
2. From inside the project, upload them with the `upload.sh` script in this
   skill's directory:

   ```bash
   <skill-dir>/upload.sh output/screens/profile-desktop.png output/screens/profile-mobile.png
   ```

   It prints one markdown image link per file. The folder defaults to the
   current git branch; pass `-d <folder>` if you're not on the PR's branch,
   and `-R owner/repo` if you're not inside the project. Uploading a file with
   the same name again replaces it, so the links in the PR stay the same.
3. Post the links to the PR, with a line on what each image shows:

   ```bash
   gh pr comment <number> --body "$(cat <<'MD'
   ## Screenshots

   Profile page, desktop (1440px):
   ![profile-desktop](https://github.com/<owner>/<repo>/blob/pr-screenshots/<branch>/profile-desktop.png?raw=true)

   Profile page, mobile (390px):
   ![profile-mobile](https://github.com/<owner>/<repo>/blob/pr-screenshots/<branch>/profile-mobile.png?raw=true)
   MD
   )"
   ```

   If you are creating the PR yourself, put the section in the PR body instead.

## Videos

Screenshots come first. Only attach a video when `verify-ui` recorded one
because the change is motion or a sequence that stills can't show; never
record one just for the PR. Post its key screenshots too, since they show in
notifications and load faster.

GitHub doesn't play videos linked from the `pr-screenshots` branch, so upload
them with the GitHub CLI's `--attach` instead, which needs gh 2.99 or later
(`gh --version`). It works like dragging a file into the PR on github.com: the
video is stored in GitHub's attachment storage, follows the repository's
visibility, and plays inline.

- **Creating the PR:** reference the local file in the body and attach it.
  The reference is rewritten to the uploaded video:

  ```bash
  gh pr create --title "..." --body-file body.md \
    --attach output/agent-browser/checkout-flow.mp4
  ```

  where `body.md` has `![checkout-flow](output/agent-browser/checkout-flow.mp4)`
  under the line describing it. The path must match the `--attach` path
  exactly.
- **An existing PR:** use `gh pr edit <number> --body-file body.md --attach ...`
  the same way, or `gh pr comment <number> --body "..." --attach ...`. With no
  body flag, `gh pr edit` appends the video to the current body.

Videos have no alt text, so describe what it shows on the line above it.
Uploading again makes a new link rather than replacing the old one, so
remove the stale reference from the body when you replace a video. Keep it
under 10 MB (shrink it as `verify-ui` describes), and the same rule as for
images applies in a public repository: seeded or test data only.

## If the upload fails

If `gh` isn't logged in, stop and ask the user to run `gh auth login`. If
`--attach` isn't recognised, ask them to upgrade the GitHub CLI
(`brew upgrade gh`) and use the screenshots meanwhile. Report other failures
with the error message. Don't substitute another image or video host.

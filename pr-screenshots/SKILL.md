---
name: pr-screenshots
description: Store screenshots on the repository's pr-screenshots branch and attach them to a GitHub pull request. The pull-requests skill uses it for the Screenshots section. Use after UI verification when a PR changes something visible, or when asked to add screenshots, images, or visual evidence to a PR.
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

## If the upload fails

If `gh` isn't logged in, stop and ask the user to run `gh auth login`. Report
other failures with the script's error message. Don't substitute another image
host.

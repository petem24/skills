---
name: pr-screenshots
description: Upload screenshots to ImgBB and attach them to a GitHub pull request. Use after UI verification when a PR changes something visible, or when asked to add screenshots, images, or visual evidence to a PR.
---

# PR screenshots

GitHub has no API for attaching images to pull requests, so upload them to
ImgBB and embed the returned links in the PR.

## Before uploading

ImgBB links are public: anyone with the URL can view the image, even when the
repository is private. Only upload screenshots that show seeded or test data.
Never upload images showing real personal data, secrets, tokens, or
credentials. If in doubt, don't upload. Describe the result in text instead.

## Steps

1. Take screenshots at the sizes that matter, such as desktop and mobile. Give
   each file a descriptive name, because the name becomes the alt text.
2. Upload them with the `upload.sh` script in this skill's directory:

   ```bash
   <skill-dir>/upload.sh output/screens/profile-desktop.png output/screens/profile-mobile.png
   ```

   It prints one markdown image link per file. Pass `-e <seconds>` to have
   ImgBB delete the images later (for example `-e 2592000` for 30 days).
3. Post the links to the PR, with a line on what each image shows:

   ```bash
   gh pr comment <number> --body "$(cat <<'MD'
   ## Screenshots

   Profile page, desktop (1440px):
   ![profile-desktop](https://i.ibb.co/...)

   Profile page, mobile (390px):
   ![profile-mobile](https://i.ibb.co/...)
   MD
   )"
   ```

   If you are creating the PR yourself, put the section in the PR body instead.

## If the upload fails

If `IMGBB_API_KEY` is not set, stop and tell the user to onboard the machine
with the setup script, then open a new terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/petem24/skills/main/setup.sh)
```

Don't run the setup script yourself, look for a key, or substitute another
image host. Report other failures with the script's error
message.

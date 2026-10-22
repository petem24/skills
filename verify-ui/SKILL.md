---
name: verify-ui
description: Verify web UI changes in headless Chrome with agent-browser, signed in as the project's Clerk test users, and run the project's relevant existing tests. Takes screenshots by default and records a video only when a change is motion or a sequence that stills can't show. Use after changing anything visible, or when asked to check, inspect, screenshot, record or exercise a browser flow.
---

# Verify UI

Check UI changes yourself in headless Chrome with **agent-browser** before
reporting them done. The project decides how to start the app, which URL to
use, how to sign in and which tests to run; the rules here apply everywhere.

## 1. Find the project's setup

Read the project's `AGENTS.md` (or `CLAUDE.md`) and the UI verification guide
it links to. Note:

- how to start the app in this checkout, and the URL to verify against;
- which user to sign in as (`pnpm auth --list` shows them);
- the viewport sizes the project supports;
- the existing tests that cover the area you changed.

If the project has none of this, say so in your report and verify what you
can without signing in.

Starting the checkout you're working in is part of verification: try to start
it, and fix local failures, before calling it a blocker. Don't stop a server
that belongs to another checkout.

## 2. Run the browser

Use `pnpm browser` from the checkout you're verifying. In DevSports projects it
comes from [devkit](https://github.com/DevSports/devkit), which pins the
version; its README covers host settings and the live dashboard. Install it
with `pnpm browser:install` when it's missing (on Linux, add `--with-deps` if
Chrome's libraries are missing). Run `pnpm browser --help` for the commands the
pinned version supports. Don't run agent-browser's own `upgrade` command.

- **One session per task.** Pick a unique `AGENT_BROWSER_SESSION` (for example
  `<project>-<task>-<role>`) and set it on **every** command: shell exports
  don't always carry over between tool calls. Close only your own session; never
  `close --all`.
- **Sign in with `pnpm auth`.** Development users are Clerk test users
  (`+clerk_test` addresses) that sign in with the code `424242`, with no email,
  passwords or secrets. `pnpm auth [user] --url "$APP_URL"` signs your session
  in through the app's own Clerk; run it again with another user to switch.
  `pnpm auth --all --save` saves sessions for test suites. To sign in by hand,
  type a test address on the sign-in page and enter `424242`. A project
  without `pnpm auth` documents its own sign-in in `AGENTS.md`.
- **One origin.** Sign in, browse and run tests against the same URL. Sessions
  don't carry across origins, so don't sign in on `localhost` and verify on the
  Tailscale URL.
- **Saved sessions are credentials.** Never print, commit or copy them, never
  ask for real passwords, codes or cookies, and never attach to a personal
  browser profile.

```sh
export AGENT_BROWSER_SESSION=<project>-<task>
pnpm auth --url "$APP_URL"
pnpm browser open "$APP_URL"
pnpm browser set viewport 1440 1000
pnpm browser snapshot -i
pnpm browser click @e3            # refs come from the latest snapshot
pnpm browser wait --text "Saved"
pnpm browser screenshot output/agent-browser/<task>-1440.png
pnpm browser console
pnpm browser errors
pnpm browser network requests
pnpm browser close
```

## 3. Check the change properly

- Take a fresh snapshot after navigation or any big change; refs go stale.
- Wait for visible UI state (text, a selector, the URL), not network idle or a
  fixed sleep. Convex and similar backends hold connections open.
- **Animation and playback** (Canvas, WebGL, `<video>`, a camera feed, CSS
  animations) can play without changing the DOM, so there's no text or
  selector to wait for. Wait on the playback state with `wait --fn` instead:
  `document.querySelector('video').currentTime > 2` for a video,
  `document.getAnimations().every(a => a.playState === 'finished')` for CSS
  and Web Animations, or a frame count or flag the component already exposes.
  Only when none of those exists, as with a Canvas drawn in a
  `requestAnimationFrame` loop, use a fixed `wait <ms>`. Keep it short, and
  say in your report where you used one and why.
- Exercise the controls you changed, not just the page they're on. Check the
  states that matter: loading, empty, error, validation and keyboard use.
- Reload to confirm anything that should persist, and check the saved content,
  not just that a click or toast happened.
- Screenshot every supported viewport the change affects and **open each
  screenshot and look at it**. A snapshot or a screenshot nobody looked at
  isn't visual verification. Canvas and charts need a visual check as well as
  DOM checks.
- Look at console errors, uncaught page errors and failed requests the page
  needs. A command that succeeded isn't a clean result.
- Run the smallest existing test that covers the change. Use agent-browser for
  exploring; don't add one-off scripts or Playwright CLI.
- Clean up data you created for the check.

Keep screenshots, recordings and other evidence under ignored
`output/agent-browser/`, with task-specific names.

## 4. Record only when stills can't show it

Screenshots are the default. Most changes (layout, styling, copy, a new
state, a form error) are fully shown by a screenshot of each state, so don't
record those. Record a video only when the change **is** the motion or the
sequence, and stills would leave the reviewer guessing:

- an animation, transition or loading sequence;
- drag and drop, resizing, scrolling behaviour such as sticky or infinite
  lists;
- a multi-step flow where what matters is how one step leads to the next,
  such as optimistic updates followed by the saved result;
- a bug fix for timing or flicker, where the "after" only proves anything
  when it's moving;
- the user asked for a video.

If you're unsure, take screenshots. One short recording of the key flow is
enough; don't record every viewport.

Recording needs ffmpeg with the libx264 encoder (`brew install ffmpeg` has it;
`pnpm browser doctor` checks). Record **mp4**, which plays in Safari, GitHub
and chat; webm doesn't everywhere. Plan the steps with a snapshot first, then
record only the flow:

```sh
pnpm browser snapshot -i                       # plan before recording
pnpm browser record start output/agent-browser/<task>.mp4 --cursor --contact-sheet
pnpm browser click @e3
pnpm browser wait --text "Saved"
pnpm browser screenshot output/agent-browser/<task>-saved.png
pnpm browser record stop
```

- Keep it under about 30 seconds. Use `--fps 60` only for short,
  motion-heavy takes and lower it (`--fps 15`) for longer ones.
- `--cursor` shows the pointer, so clicks and drags are visible. Leave it off
  for pure animation work.
- **You can't watch the video, so check it another way.** `--contact-sheet`
  saves `<task>.contact-sheet.png` next to the video, a grid of timestamped
  frames at each visible change; open it to confirm the flow happened in the
  right order. For scroll-heavy takes add `--contact-sheet-threshold 0.2` so
  it isn't full of near-identical frames. The frames are small, so also take
  screenshots at the key moments while recording and look at those for
  detail.
- Check the size with `ls -lh`. GitHub accepts up to 10 MB on free plans
  (100 MB on paid). If it's bigger, shrink it:

  ```sh
  ffmpeg -i <task>.mp4 -vf "scale='min(1280,iw)':-2" -c:v libx264 -crf 28 \
    -preset slow -pix_fmt yuv420p -movflags +faststart -an <task>-small.mp4
  ```

## 5. Host quirks

Normal macOS and Linux hosts need no settings. On a host where Chrome reports
`No usable sandbox` and it can't be fixed, or where Tailscale runs in
userspace and needs an outbound proxy, put `AGENT_BROWSER_ARGS`,
`AGENT_BROWSER_PROXY` and the lowercase proxy variables in the project's
host settings file (see its guide), never in committed config.

## 6. Report

Give the URL, who you were signed in as, the viewport sizes, what you did and
what you saw, test commands and their results, console and page errors,
evidence paths, and anything you couldn't verify. Say clearly when only the
sign-in page was covered: that doesn't verify a feature behind it. When the
work goes into a pull request, the `pull-requests` skill puts these
screenshots in it.

**Show every screenshot inline, by its full absolute path**, so the reader sees
it in the chat and can click to expand it. One Markdown image per file:

```md
![Settings page at 1440px](</Users/me/repos/my app/output/agent-browser/settings-1440.png>)
```

- Get the path with `realpath output/agent-browser/<file>`; don't type it.
- Always wrap the path in `<...>`. A space in a bare path stops the image
  rendering at all, and the brackets are harmless when there's no space.
- Never just name the folder, and never use a relative path
  (`output/agent-browser/x.png`) or `~/`. Chat UIs such as T3 Code resolve
  relative paths against the thread's checkout, which may not be where you
  saved the file, and they refuse `~/` outright.
- Recordings work the same way: `![Checkout flow](</abs/path/checkout.mp4>)`
  plays the video inline. Show its contact sheet too, and say why the change
  needed a video rather than screenshots.

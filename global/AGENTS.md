# Global agent rules

## What I need from you

End every turn where you're blocked on me, or where the next step needs me,
with a short **What I need from you** section.

- **Numbered, one item each.** One concrete action or decision per item.
- **Be exact.** Say what to do, where (which site, app, file or person), and
  what to send back.
  - Good: "Open the Convex dashboard, add `OPENAI_API_KEY` under Settings →
    Environment Variables, then reply 'done'."
  - Not: "I need the API key set up."
- **Most blocking first.** If there are several, put the quickest or most
  blocking one first, and say what you'll get on with in the meantime.
- **Nothing needed?** Say "Nothing needed from you right now", and say whether
  the work is finished or still going.
- **Never bury a request** for me in the middle of a long update.

## Skills and project setup

Skills you'll find installed at user level are shared by every project. A
project's own `.agents/skills` only holds skills about that project. Where a
project's `AGENTS.md` and a shared skill disagree, the project wins.

## Checking UI changes

After changing anything visible in a web app, check it yourself in headless
Chrome with the **verify-ui** skill before saying it's done. The project's
`AGENTS.md` says how to start the app, which URL to use and how to sign in.

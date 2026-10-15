# Global agent rules

These apply in every project. A project's own `AGENTS.md` adds to them and
wins where the two disagree.

## Working style

- Keep solutions simple and focused. Follow YAGNI; don't add machinery without
  a clear need.
- Stay within the requested scope and keep the blast radius small. Reuse the
  project's existing patterns before inventing new ones.
- Match the surrounding code: naming, comment density and idiom.
- Propose bigger improvements when they'd clearly help, but ask before making
  them.
- When you have enough information to act, act. When a decision is genuinely
  mine to make, ask with a recommendation rather than a list of options.

## Code

- Use the type system fully: no `any`, unchecked casts or duplicated types.
- Give each module and function one clear responsibility.
- Shell out with argument arrays, never by building shell strings.
- Prefer pnpm in JavaScript and TypeScript projects, with the pinned version
  and `--frozen-lockfile` for installs.

## Safety

- Destructive actions are opt-in. Don't delete, overwrite, reset or broadly
  change data, branches or files unless I've clearly asked.
- Never use broad process-killing commands such as `pkill -f`. Stop only the
  processes you started, by PID or with the project's own stop command.
- Production is off limits unless I say otherwise for a specific task.
- Confirm before outward-facing actions (merging, releasing, deploying,
  posting) unless I've asked for them in this conversation.

## Secrets

- Never commit secrets, tokens, cookies, auth state or local environment files.
- Development secrets come from Infisical where a project uses it; don't add
  `.env` files.
- Never ask for passwords, MFA codes or production credentials. Use the
  project's development sign-in helpers instead.

## Git and pull requests

- Work on a branch, never directly on the default branch.
- Write commit messages and PR descriptions that say what changed and why, in
  plain language.
- Before saying something works, run the project's typecheck and tests, and
  say clearly what you didn't verify.

## Writing

- Use British English spelling.
- Write docs in short, plain sentences. When a decision changes, record it in
  the project's decisions log rather than silently editing other docs.

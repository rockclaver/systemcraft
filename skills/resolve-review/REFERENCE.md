# resolve-review — Reference

## Language-specific quality gate commands

| Stack | Type check | Lint | Test |
|-------|-----------|------|------|
| TypeScript / Node | `npx tsc --noEmit` | `npm run lint` | `npm test` |
| TypeScript / Bun | `bunx tsc --noEmit` | `bun run lint` | `bun test` |
| Python | `mypy .` | `ruff check .` | `pytest` |
| Go | _(built into build)_ | `golangci-lint run` | `go test ./...` |
| Rust | `cargo check` | `cargo clippy` | `cargo test` |
| Ruby | _(sorbet if present)_ | `rubocop` | `bundle exec rspec` |

Run all that apply to the project. If a command isn't present in `package.json` scripts or the project, note it and skip — don't fabricate commands.

## Paginating gh API results

The GitHub API returns max 30 items by default. Use `--paginate` to get all:

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate \
  --jq '[.[] | {id, path, line, body, author: .user.login}]'
```

## Checking if a comment thread is already resolved

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate \
  --jq '[.[] | select(.in_reply_to_id == null) | {id, resolved: (.position == null)}]'
```

A `null` position means the line the comment was on no longer exists in the diff — the thread may be outdated. Treat these carefully: they might be resolved by prior commits, or the code may have moved.

## Replying to an inline comment thread

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -X POST \
  -f body="Fixed in <sha>: <explanation>" \
  -F in_reply_to=<parent-comment-id>
```

The `in_reply_to` field groups your reply into the existing thread instead of creating a new one.

## Requesting re-review after addressing all comments

```bash
# Re-request review from the original reviewers
gh pr edit <number> --add-reviewer <username>

# Or via API for multiple reviewers
gh api repos/{owner}/{repo}/pulls/<number>/requested_reviewers \
  -X POST \
  -f 'reviewers[]=<username1>' \
  -f 'reviewers[]=<username2>'
```

Only do this after all gates pass and all threads are resolved/replied to.

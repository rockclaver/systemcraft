---
name: fix-issue
description: Fetch a GitHub issue by number, implement the fix, verify all acceptance criteria and quality gates pass, then open a pull request. Use when the user types /fix-issue <number> or says "fix issue #N", "work on issue N", "implement issue N".
---

# fix-issue

End-to-end workflow: GitHub issue → implementation → quality gates → PR.

## Quick start

```
/fix-issue 42
```

## Workflow

### 1. Fetch & understand the issue

```bash
gh issue view <number> --json title,body,labels,assignees,comments
```

- Extract: title, description, acceptance criteria (look for checkboxes `- [ ]`), labels
- If no explicit acceptance criteria exist, derive them from the description
- State your understanding before writing any code

### 2. Branch

```bash
git checkout -b fix/issue-<number>-<slug>
# slug = kebab-case of issue title, max 5 words
```

Never work directly on main/master.

### 3. Implement

- Scope the fix to exactly what the issue describes — no extra refactors
- Read relevant files before editing
- Make commits as you go with clear messages referencing `#<number>`

### 4. Pre-PR quality gates (ALL must pass)

Run these in order. Stop and fix before moving on if any fail.

```bash
# a. Type checking (if applicable)
npx tsc --noEmit        # TS projects
# or: mypy .            # Python projects

# b. Lint
npm run lint            # JS/TS
# or: ruff check .      # Python

# c. Tests
npm test                # or: pytest, go test ./..., cargo test
```

Then manually verify each acceptance criterion from the issue:
- For each `- [ ]` checkbox in the issue body: confirm it is satisfied
- If the feature has a UI: start dev server, exercise the golden path

**Do not open the PR if any gate fails.**

### 5. Open the PR

```bash
gh pr create \
  --title "<issue title>" \
  --body "$(cat <<'EOF'
## Summary
<bullet list of changes>

## Closes
Closes #<number>

## Acceptance criteria
<copy each criterion with ✅ next to each completed one>

## Test plan
<how a reviewer can verify this works>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Return the PR URL to the user.

## Edge cases

| Situation | Action |
|-----------|--------|
| Issue not found | Report `gh issue view` error, stop |
| No test suite exists | Note it, proceed, flag in PR body |
| Tests fail after fix | Fix tests or the implementation — never skip |
| Issue is ambiguous | Ask one clarifying question before branching |
| Issue already has a branch/PR | Check with user before creating a new one |

See [REFERENCE.md](REFERENCE.md) for language-specific quality gate commands.

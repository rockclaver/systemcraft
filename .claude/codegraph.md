# Code Graph
> Commit: 3bbaa74 | Date: 2026-04-02 | Files: 13 | Lang: markdown + scripts

## Architecture Overview
SystemCraft is a catalog of reusable AI agent skills. Each skill is a self-contained folder under `skills/<domain>/` containing a `SKILL.md` (frontmatter + instructions), an optional `REFERENCE.md` (extended docs), and optional `scripts/` (deterministic helpers). Skills are discovered by matching the `description` frontmatter against user prompts. The repo is organized into four domains: `core` (general-purpose agent workflows), `backend` (server-side tooling), `infra` (deployment/ops), and `ai`/`business` (reserved for future skills).

## Module Index

### skills/core/

| File | Purpose | Key Exports | Used by |
|---|---|---|---|
| `code-graph/SKILL.md` | Builds and maintains a `.claude/codegraph.md` codebase index so the agent can navigate a repo from one file instead of scanning many. | skill: `code-graph` | — |
| `code-graph/REFERENCE.md` | Documents the codegraph file format, node template, folder-level summary format, and token budget rules. | — | `code-graph/SKILL.md` |
| `code-graph/scripts/scan.js` | CLI script that discovers files, extracts exports/imports via grep, and emits a structured draft codegraph — no AI tokens spent. | — | `code-graph/SKILL.md` |
| `write-a-skill/SKILL.md` | Guides the agent in creating new skills with proper frontmatter, progressive disclosure, and bundled resources. | skill: `write-a-skill` | — |
| `grill-me/SKILL.md` | Conducts a relentless Socratic interview to stress-test a plan or design until all decision branches are resolved. | skill: `grill-me` | — |
| `refactor-codebase/SKILL.md` | Incrementally refactors a codebase toward a scalable structure using a phased plan without breaking the working system. | skill: `refactor-codebase` | — |
| `refactor-codebase/REFERENCE.md` | Reference patterns and worked examples for phased refactoring strategies. | — | `refactor-codebase/SKILL.md` |
| `write-tests/SKILL.md` | Writes high-value automated tests by inspecting the repo, inferring the test stack, and targeting risky untested behavior first. | skill: `write-tests` | — |
| `write-tests/REFERENCE.md` | Extended guidance on test strategies, coverage tooling, and stack-specific test patterns. | — | `write-tests/SKILL.md` |
| `write-tests/scripts/repo_test_probe.py` | Python probe that inspects a repo to detect the testing framework, coverage config, and existing test structure. | — | `write-tests/SKILL.md` |
| `prd-to-plan/SKILL.md` | Converts a PRD into a multi-phase tracer-bullet implementation plan saved to `./plans/`. | skill: `prd-to-plan` | — |
| `write-a-prd/SKILL.md` | Guides the agent through user interviews and codebase exploration to produce a PRD, then submits it as a GitHub issue. | skill: `write-a-prd` | — |

### skills/backend/

| File | Purpose | Key Exports | Used by |
|---|---|---|---|
| `design-api/SKILL.md` | Designs and implements consistent REST API endpoints (handlers, routing, validation, error responses) with full test coverage. | skill: `design-api` | — |
| `design-api/REFERENCE.md` | Canonical patterns for DRY API design: shared utilities, error shapes, validation conventions, and endpoint templates. | — | `design-api/SKILL.md` |
| `migrate-to-better-auth/SKILL.md` | Detects any existing auth system and produces a phased migration plan to better-auth, rewriting config, routes, and seed data. | skill: `migrate-to-better-auth` | — |
| `migrate-to-better-auth/REFERENCE.md` | Provider-specific migration notes, better-auth plugin options, and common pitfall patterns. | — | `migrate-to-better-auth/SKILL.md` |

### skills/infra/

| File | Purpose | Key Exports | Used by |
|---|---|---|---|
| `dockerize-and-deploy/SKILL.md` | Produces production-grade Dockerfiles, docker-compose setup with volumes, and a pre-flight validation script for a given repo. | skill: `dockerize-and-deploy` | — |
| `dockerize-and-deploy/REFERENCE.md` | Deployment patterns, volume configuration examples, and validation script templates. | — | `dockerize-and-deploy/SKILL.md` |

## Config & Schema Files

- `README.md` — project overview, skill authoring guidelines, installation instructions, and discovery/troubleshooting guide

---
_Regenerate: `node <skill-dir>/scripts/scan.js > .claude/codegraph.draft.md`_

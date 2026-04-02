# Write Feature PRD Reference

## Repo Audit Checklist

Before writing the PRD, gather evidence for:

- Entry points: routes, CLI commands, jobs, or UI surfaces involved
- Current modules: services, repositories, components, workers, validators
- Durable contracts: API shapes, event names, schema entities, permission rules
- Existing quality bar: tests, telemetry, error handling, rollout patterns
- Reuse candidates: anything that already solves 30% or more of the feature
- Delivery helpers: relevant skills, scripts, generators, or platform tools

Record what is confirmed from code separately from what is inferred.

## Reuse Inventory Format

Use a compact table or bullet list like this:

- **Reuse**
  - `BillingService`: already creates invoices; extend for subscription renewals
  - `POST /api/projects`: response shape and auth guard to mirror
- **Modify**
  - `ProjectPolicy`: new permission check needed for archived projects
  - background worker pipeline: add one new event handler
- **Net-new**
  - feature flag for staged rollout
  - analytics event for user adoption

If nothing reusable exists, say so explicitly and summarize how you verified that.

## Decision Prompts

Resolve these before finalizing the PRD:

- What user-visible behavior changes first?
- What can be reused unchanged?
- What must be modified, and what are the likely blast-radius areas?
- Are there schema, API, queue, or auth implications?
- Does rollout need migration, backfill, or feature flags?
- What can fail, and how should the system degrade?
- What is the smallest demoable slice of the feature?

## PRD Template

```md
## Problem Statement

Describe the user or business problem in product terms.

## Current State Findings

- Confirmed findings from the codebase
- Existing modules, flows, or contracts that are relevant
- Important constraints imposed by the current architecture

## Proposed Solution

Describe the intended user-facing behavior and the high-level system approach.

## User Stories

1. As a <actor>, I want <feature>, so that <benefit>
2. ...

## Reuse And Change Surface

### Reuse

- Existing modules, services, routes, components, or tools to leverage

### Modify

- Existing areas that must change

### Net-new

- Capabilities that must be introduced

## Implementation Decisions

- Durable architectural decisions
- Data model or schema impact
- API, event, worker, or integration impact
- Auth, permissions, and validation rules

## Tooling And Delivery Plan

- Skills or tools that should be used after PRD approval
- Suggested sequencing, such as `/prd-to-plan` then `/design-api`

## Testing And Observability

- What behavior must be tested
- Prior art in the codebase to mirror
- Logging, metrics, alerts, or tracing to add

## Rollout And Migration

- Feature flags, backfills, migrations, or operational steps

## Risks And Open Questions

- Remaining uncertainties, assumptions, and tradeoffs

## Out Of Scope

- Explicitly excluded work
```

## Handoff Guidance

After approval:

- Use `/prd-to-plan` if implementation should be phased.
- Use `/design-api` for API-heavy slices.
- Use `/write-tests` for regression coverage.
- Use `/grill-me` if unresolved decisions still feel weak.

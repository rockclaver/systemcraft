---
name: design-api
description: Design and implement consistent, DRY REST API endpoints for database models — handlers, routing, validation, error responses, and shared utilities — then generate test coverage for every endpoint. Use when the user asks to write an API, add endpoints for a model, build a REST layer, or create CRUD routes.
---

# Design API

Write well-structured, consistent API endpoints for a given model. Reuse existing patterns in the codebase — never invent new conventions if good ones already exist.

## Quick Start

1. Read the model and existing API layer.
2. Identify shared utilities to reuse (error handlers, validators, response helpers).
3. Write the endpoints following the contract rules below.
4. Run `/write-tests` on the new endpoints.

## Workflow

### 1. Read before writing

Read:
- The database model (schema, relations, field types)
- One existing handler/controller to match the code's style
- The router/route registration pattern
- Any shared middleware (auth guards, validation wrappers, error handlers)

Do not write anything until you understand the conventions in use.

### 2. Identify what to reuse

Before creating any helper, check if it already exists:
- Response shape helpers (`{ data, error, meta }`)
- Pagination utilities
- Validation schemas (Zod, Joi, Yup)
- Auth/permission guards
- Error classes (`NotFoundError`, `ValidationError`, etc.)
- Database query wrappers or repository patterns

Only create a new utility when nothing existing fits.

### 3. Define the API contract

Before writing handlers, write down the contract:

```
GET    /resources           → list (paginated)
GET    /resources/:id       → single resource or 404
POST   /resources           → create, return 201 + created resource
PUT    /resources/:id       → full replace or 404
PATCH  /resources/:id       → partial update or 404
DELETE /resources/:id       → 204 No Content or 404
```

Confirm with the user if any of these should be omitted or if nested routes are needed (e.g. `/users/:id/posts`).

### 4. Write the handlers

Rules:
- Each handler does one thing: validate → call service/repo → respond
- Never query the DB directly in a handler — go through a service or repository layer
- Use shared error handling — never duplicate `try/catch` boilerplate per handler
- All responses use the same shape — `{ data }` for success, `{ error, message }` for failure
- 404s returned from the service layer must propagate to a consistent error response
- Never expose internal DB errors or stack traces to the client

### 5. Write tests with `/write-tests`

Invoke `/write-tests` targeting the new handlers. Ensure coverage for:
- Happy path for each verb
- 404 when resource does not exist
- 400/422 on invalid input (missing required fields, wrong types)
- 401/403 if the route is auth-guarded
- Edge cases specific to the model (unique constraint violations, relation cascades)

### 6. Verify

```bash
npx tsc --noEmit        # no type errors
npm test -- --testPathPattern=<resource>  # targeted test run
```

Fix failures before moving to the next model.

## Guardrails

- Never add an endpoint that doesn't map to a user-facing need — no speculative routes.
- Do not add filtering, sorting, or pagination unless asked; stub the interface cleanly so it can be added later.
- If the existing codebase has no service/repository layer, note it and ask the user before adding one — use `/refactor-codebase` for that work separately.
- Keep handler files thin — if a handler exceeds ~30 lines, push logic into the service layer.

## References

- [REFERENCE.md](REFERENCE.md) — response shape conventions, error handling patterns, validation examples, pagination contract, and test structure templates.

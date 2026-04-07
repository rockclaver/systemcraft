# API Design Reference

## Response Shape Contract

All endpoints return the same envelope. Never deviate from this shape.

```typescript
// Success (single resource)
{ "data": { ...resource } }

// Success (list)
{ "data": [...resources], "meta": { "total": 42, "page": 1, "perPage": 20 } }

// Created
HTTP 201
{ "data": { ...resource } }

// No content (DELETE)
HTTP 204
(empty body)

// Client error
HTTP 400 | 404 | 409 | 422
{ "error": "NOT_FOUND", "message": "User with id 123 not found" }

// Server error
HTTP 500
{ "error": "INTERNAL_ERROR", "message": "Something went wrong" }
```

Never return raw DB records or ORM objects directly — map to a response DTO first.

---

## Error Handling Pattern

Use a centralized error handler. Handlers should throw — never `res.status(500).json(...)` inline.

```typescript
// errors.ts
export class AppError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
  ) {
    super(message);
  }
}
export class NotFoundError extends AppError {
  constructor(resource: string, id: string | number) {
    super(404, 'NOT_FOUND', `${resource} with id ${id} not found`);
  }
}
export class ValidationError extends AppError {
  constructor(message: string) {
    super(422, 'VALIDATION_ERROR', message);
  }
}
export class ConflictError extends AppError {
  constructor(message: string) {
    super(409, 'CONFLICT', message);
  }
}

// errorMiddleware.ts (Express)
export function errorMiddleware(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.code, message: err.message });
  }
  console.error(err);
  res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Something went wrong' });
}
```

---

## Handler Structure (Express)

```typescript
// handlers/users.ts
import { RequestHandler } from 'express';
import { UserService } from '../services/userService';
import { NotFoundError } from '../errors';
import { createUserSchema, updateUserSchema } from '../validation/userSchemas';

export const getUser: RequestHandler = async (req, res, next) => {
  try {
    const user = await UserService.findById(req.params.id);
    if (!user) throw new NotFoundError('User', req.params.id);
    res.json({ data: user });
  } catch (err) {
    next(err);
  }
};

export const createUser: RequestHandler = async (req, res, next) => {
  try {
    const body = createUserSchema.parse(req.body); // throws ValidationError on failure
    const user = await UserService.create(body);
    res.status(201).json({ data: user });
  } catch (err) {
    next(err);
  }
};
```

---

## Validation Pattern (Zod)

```typescript
// validation/userSchemas.ts
import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'member']).default('member'),
});

export const updateUserSchema = createUserSchema.partial(); // PATCH — all fields optional

export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
```

Wire Zod errors into the error middleware:
```typescript
import { ZodError } from 'zod';
// in errorMiddleware:
if (err instanceof ZodError) {
  return res.status(422).json({ error: 'VALIDATION_ERROR', message: err.errors[0].message });
}
```

---

## Service / Repository Layer

```typescript
// services/userService.ts
import { db } from '../db';
import { CreateUserInput, UpdateUserInput } from '../validation/userSchemas';

export const UserService = {
  findById: (id: string) =>
    db.user.findUnique({ where: { id } }),

  findAll: (page = 1, perPage = 20) =>
    Promise.all([
      db.user.findMany({ skip: (page - 1) * perPage, take: perPage }),
      db.user.count(),
    ]).then(([data, total]) => ({ data, meta: { total, page, perPage } })),

  create: (input: CreateUserInput) =>
    db.user.create({ data: input }),

  update: (id: string, input: UpdateUserInput) =>
    db.user.update({ where: { id }, data: input }),

  delete: (id: string) =>
    db.user.delete({ where: { id } }),
};
```

---

## Pagination Contract

Standard query params: `?page=1&perPage=20`

```typescript
// utils/pagination.ts
export function parsePagination(query: Record<string, unknown>) {
  const page = Math.max(1, Number(query.page) || 1);
  const perPage = Math.min(100, Math.max(1, Number(query.perPage) || 20));
  return { page, perPage };
}
```

---

## Test Structure Template

```typescript
// handlers/users.test.ts
describe('GET /users/:id', () => {
  it('returns 200 with user data for valid id', async () => { ... });
  it('returns 404 when user does not exist', async () => { ... });
  it('returns 401 when unauthenticated', async () => { ... }); // if guarded
});

describe('POST /users', () => {
  it('returns 201 with created user', async () => { ... });
  it('returns 422 when email is missing', async () => { ... });
  it('returns 422 when email is invalid', async () => { ... });
  it('returns 409 when email already exists', async () => { ... });
});

describe('PATCH /users/:id', () => {
  it('returns 200 with updated fields', async () => { ... });
  it('returns 404 when user does not exist', async () => { ... });
  it('returns 422 when input is invalid', async () => { ... });
});

describe('DELETE /users/:id', () => {
  it('returns 204 on success', async () => { ... });
  it('returns 404 when user does not exist', async () => { ... });
});
```

---

## Nested Resource Routes

Only nest one level deep. Deeper nesting creates fragile contracts.

```
✓  GET /users/:userId/posts
✗  GET /users/:userId/posts/:postId/comments/:commentId
```

For deeply nested resources, use flat routes with query params:
```
GET /comments?postId=:postId
```

---

## HTTP Status Code Quick Reference

| Scenario | Status |
|---|---|
| Successful read | 200 |
| Successful create | 201 |
| Successful delete / no body | 204 |
| Bad input / missing field | 400 or 422 |
| Unauthenticated | 401 |
| Forbidden (authenticated, no permission) | 403 |
| Resource not found | 404 |
| Conflict (duplicate, state violation) | 409 |
| Server error | 500 |

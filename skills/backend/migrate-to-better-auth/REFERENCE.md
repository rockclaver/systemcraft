# Migration Reference

## Schema Mappings by Source Library

### NextAuth v4 → better-auth

| NextAuth | better-auth | Change |
|---|---|---|
| `User.emailVerified` (Date\|null) | `user.emailVerified` (boolean) | Type coercion required |
| `Session.sessionToken` | `session.token` | Rename |
| `Session.expires` | `session.expiresAt` | Rename |
| `Account.providerAccountId` | `account.accountId` | Rename |
| `Account.provider` | `account.providerId` | Rename |
| `Account.access_token` | `account.accessToken` | Rename (camelCase) |
| `Account.refresh_token` | `account.refreshToken` | Rename |
| `Account.expires_at` (unix int) | `account.accessTokenExpiresAt` (Date) | Type + rename |
| `VerificationToken` | `verification` | Table rename |
| `VerificationToken.identifier` | `verification.identifier` | Same |
| `VerificationToken.token` | `verification.value` | Rename |
| `VerificationToken.expires` | `verification.expiresAt` | Rename |

**emailVerified migration script (Prisma example)**:
```sql
ALTER TABLE "user" ADD COLUMN "emailVerified" BOOLEAN NOT NULL DEFAULT false;
UPDATE "user" SET "emailVerified" = true WHERE "emailVerifiedDate" IS NOT NULL;
ALTER TABLE "user" DROP COLUMN "emailVerifiedDate";
```

### Lucia v3 → better-auth

| Lucia | better-auth | Change |
|---|---|---|
| `User` (custom shape) | `user` | Add `name`, `image`, `emailVerified` |
| `Session.id` | `session.id` | Same |
| `Session.userId` | `session.userId` | Same |
| `Session.expiresAt` | `session.expiresAt` | Same |
| No accounts table | `account` | Add for OAuth |

Lucia stores OAuth in a separate key table — map `Key` → `account` where `key.id` = `{providerId}:{accountId}`.

### Passport.js → better-auth

Passport doesn't own the DB schema — the existing `users` table is custom. Map by convention:
- Identify `passport.use(new LocalStrategy(...))` → enable `emailAndPassword`
- Identify `passport.use(new GoogleStrategy(...))` → enable `socialProviders.google`
- Serialize/deserialize user maps to `session.userId` lookup

### Custom JWT → better-auth

- JWT payload `sub` → `session.userId`
- JWT `exp` → `session.expiresAt`
- No session table exists — better-auth will create one (database-backed by default)
- Existing tokens become invalid after migration — communicate this to users (force re-login)

### Clerk → better-auth

Clerk is a hosted service — no local DB schema to migrate. Migration path:
1. Export users from Clerk dashboard (CSV or API)
2. Import into better-auth `user` table
3. Users must reset passwords (Clerk doesn't expose password hashes)
4. Replace `@clerk/nextjs` imports with `better-auth/client`
5. Replace `<ClerkProvider>` with better-auth session provider

---

## ORM Adapter Patterns

### Prisma

```typescript
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export const auth = betterAuth({
  database: prismaAdapter(prisma, { provider: "postgresql" }),
  // ...
});
```

Generate schema additions: `npx @better-auth/cli generate --output ./prisma/schema.prisma`

### Drizzle

```typescript
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { db } from "./db";

export const auth = betterAuth({
  database: drizzleAdapter(db, { provider: "pg" }),
});
```

### Raw / node-postgres

```typescript
import { Pool } from "pg";
export const auth = betterAuth({
  database: { dialect: "pg", db: new Pool({ connectionString: process.env.DATABASE_URL }) },
});
```

---

## Server Config Template

```typescript
// src/lib/auth.ts
import { betterAuth } from "better-auth";
import { twoFactor } from "better-auth/plugins";

export const auth = betterAuth({
  database: /* adapter */,

  emailAndPassword: {
    enabled: true,
    // requireEmailVerification: true,
  },

  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    },
    github: {
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    },
  },

  plugins: [
    twoFactor(),
    // organization(), adminPlugin(), ...
  ],
});

export type Auth = typeof auth;
```

## Route Handler by Framework

### Next.js App Router
```typescript
// app/api/auth/[...all]/route.ts
import { auth } from "@/lib/auth";
import { toNextJsHandler } from "better-auth/next-js";
export const { GET, POST } = toNextJsHandler(auth);
```

### Express / Hono / Fastify
```typescript
app.all("/api/auth/*", (req, res) => auth.handler(req, res));
```

---

## Seed Data Patterns

### Before (NextAuth-style)
```typescript
await prisma.user.create({
  data: {
    email: "admin@example.com",
    emailVerified: new Date(), // ← Date
    accounts: {
      create: {
        provider: "github",          // ← old name
        providerAccountId: "123456", // ← old name
        type: "oauth",
      }
    }
  }
});
```

### After (better-auth)
```typescript
await prisma.user.create({
  data: {
    email: "admin@example.com",
    emailVerified: true,  // ← boolean
    accounts: {
      create: {
        providerId: "github",   // ← new name
        accountId: "123456",    // ← new name
        createdAt: new Date(),
        updatedAt: new Date(),
      }
    }
  }
});
```

---

## Environment Variables Checklist

```bash
# Required always
BETTER_AUTH_SECRET=        # 32+ char random string
BETTER_AUTH_URL=           # e.g. http://localhost:3000

# Per OAuth provider
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=

# Optional
DATABASE_URL=              # if not already set
REDIS_URL=                 # if using Redis session store
```

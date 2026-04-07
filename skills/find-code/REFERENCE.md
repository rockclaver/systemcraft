# Find Code Reference

## Output Format

Every mode always returns `file:line: content`. The agent uses this to jump directly:

```
src/services/userService.ts:14:export async function createUser(
src/handlers/users.ts:31:  const user = await createUser(body);
tests/users.test.ts:88:  it('creates user', async () => {
```

`EMPTY` is returned (with a tip) when nothing matches — refine and re-run.

---

## Search Modes

### `text` (default) — grep for any pattern
```bash
find.sh "TODO"
find.sh "DATABASE_URL"
find.sh "throw new" --ext ts
find.sh "console\.log" --in src
```

### `--file` — find files by name
```bash
find.sh --file "userService"       # matches userService.ts, userService.test.ts
find.sh --file "migration"         # finds all migration files
find.sh --file ".env" --in .       # find env files at root
```

### `--def` — find symbol definitions
```bash
find.sh --def "createUser"         # function/class/const named createUser
find.sh --def "UserService"        # class definition
find.sh --def "NotFoundError"      # class or type alias
find.sh --def "parseDate" --ext ts # scoped to TypeScript only
```

Matches: `export function`, `export class`, `export const X =`, `def X(`, `func X(`, `type X`

### `--callers` — find usages
```bash
find.sh --callers "createUser"     # everywhere createUser is called
find.sh --callers "UserService"    # everywhere UserService is referenced
find.sh --callers "prisma.user"    # all prisma.user.* calls
```

Automatically filters out definition lines to show only call sites.

### `--imports` — find where a module is imported
```bash
find.sh --imports "userService"    # all files importing userService
find.sh --imports "better-auth"    # all files importing the package
find.sh --imports "prisma/client"  # all files importing prisma
```

---

## Filters

```bash
--ext ts          # only .ts files
--ext py          # only .py files
--in src/services # scope to folder
--in src          # scope to src/
--flags "-i"      # case-insensitive
--flags "-w"      # whole-word match only
--limit 100       # raise result cap (default 50)
```

Combine freely:
```bash
find.sh "findById" --ext ts --in src/services --flags "-i"
```

---

## Common Search Scenarios

### "Where is this function defined?"
```bash
find.sh --def "handleWebhook"
# → src/handlers/stripe.ts:22:export async function handleWebhook(
```

### "What files import this module?"
```bash
find.sh --imports "authService"
# → src/handlers/auth.ts:3:import { signToken } from '../services/authService';
# → src/middleware/auth.ts:2:import { verifyToken } from '../services/authService';
```

### "Where is this env var used?"
```bash
find.sh "STRIPE_SECRET_KEY"
# → src/lib/env.ts:8:  STRIPE_SECRET_KEY: z.string(),
# → src/services/billing.ts:5:const stripe = new Stripe(env.STRIPE_SECRET_KEY);
```

### "Find all TODO/FIXME comments"
```bash
find.sh "TODO\|FIXME\|HACK" --flags "-E"
```

### "Find all routes/endpoints"
```bash
find.sh "router\.\(get\|post\|put\|patch\|delete\)" --flags "-E" --ext ts
find.sh "app\.\(get\|post\)" --flags "-E" --ext js
```

### "Find all error throws"
```bash
find.sh "throw new" --ext ts --in src
```

### "Find all database queries for a model"
```bash
find.sh "prisma\.user\." --flags "-E"
find.sh "db\.select.*from.*users" --flags "-iE"
```

### "Find test for a specific module"
```bash
find.sh --file "userService.test"
find.sh --file "users.spec"
```

### "Find where a type is used"
```bash
find.sh --callers "CreateUserInput" --ext ts
```

### "Find all files in a folder"
```bash
find.sh --file "" --in src/handlers   # all files under handlers/
```

---

## Refinement Decision Tree

```
Results empty?
  → Try --flags "-i" (case-insensitive)
  → Try --file mode instead of text
  → Broaden pattern: "User" instead of "createUser"

Too many results?
  → Add --in <folder> to scope
  → Add --ext <type> to filter by language
  → Use --def or --callers instead of text

Results include test/generated files?
  → Add --in src (excludes tests/)
  → Add --flags "--exclude=*.test.ts --exclude=*.spec.ts"

Wrong language matches?
  → Add --ext ts / --ext py / --ext go
```

---

## Agent Decision Protocol

```
NEED TO FIND SOMETHING?
  ↓
Run find.sh with appropriate mode
  ↓
Results contain file:line?
  → YES → Read that file at that line. Done.
  → EMPTY → Refine pattern and re-run (max 3 attempts)
  → TOO MANY → Narrow with --in or --ext and re-run
  ↓
Never open a file to search inside it.
Never guess file locations.
Never scan a directory listing.
```

# Super Admin

**Role:** `SUPER_ADMIN` · **Seeded on startup** · `superadmin@greentech.local`

Platform owner. Sees every municipality and can do everything a Municipal Admin can, without
the municipality scope.

Console: `/admin/super` in `app/web/greentech`.

---

## Tasks

| # | Task | API | Status |
| --- | --- | --- | --- |
| 1 | Log in to the console | `POST /auth/login` | Done |
| 2 | Platform dashboard across every municipality | `GET /api/v1/admin/overview` | Done |
| 3 | **Create Municipal Admins** | `POST /api/v1/admin/users` | Done |
| 4 | Create collectors and recyclers anywhere | `POST /api/v1/admin/users` | Done |
| 5 | List / search every user, unscoped | `GET /api/v1/admin/users` | Done |
| 6 | Enable / disable any account | `PATCH /api/v1/admin/users/{id}` | Done |
| 7 | **Create a municipality** | `POST /api/v1/admin/municipalities` | Done |
| 8 | Edit a municipality and its depot | `PATCH /api/v1/admin/municipalities/{id}` | Done |
| 9 | Manage collection points in any municipality | `/api/v1/admin/collection-points` | Done |
| 10 | Platform leaderboard | `GET /api/v1/leaderboard` | Done |
| 11 | Service health check | `GET /health` | Done |
| 12 | View system configuration | Console panel | Done (read-only) |

### What only a Super Admin can do

- Create a `MUNICIPAL_ADMIN` — a municipal admin attempting this gets `403`.
- Create or edit a **municipality**, which includes the depot coordinates every collector route
  starts and ends at.
- See users across **all** municipalities; a municipal admin's list is filtered to their own.
- `overview.scope` returns `PLATFORM` rather than `MUNICIPALITY`.

### Seeding

`AdminSeeder` runs after the geo seed (`@Order(20)`) and creates both admin accounts if they do
not exist. **There is no default password** — with `ADMIN_SEED_SUPER_PASSWORD` unset, seeding is
skipped and logged, so a known credential can never ship by accident.

> Do not put `#` in a password inside `.env`. It starts a comment and silently truncates the
> value — this cost real debugging time.

---

## Not built yet

| Task | Note |
| --- | --- |
| Editing config from the console | Everything is env vars plus a restart |
| Audit log of admin actions | Actions are logged to the app log, not stored |
| Deleting a municipality | Only soft `active` toggling |
| Cross-municipality comparison charts | Overview aggregates rather than compares |
| Role transfer / reassigning a user's municipality | Field exists; no console control |
| Impersonation for support | No such flow |
| API keys / rate limits per municipality | Not modelled |

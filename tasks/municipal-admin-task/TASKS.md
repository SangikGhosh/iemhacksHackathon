# Municipal Admin

**Role:** `MUNICIPAL_ADMIN` · **Created by:** Super Admin · **Seeded:** `hmc.admin@greentech.local`

Runs one municipality. Scoped to their own body — they never see another municipality's staff.

Console: `/admin/municipal` in `app/web/greentech`.

---

## Tasks

| # | Task | API | Status |
| --- | --- | --- | --- |
| 1 | Log in to the console | `POST /auth/login` | Done |
| 2 | Dashboard — scans, waste diverted, points, bin split, 14-day trend | `GET /api/v1/admin/overview` | Done |
| 3 | List / search / filter users | `GET /api/v1/admin/users` | Done |
| 4 | Create a collector | `POST /api/v1/admin/users` | Done |
| 5 | Create a recycler | `POST /api/v1/admin/users` | Done |
| 6 | Enable / disable an account | `PATCH /api/v1/admin/users/{id}` | Done |
| 7 | View collection points | `GET /api/v1/admin/collection-points` | Done |
| 8 | Add a collection point | `POST /api/v1/admin/collection-points` | Done |
| 9 | Edit a collection point | `PATCH /api/v1/admin/collection-points/{id}` | Done |
| 10 | Retire a collection point | `DELETE /api/v1/admin/collection-points/{id}` | Done |
| 11 | View analytics — top materials, pickup status, marketplace | `GET /api/v1/admin/overview` | Done |
| 12 | View pricing and reward rates | Console panel | Done (read-only) |

### Rules that apply

- **Can only create `COLLECTOR` and `RECYCLER`.** Creating a `MUNICIPAL_ADMIN` returns `403`.
- New accounts **inherit the admin's municipality** automatically.
- Can only modify collectors and recyclers, and only within their own municipality (`403`).
- Cannot touch a `SUPER_ADMIN` account.
- Admin-created accounts skip OTP — `emailVerified` is set true, so the person can log in
  straight away with the password the admin set.
- **Disabling is immediate:** the existing JWT stops working on the next request and a fresh
  login returns `403`.
- Cannot create or edit municipalities — that is Super Admin only (`403`).

### Retiring a point

`DELETE` is a **soft delete** — it sets `active = false`. Nothing is removed, so pickups that
already reference the point keep their history.

---

## Not built yet

| Task | Note |
| --- | --- |
| Editing pricing from the console | Rates are env vars (`DOORSTEP_POINTS_PER_KG` etc.) and need a restart |
| Downloadable reports (CSV / PDF) | Analytics are on-screen only |
| Assigning a pickup to a specific collector | Collectors self-select from the open feed |
| Ward-level breakdown | Points carry a `ward` but nothing aggregates by it yet |
| Complaints / grievance handling | No model |
| Alerts on a full bin | Needs the IoT fill-level sensors from the hardware track |
| Vehicle / fleet register | Capacity is one global env value, not per vehicle |

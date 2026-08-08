# Role tasks

One folder per role. Each `TASKS.md` lists what that role can do, which API backs it, whether
it is built, and what is still open.

| Folder | Role | Created by |
| --- | --- | --- |
| [collector-task](collector-task/TASKS.md) | `COLLECTOR` | Municipal Admin |
| [recycler-task](recycler-task/TASKS.md) | `RECYCLER` | Municipal Admin |
| [municipal-admin-task](municipal-admin-task/TASKS.md) | `MUNICIPAL_ADMIN` | Super Admin |
| [super-admin-task](super-admin-task/TASKS.md) | `SUPER_ADMIN` | Seeded on startup |

Citizens self-register through `/auth/register`; every other role is created by an
administrator, so there is no public sign-up path to a privileged account.

Status key: **Done** — built and tested. **Partial** — API exists, no UI. **Open** — not built.

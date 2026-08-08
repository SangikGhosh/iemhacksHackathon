# api-java

Auth service for the waste management platform. Spring Boot 3.5 / Java 17 / PostgreSQL.

## Run

```bash
mvn spring-boot:run
```

`.env` is committed-ignored and already filled in locally. It points at the `greentech`
database on `localhost:5432` (user `myuser`) — deliberately NOT `jotterly`, so this app's
`users` table cannot collide with the other project's. Schema is created by Hibernate
(`DDL_AUTO=update`); there is no Flyway here, so never set `validate`.

## Endpoints

Full spec in [docs/openapi.yml](docs/openapi.yml) — paste it into
[editor.swagger.io](https://editor.swagger.io) to browse or generate a client.

| Method | Path | Auth | Body |
| --- | --- | --- | --- |
| POST | `/auth/send-otp` | public | `{ "email" }` |
| POST | `/auth/register` | public | `{ "email", "fullName", "password", "otp", "role" }` |
| POST | `/auth/login` | public | `{ "email", "password" }` |
| POST | `/auth/google` | public | `{ "idToken", "role" }` |
| GET | `/auth/me` | Bearer | — |
| GET | `/health` | public | — |

`role` is optional and defaults to `CITIZEN`. Only `CITIZEN`, `COLLECTOR` and `RECYCLER` can be
self-assigned; `MUNICIPAL_ADMIN` and `SUPER_ADMIN` are rejected with 403 and must be set in the DB.

### Auth response

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": {
    "id": "uuid",
    "email": "john@gmail.com",
    "fullName": "John Doe",
    "role": "CITIZEN",
    "points": 120
  }
}
```

`GET /auth/me` returns the `user` object alone.

## Mail (Resend)

- OTP — sent synchronously by `/auth/send-otp`; a delivery failure returns 502.
- Welcome — after register and after first Google sign-in.
- Sign-in alert — after every returning login, with time and IP.

## Notes

- OTPs live in memory (10 min TTL) — fine for a single instance, swap for Redis if you scale out.
- The OTP is written to the app log so you can test without opening an inbox. Strip that from
  `OtpService.generate` before anything resembling production.
- Access tokens only, 7-day TTL, no refresh tokens — so `JWT_EXPIRATION` is 7 days, not the
  15 minutes Jotterly uses (it has a refresh endpoint; this does not).

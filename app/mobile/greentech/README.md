# greentech (mobile)

Flutter client for the GreenTech waste-management platform. Talks to the Spring
service in [`service/api-java`](../../../service/api-java).

## Run

```bash
flutter pub get
flutter run
```

The backend must be running on port `8080` first. The app picks its host
automatically:

| Target | Base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:8080` |
| iOS simulator / desktop / web | `http://localhost:8080` |
| Physical device | pass `--dart-define` (below) |

A physical phone cannot reach `localhost` — point it at your machine's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8080
```

## Configuration

Everything is passed at build time; nothing is committed.

| Define | Required | Purpose |
| --- | --- | --- |
| `API_BASE_URL` | no | Overrides the auto-detected host. No trailing slash. |
| `GOOGLE_SERVER_CLIENT_ID` | for Google sign-in | The **Web** OAuth client ID. Empty hides the Google button. |
| `MAPBOX_ACCESS_TOKEN` | for the map | Mapbox public token (`pk.…`). Empty leaves the map tiles blank. |

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.42:8080 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=1234-abc.apps.googleusercontent.com \
  --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here
```

Or keep them in a gitignored file and pass them together:

```bash
cp dart_define.example.json dart_define.json
flutter run --dart-define-from-file=dart_define.json
```

Read in [`lib/Config/ApiConfig.dart`](lib/Config/ApiConfig.dart) and
[`lib/Config/MapConfig.dart`](lib/Config/MapConfig.dart).

## Google OAuth setup

The app never verifies the Google token itself. It obtains an **ID token** from
Google and posts it to `POST /auth/google`; the backend verifies the signature
and the `aud` claim against its own `GOOGLE_CLIENT_ID`. Both sides must
therefore point at the **same Web client ID**.

### 1. Create the OAuth clients

In [Google Cloud Console](https://console.cloud.google.com) → one project for
the whole app:

1. **APIs & Services → OAuth consent screen** — External, add your account
   under *Test users* while unpublished.
2. **APIs & Services → Credentials → Create credentials → OAuth client ID**,
   three times:

| Type | Fields | Gives you |
| --- | --- | --- |
| **Web application** | no redirect URI needed | the client ID **both** the app and backend use |
| **Android** | package `com.example.greentech` + SHA-1 | nothing to copy — it just authorises the app |
| **iOS** | bundle `com.example.greentech` | an iOS client ID + reversed client ID |

Debug SHA-1 for this machine:

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android | grep SHA1
```

Add the release keystore's SHA-1 too before shipping, or Google sign-in works in
debug and fails in release.

### 2. Wire the backend

`service/api-java/.env` does not exist yet — copy the template and fill it in:

```bash
cd service/api-java && cp .env.example .env
```

Set the **Web** client ID (not the Android or iOS one):

```
GOOGLE_CLIENT_ID=1234-abc.apps.googleusercontent.com
```

`JWT_SECRET` and `RESEND_API_KEY` are also blank by default. Without a JWT
secret the service cannot mint tokens; without a Resend key the signup OTP email
fails with `502`.

### 3. Wire the app

Still to be done — the button exists but is not connected to a Google SDK:

1. `flutter pub add google_sign_in`
2. Android: place `google-services.json` in `android/app/`
3. iOS: add the reversed iOS client ID as a URL scheme in `ios/Runner/Info.plist`
4. Replace the placeholder in `_continueWithGoogle` in
   [`lib/Screen/Auth/AuthSelectionScreen.dart`](lib/Screen/Auth/AuthSelectionScreen.dart)
   with: obtain `idToken` → `ApiService.loginWithGoogle(idToken: ...)` →
   `ref.read(sessionProvider.notifier).adopt(session)` → `context.go('/home')`

`ApiService.loginWithGoogle` is already written and matches the endpoint.

### Behaviour worth knowing

- **One endpoint does signup and login.** An unknown Google email creates the
  account; a known one signs in. The client cannot tell the two apart, and does
  not need to.
- **`role` only applies on account creation.** A returning user's role is never
  changed by the request. Since the button sits on the selection screen with the
  default `CITIZEN`, anyone signing up with Google becomes a Citizen
  permanently. Collectors and Recyclers must use the email flow, or the button
  has to move after the role step.
- **Login methods cannot mix.** A Google-created email rejects password login
  with `Please use GOOGLE to log in`, and a password-created email rejects
  Google with `Account already exists with a different login method`.

## Auth flow

Signup is five steps — email → OTP → name → password → role — because
`POST /auth/register` verifies the OTP and creates the account in one call.
A rejected OTP returns the user to the code step with the digits cleared; a
taken email returns them to the first step.

The access token (7 days, no refresh token) is stored with `shared_preferences`
and restored on launch. An expired token is discarded and the user signs in
again.

| Screen | Endpoint |
| --- | --- |
| Signup step 1 | `POST /auth/send-otp` |
| Signup step 5 | `POST /auth/register` |
| Login | `POST /auth/login` |
| Google button | `POST /auth/google` |
| Splash / dashboard refresh | `GET /auth/me` |

## Layout

```
lib/
  main.dart                 theme + MaterialApp.router
  Config/ApiConfig.dart     base URL, timeout, dart-defines
  Model/AppUser.dart        AppUser, AuthSession, Role
  Provider/                 Riverpod notifiers (session, signup)
  Routes/Routes.dart        go_router + auth guard
  Screen/                   Auth, Dashboard, Splash, NotFound
  Service/                  ApiService, UserService, ToastService
  Widget/                   shared auth widgets
```

State is `flutter_riverpod`; routing is `go_router` with a redirect guard tied
to the session provider.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `Can't reach the server` | Backend down, or a physical device using `localhost` — set `API_BASE_URL`. |
| Google button missing | `GOOGLE_SERVER_CLIENT_ID` not passed. |
| `Invalid Google token` | App and backend are using different client IDs, or the wrong type — both need the **Web** one. |
| OTP email never arrives | `RESEND_API_KEY` unset in the backend `.env`. |
| Signed out on every launch | Token expired (7 days) or the backend's `JWT_SECRET` changed. |

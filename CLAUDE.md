# Mjengo Hub — CLAUDE.md

Flutter client for **Mjengo Hub** (mjengohub.co.ke) — a Kenyan construction-industry
platform: infrastructure/private project tracking, road-safety & site-safety incident
reporting, news, mental-health support ("Mshikamano"), videos, and a
points/referral gamification layer. This app is a mobile/web companion to an
existing web platform; screens are being brought to visual/feature parity with it
(see recent commit "full visual and feature parity sync with web platform").

## Stack

- **Flutter** (SDK `^3.10.0`), targets Android/iOS/macOS/Windows/Linux/Web.
- **State management / DI**: `get` (GetX) — `GetxController`, `Obx`, `Get.put`,
  `Get.find`, `GetMaterialApp` + `GetPage` routing. No Provider/Riverpod/Bloc.
- **HTTP**: `GetConnect` (from `get`) wrapping `package:http`, plus raw `http` for
  multipart uploads. No `dio`/`retrofit`.
- **Auth**: Firebase Auth + `google_sign_in` for the Google OAuth handshake only;
  the actual session is a custom JWT issued by the Mjengo Hub REST API (see
  **Auth flows** below — this is not a "sign in with Firebase and trust
  `FirebaseAuth.currentUser`" app).
- **Fonts**: `google_fonts` — Montserrat used everywhere, applied both as the app
  text theme (`main.dart`) and per-widget via `GoogleFonts.montserrat(...)`.
- **Persistence**: `shared_preferences` for JWTs + cached user JSON. No local DB
  (no sqflite/hive/isar).
- **Media**: `image_picker` (uploads), `youtube_player_iframe` (videos),
  `url_launcher` (external links), `share_plus`.
- **Hosting**: Firebase Hosting (staging + PR preview channels) and GitHub Pages
  (production, `main` branch, custom domain via `CNAME`).

## Architecture & conventions

### Feature-folder layout

Each feature lives under `lib/<feature>/` with the same internal shape:

```
lib/<feature>/
  controllers/   GetxController subclasses (state + calls into services)
  models/        plain Dart model classes with fromJson/toJson
  services/      thin HTTP wrappers over BaseService/MjengoService
  screens/       full-page widgets, wired to a controller via Get.find
  widgets/       feature-local reusable widgets
```

Features: `auth`, `home`, `news`, `projects`, `incidents`, `mental_health`,
`videos`, `notifications`, `comments`, `point` (gamification: points/referrals/
copyright claims), `profile`, `hub`, `search`, `onboarding`, `splash`,
`navigation`, `shared` (cross-feature theme/widgets/services), `services`
(app-wide base HTTP + connectivity).

`lib/point/` is a misleading name — it holds **app core**, not just gamification:
`point/core/` has `DependencyInjection` and `FirebaseInitializer`, `point/routes/`
has `AppRoutes`. Gamification itself is `point/services/gamification_service.dart`
+ `point/models/points_models.dart`.

### Dependency injection

`main.dart` → `DependencyInjection.init()` (`lib/point/core/dependency_injection.dart`)
registers permanent singletons in order: `BaseService`, `MjengoService`,
`MjengoAuthController`, `UserController`, `HomeNewsController`,
`DiscoverController`, `VideosController`, `NotificationsController`. Feature
services that aren't permanent singletons (`ProjectsService`, `IncidentsService`,
`CommentsService`, `SiteService`, `GamificationService`, etc.) are just
instantiated directly (`final _service = ProjectsService();`) inside the widget/
controller that uses them — they're stateless wrappers, not DI-managed.

Each `init()` step is wrapped in its own try/catch and logs with an emoji prefix
(`🔧`, `✅`, `❌`, `🔐`, `👤`, `📰`, `🔍`, `🎬`, `🔔`) — a failure in one dependency
doesn't block the others from initializing. Follow this pattern for new
dependencies rather than a single top-level try/catch.

### Routing

`GetMaterialApp(getPages: AppRoutes.routes, initialRoute: AppRoutes.splash)` in
`main.dart`. Route table + path constants live in
`lib/point/routes/app_routes.dart`. Bottom-tab navigation (`MainNavigation` /
`lib/navigation/main_navigation.dart`) uses an `IndexedStack` with 6 tabs (Home,
Hub, Discover, Videos, Tools, Profile/Settings) driven by `MainNavController`
(defined at the bottom of `lib/home/home_screen.dart`, not its own file).

### HTTP layer — two parallel clients (know which one a feature uses)

There are **two** `GetConnect` wrappers pointed at the same API base
(`https://mjengohub.co.ke/api/v1/`), reading/writing the **same**
`shared_preferences` key (`mjengo_access_token`), so they share a session — but
they are separate classes with separate method names:

- **`BaseService`** (`lib/services/base_service.dart`) — `getRequest`,
  `postRequest`, `postRequestNoAuth`, `putRequest`, `patchRequest`,
  `deleteRequest`, `deleteWithBodyRequest`, `uploadFile`. Used by most domain
  services: news, projects, incidents, videos, mental health, comments, site
  settings. Centralizes status-code handling (401/429/413/5xx/4xx) into a
  normalized `{error, message}` body in `_handleResponse`.
- **`MjengoService`** (`lib/services/mjengo_service.dart`) — `apiGet`, `apiPost`,
  `apiPut`, `apiDelete`, `uploadMultipart`. Used by `MjengoAuthController` and
  `GamificationService` (points/referrals/copyright). Owns the token
  save/clear/cache helpers (`saveTokens`, `getAccessToken`, `saveUserCache`,
  `hasSession`, `logout`).

When adding a new service, match whichever client the sibling services in that
feature already use rather than introducing a third pattern. Also note
`UserController extends BaseService` directly (mixing controller + HTTP client)
— that's legacy (see **Auth flows**); don't copy that shape for new controllers.

Every domain service method independently try/catches and returns `[]` / `null`
/ `false` on any failure (network, non-200, parse) rather than throwing — screens
never need their own try/catch around a service call, just null/empty checks.

### API response envelope

Backend responses are `{"success": bool, "data": ...}` (list or object) on
success, and `{"error": "CODE", "message": "human text"}`-shaped on failure.
Read via `res.body['data']`, check `res.statusCode == 200 || 201`.

### Images

Always use `NetImage` (`lib/news/widgets/net_image.dart`) instead of raw
`Image.network` for any remote image — it handles null/empty URLs, load
failures, and mobile hotlink-protection (cPanel `Referer` header, skipped on
web where it's a forbidden CORS header) in one place. Pass `placeholderColor`
to match the surrounding card; default is light gray (`0xFFE5E7EB`).

### Theme / design tokens

`lib/shared/theme/app_theme.dart` — `AppColors` (ported from the website's
`main.css` custom properties, brand blue `#4A90E2`→`#357abd`) and `AppRadius`
(`pill = 999`, `card = 14`, `chip = 8`). Prefer these tokens over inlining new
hex colors for anything that should look consistent with the website.

### Logging

Services/controllers log with `print()` + emoji prefixes rather than a logging
package — there's no `logger`/`talker` dependency. Match this style rather than
introducing one.

## Auth flows

**There are two independent, non-interoperating auth stacks in this codebase.**
Only one is live in the current UI.

### Live: `MjengoAuthController` (custom JWT, REST-only)

`lib/auth/controllers/mjengo_auth_controller.dart` — everything the current
`LoginScreen` (`lib/auth/screens/login_screen.dart`) actually calls.

- **Email sign up** — `POST auth/register` → stores `access_token` +
  `refresh_token` (JWT pair, not a Firebase token) via
  `MjengoService.saveTokens`, caches the user JSON, navigates straight to
  `/home`. No OTP/email-verification step in this flow.
- **Email sign in** — `POST auth/login`.
- **Google sign-in** — uses `google_sign_in`'s `GoogleSignIn.instance` directly
  (NOT `firebase_auth`'s `GoogleAuthProvider`/`signInWithPopup`) to get a Google
  ID token, then `POST auth/google` with `{id_token}`; the *backend* verifies it
  against OAuth client id `729219361762-...apps.googleusercontent.com` (also
  registered as `google-signin-client_id` meta tag in `web/index.html`).
  `GoogleSignIn.initialize()` is fired eagerly in `onInit()` (not awaited) so the
  later `authenticate()` call inside the button's `onTap` is the *first* await in
  that gesture — required for the web popup to count as user-initiated.
- **Guest access** — `continueAsGuest()` just navigates to `/home` with no
  session; screens must check `isAuthenticated` for gated features.
- **Session restore** — on app start, if a cached token exists, load the cached
  user immediately (no network wait), mark `isInitialized`, then silently
  `GET auth/me` in the background; only a definitive 401/403 clears the session
  (network/5xx errors keep the cached session so a flaky connection doesn't log
  people out).
- **Sign out** — clears tokens + user cache, signs out of Google too (in case a
  Google session is active), routes to `/login`.
- **Password reset** — `POST auth/forgot-password` (always 200, to prevent email
  enumeration).
- **Avatar / cover upload** — `POST auth/me/avatar` / `auth/me/cover` via
  `MjengoService.uploadMultipart` (Cloudflare R2-backed on the server).

Firebase Core/Auth are still initialized at startup (`FirebaseInitializer` in
`lib/point/core/firebase_initializer.dart`, web forced to `Persistence.SESSION`
to survive incognito), but the live flow never calls
`FirebaseAuth.instance.signInWith*` — Firebase is present for `google_sign_in`
interop and because the legacy stack below still uses it.

### Legacy / unreachable from current UI: `UserController`

`lib/auth/controllers/user_controller.dart` (extends `BaseService` directly) —
a much older, more elaborate Firebase-Auth-based flow: email+password via
`FirebaseAuth`, phone OTP via `FirebaseAuth.verifyPhoneNumber`, full Firebase
Multi-Factor Auth (SMS) enrollment/challenge/unenroll, shop registration with
document uploads, and backend calls under a **different** path prefix
(`/users/auth/...` vs the live stack's `auth/...`). It's still registered in DI
and still backs two screens (`two_factor_screen.dart`, `verify_otp_screen.dart`),
but nothing in the live `MjengoAuthController` flow navigates to `/verify-otp`
or `/mfa-verify` (the latter isn't even a registered route in `AppRoutes`) —
these are effectively dead ends reachable only from within `UserController`'s
own flow. `lib/auth/screens/sign_up_screen.dart` also appears orphaned — the
`signup` route points at `LoginScreen(startOnSignUp: true)`, not `SignUpScreen`.

**Do not extend `UserController` for new work** — build against
`MjengoAuthController` unless a task specifically asks you to touch the legacy
Firebase MFA flow. If asked to remove dead code, confirm with the user first
since these screens are still routed and could be mid-migration rather than
abandoned.

## Backend API

Base URL: `https://mjengohub.co.ke/api/v1/` (both HTTP clients). A commented-out
LAN IP (`http://192.168.0.102:8080/api/v1/`) appears in both service files for
local backend testing — swap it in manually, don't leave it swapped in. Health
check lives outside the `/api/v1` prefix, at `/health`
(`BaseService.testConnection`).

Auth: `Authorization: Bearer <jwt>` header, attached automatically by both
clients' request modifiers from the cached `mjengo_access_token`.

| Feature | Method & path | Notes |
|---|---|---|
| Auth | `POST auth/register` | live signup |
| | `POST auth/login` | live login |
| | `POST auth/google` | `{id_token}`, backend-verified |
| | `GET auth/me` | profile fetch/refresh |
| | `PUT auth/me` | profile update |
| | `POST auth/forgot-password` | always 200 |
| | `POST auth/me/avatar` / `auth/me/cover` | multipart |
| News | `GET articles` (query) / `GET articles/{slug}` | featured + breaking use different query params on the same endpoint |
| | `GET categories` | |
| Projects | `GET projects` (query incl. `project_type=infrastructure\|private_development`) | client-side filtered too, see comment in `projects_service.dart` — "live API doesn't filter by this yet" |
| | `GET projects/{slug}` / `GET clients` | |
| | `POST projects/{id}/suggest-edit` / `suggest-progress` | |
| Incidents | `GET incidents` (query incl. `type=road_safety\|site_safety`) / `GET incidents/{slug}` | |
| | `POST incidents` | create (used by "Share Barabara" / site safety report flows) |
| | `POST incidents/{id}/comment` / `suggest-edit` | |
| | `POST incidents/{id}/media` | image upload via `uploadFile`, not multipart helper |
| Mental health | `GET mental-health/posts`, `POST mental-health/posts`, `GET mental-health/videos` | "Mshikamano" |
| Videos | `GET youtube/videos`, `GET youtube/playlists`, `GET youtube/categories` | |
| Notifications | `GET notifications/unread-count`, `PUT notifications/{id}/read`, `PUT notifications/read-all`, `DELETE notifications/{id}`, `DELETE notifications` | |
| Comments (polymorphic) | `GET/POST {prefix}/{id}/comments` | `prefix` ∈ `articles`, `projects`, `incidents`, `mental-health/posts` — see `CommentResource` enum |
| | `POST comments/{id}/vote`, `POST comments/{id}/report` | |
| Site | `GET site/settings`, `GET site/social-links` | store URLs, admin-managed social links (home screen falls back to hardcoded links if this returns empty) |
| Gamification | `GET points/summary`, `GET points/log`, `GET referrals/me`, `POST referrals/redeem`, `POST copyright-claim` (JSON or multipart with `proof`) | **flagged in source as possibly not deployed yet** — "these follow the same REST conventions... some of these endpoints don't exist on the backend yet;" every call degrades to a safe default rather than surfacing an error |
| Legacy (`UserController` only) | `POST /users/auth/signup/google`, `/users/auth/signin/phone`, `/users/auth/signup/phone`, `PUT /users/auth/user/{uid}`, `/users/auth/user/{uid}/delete`, `/users/auth/user/{uid}/shop-status`, `/users/auth/user/{uid}/register-shop`, `/users/upload/document`, `/users/upload/business-photos` | different prefix from the live stack; treat as legacy, see **Auth flows** |

No unified `/search` endpoint — `SearchScreen` fans out to the existing
per-feature endpoints (articles/projects/incidents) client-side rather than
calling a single backend search route.

## Conventions checklist for new work

- New screen → new `lib/<feature>/screens/*.dart`; register it in
  `lib/point/routes/app_routes.dart` with a named constant, don't hardcode route
  strings at call sites except for the handful of existing inline ones
  (`'/share-barabara'`, `'/mfa-verify'` etc. — inconsistent, but don't add more).
- New backend call → add a method to the feature's `*_service.dart` (or extend
  an existing one), following the try/catch-and-return-empty pattern; don't call
  `BaseService`/`MjengoService` directly from a screen or controller.
- New remote image → `NetImage`, not `Image.network`.
- New colors/radii that should match the website → `AppColors`/`AppRadius` in
  `shared/theme/app_theme.dart`, not inline hex.
- Text styling → `GoogleFonts.montserrat(...)`, matching the weight/size scale
  already used in nearby widgets in that screen.
- GetX reactive state → `Rx<T>`/`.obs` fields with private backing + public
  getters (see `MjengoAuthController`), wrap consuming widgets in `Obx(() => ...)`.

## Known gaps (don't be surprised by these)

- `test/widget_test.dart` is still the default `flutter create` counter-app
  smoke test — it references `MyApp` but asserts counter behavior the app
  doesn't have, so it fails as-is. There is no real test suite; don't assume
  `flutter test` passing means anything about app correctness.
- Gamification endpoints (points/referrals/copyright-claim) may 404 on the live
  backend — this is expected and handled, not a regression to chase.
- `/mfa-verify` is referenced (`Get.toNamed`) but not registered in
  `AppRoutes.routes` — a live crash risk only inside the legacy MFA flow.
- Every HTTP call logs full request/response (headers, body) via `print()` —
  expect verbose console output; this is intentional for now, not a stray debug
  leftover to "clean up" unless asked.

## Deploy

- `staging` branch and PRs → Firebase Hosting preview/staging channel
  (`.github/workflows/firebase-hosting-pull-request.yml`, project
  `mjengohub-staging-176d6`, `flutter build web --release`).
- `main` branch → GitHub Pages (`.github/workflows/deploy.yml`), published to
  `gh-pages`, custom domain `mjengohub.co.ke` via `CNAME`.
- Both workflows run `flutter build web --release` from scratch — no separate
  lint/test gate in CI currently.

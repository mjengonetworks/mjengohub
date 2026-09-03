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
`service_catalog` (services catalogue), `reports` (infrastructure reports),
`reviews`,
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
`MjengoAuthController`, `HomeNewsController`,
`DiscoverController`, `VideosController`, `NotificationsController`. Feature
services that aren't permanent singletons (`ProjectsService`, `IncidentsService`,
`CommentsService`, `SiteService`, `GamificationService`, `ServiceCatalogService`,
`ReportsService`, `ReviewsService`, `SearchService`, etc.) are just
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
feature already use rather than introducing a third pattern. Note also that
`MjengoService` now owns `refreshAccessToken()`, and that its 401 response
modifier clears only the *access* token (the refresh token is kept so a refresh
is still possible).

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
  ID token, then `POST auth/google` with `{id_token}`. **This endpoint does not
  exist in api.py** (verified against the website repo: the only Google route is
  a session-based redirect at `application.py` `/auth/google`), so the call 404s
  and the controller surfaces an explicit "not available yet" message. The
  intended contract is that the *backend* verifies the ID token against an
  OAuth client id. Note the client ids currently disagree three ways: the app
  and `web/index.html` use `729219361762-...`, the website backend uses
  `185210499275-...`, and `android/app/google-services.json` carries
  `457461415783-...`. These must be reconciled to one client before Google
  sign-in can work end to end.
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
- **Password reset** — `POST auth/forgot-password`. **Not implemented in api.py**
  (the backend has no password-reset route at all), so this 404s today and the
  controller says so explicitly instead of promising an email. When it is added
  it should always return 200, to prevent email enumeration.
- **Avatar / cover upload** — `POST auth/me/avatar` / `auth/me/cover` via
  `MjengoService.uploadMultipart` (Cloudflare R2-backed on the server).

Firebase Core/Auth are still initialized at startup (`FirebaseInitializer` in
`lib/point/core/firebase_initializer.dart`, web forced to `Persistence.SESSION`
to survive incognito), but the live flow never calls
`FirebaseAuth.instance.signInWith*` — Firebase is present for `google_sign_in`
interop and because the legacy stack below still uses it.

### Removed: the legacy `UserController` stack

There used to be a second, Firebase-Auth-based auth stack
(`lib/auth/controllers/user_controller.dart` plus `sign_up_screen.dart`,
`two_factor_screen.dart`, `verify_otp_screen.dart`) with phone OTP, Firebase
Multi-Factor Auth, shop registration, and backend calls under a different
`/users/auth/...` prefix. **It has been deleted**, along with its DI
registration, its `/verify-otp` and `/mfa-enroll` routes, and the dead
marketplace/2FA fields it required on `UserModel` (`ShopDetails`,
`ShopDocuments`, `UserValidator`, `userType`, `trustBadges`, `twoFAEnabled`, …).
None of it was reachable from the live UI and none of it matched api.py.

`MjengoAuthController` is now the only auth stack. Firebase Core/Auth are still
initialized at startup (`FirebaseInitializer`) purely for `google_sign_in`
interop.

`UserModel` now mirrors api.py's `_user_dict` exactly and
`MjengoAuthController._parseUser` just delegates to `UserModel.fromJson`.

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
| | `POST auth/google` | **missing from api.py** — 404s; see **Auth flows** |
| | `GET auth/me` | profile fetch/refresh |
| | `PUT auth/me` | profile update |
| | `POST auth/forgot-password` | **missing from api.py** — 404s; see **Auth flows** |
| | `POST auth/refresh` | refresh-token -> new access token; `MjengoService.refreshAccessToken()` bypasses `httpClient` to send the *refresh* token |
| | `POST auth/me/avatar` / `auth/me/cover` | multipart |
| News | `GET articles` (query) / `GET articles/{slug}` | featured + breaking use different query params on the same endpoint |
| | `GET categories` | |
| Projects | `GET projects` (query incl. `project_type=infrastructure\|private_development`) | filtered server-side; `projects_service.dart` keeps a redundant client-side filter as a safety net |
| | `GET projects/{slug}` / `GET clients` | |
| | `POST projects/{id}/suggest-edit` / `suggest-progress` | |
| Incidents | `GET incidents` (query incl. `type=road_safety\|site_safety`) / `GET incidents/{slug}` | |
| | `POST incidents` | create (used by "Share Barabara" / site safety report flows) |
| | `POST incidents/{id}/comments` / `suggest-edit` | plural — the singular form was a bug, fixed |
| | `POST incidents/{id}/media` | image upload via `uploadFile`, not multipart helper |
| Mental health | `GET mental-health/posts`, `POST mental-health/posts`, `GET mental-health/videos` | "Mshikamano" |
| Videos | `GET youtube/videos`, `GET youtube/playlists`, `GET youtube/categories` | |
| Notifications | `GET notifications` (paginated list), `GET notifications/unread-count`, `PUT notifications/{id}/read`, `PUT notifications/read-all`, `DELETE notifications/{id}`, `DELETE notifications` | |
| Comments (polymorphic) | `GET/POST {prefix}/{id}/comments` | `prefix` ∈ `articles`, `projects`, `incidents`, `mental-health/posts` — see `CommentResource` enum |
| | `POST comments/{id}/vote` | no `/report` route exists under `/api/v1` (only a session-based one on the website), so `CommentsService` has no `report()` |
| Site | `GET site/settings`, `GET site/social-links` | store URLs, admin-managed social links (home screen falls back to hardcoded links if this returns empty) |
| | `GET site/figures`, `GET site/alerts` | headline counters + scheduled site banners (`SiteService`) |
| | `POST newsletter/subscribe` | 409 = already subscribed |
| | `POST advertise` | advertising enquiry; returns a `reference` |
| Services | `GET services`, `GET services/{slug}`, `POST services/{slug}/request` | `lib/service_catalog/` (folder is not `services/` because that name is the HTTP layer) |
| Reports | `GET reports`, `GET reports/{id}`, `POST reports`, `POST reports/{id}/vote` | citizen infrastructure reports, `lib/reports/`; voting is IP-scoped and toggles |
| Reviews | `GET reviews`, `POST reviews` | `lib/reviews/`; POST lands unapproved, so it won't appear in GET immediately |
| Search | `GET search` | articles + services + reports only (min 2 chars) |
| Projects (extra) | `GET projects/{id}/milestones`, `GET projects/{id}/media`, `POST projects/{id}/rate` | rating is 1–10, not 1–5 |
| Clients | `GET clients/{slug}` | adds `description` + `project_count` |
| Mental health (extra) | `POST mental-health/videos` | needs `title` + `uploader_name` and one of `youtube_id`/`file_path`; lands unapproved |
| Calculators | `POST calculators/concrete\|plaster\|budget\|units`, `GET calculators/units/available` | **not wired** — the Tools screen does this maths locally so it works offline |
| Gamification | `GET points/summary`, `GET points/log`, `GET referrals/me`, `POST referrals/redeem`, `POST copyright-claim` (JSON or multipart with `proof`) | all confirmed live in api.py; calls still degrade to safe defaults on failure |

`GET /search` **does** exist, but only covers articles, services and
infrastructure reports. `SearchScreen` therefore merges two sources: the
unified route (via `SearchService`) plus per-feature fan-out to `/projects`
and `/incidents`, which `/search` deliberately doesn't touch.

## Conventions checklist for new work

- New screen → new `lib/<feature>/screens/*.dart`; register it in
  `lib/point/routes/app_routes.dart` with a named constant, don't hardcode route
  strings at call sites except for the handful of existing inline ones
  (`'/share-barabara'` etc. — inconsistent, but don't add more).
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
- New submission form → reuse `lib/shared/widgets/form_fields.dart`
  (`AppTextField`, `AppDropdown`, `FieldLabel`, `AppSubmitButton`,
  `requiredField`, `emailField`) rather than re-deriving the input decoration.
- Any screen that also ships on web → wrap the scroll body in `ContentWidth`
  from `lib/shared/widgets/responsive.dart` so it doesn't stretch to 1900px;
  `Breakpoints`/`context.isDesktop`/`context.gridColumns` live there too.

## Known gaps (don't be surprised by these)

- `test/widget_test.dart` is still the default `flutter create` counter-app
  smoke test — it references `MyApp` but asserts counter behavior the app
  doesn't have, so it fails as-is. There is no real test suite; don't assume
  `flutter test` passing means anything about app correctness.
- **Google sign-in and password reset are broken end to end** because
  `POST auth/google` and `POST auth/forgot-password` don't exist in api.py.
  Both now fail with an explicit message instead of a generic error. Fixing
  them needs backend routes, plus reconciling the three different Google OAuth
  client ids (see **Auth flows**).
- Several screens still use raw `Image.network` instead of `NetImage`
  (`home_screen`, `home_extra_sections`, `incidents_list_screen`,
  `incident_detail_screen`, `mshikamano_screen`, `projects_screen`,
  `project_detail_screen`, `account_screen`, `profile_screen`,
  `videos_screen`). On mobile these can fail cPanel hotlink protection, so
  images silently don't load — worth converting.
- The website has features with **no** `/api/v1` equivalent, so the app can't
  reach parity on them: events, merch/cart/checkout, donations, financiers,
  user pages (`my_pages`/`page_profile`), article/project/event submission,
  and banner ads. Don't add app screens for these until the backend exposes
  JSON routes.
- Jobs and Tenders are **not** separate models/endpoints — they're plain
  Article categories (`GET articles?category=jobs` / `category=tenders`),
  same as any other news category. `HubScreen` has "Jobs"/"Tenders" tiles
  that preset that filter on `DiscoverController` and switch to the News tab
  rather than pushing a route; don't build standalone Jobs/Tenders
  screens/services/models.
- The Flutter SDK is not installed on the current dev machine, so
  `flutter analyze` / `flutter build` can only be validated in CI.
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

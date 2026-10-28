# Mjengo Hub Flutter production parity audit

Audit date: 2026-10-29 (Africa/Nairobi)

Scope: tracked Flutter source, tests and project documentation in this repository, compared with the live production site at https://mjengohub.co.ke. Existing untracked browser captures were preserved and were not treated as source code.

## Repository baseline

- Branch at audit start: `main`, behind `origin/main` by 2 commits.
- Audit branch: `feature/flutter-production-parity-audit`.
- Existing user change preserved: `pubspec.yaml` version `1.0.0+3` -> `1.0.0+4`.
- Existing untracked capture folders and PNGs preserved.
- App shell: `GetMaterialApp` + GetX named routes, `MainNavigation` with an `IndexedStack`, native Material screens.
- State/integration: GetX controllers, Firebase Auth/Messaging/Core, `http`-based services, Shared Preferences, `connectivity_plus`, `app_links`, `share_plus`, image/media and map packages.
- Design system: `lib/shared/theme/app_theme.dart`, Montserrat via `google_fonts`, light/dark theme wiring in `lib/main.dart`, reusable navigation/header/cards/image widgets.
- Backend/media conventions: API services under feature folders; relative media paths resolve through `media.mjengohub.co.ke`; canonical website URLs are used by article sharing/deep-link helpers.

## Production information architecture observed

The production homepage currently exposes Home, News and Articles, Infrastructure Tracker, Private Projects/Developments, Africa & World, Built History, Site Safety, Media & Feed, Merch, global search, Mjengo Hub AI, account/sign-in, community contribution, notifications/alerts, partners and legal/support content. The homepage hierarchy includes latest news, category browsing, latest infrastructure/private projects, featured analysis, media/video, Africa & World, Built History, safety, project category browse, community and partners.

Site Safety production separates incident reports from safety articles/tips and provides search/filter controls, severity/type views, map/grid/split presentation, emergency contacts and submit/report entry points. Unknown casualty/injury values are not to be represented as confirmed zeroes.

Project Sources, Project Overview and AI workflows are treated as pending unless the production API response confirms them. Repository tracker notes also mark Feed reporting/moderation and several AI/feed changes as approval or backend dependent.

## Website-to-Flutter parity matrix

| Production area / capability | Flutter implementation | Status | Evidence / next action |
|---|---|---|---|
| Home and editorial hierarchy | `HomeScreen`, `home_extra_sections.dart`, `HomeNewsController` | Partial / needs visual QA | Broad section coverage exists, including hero, latest news, projects, private projects, media, safety, Africa & World, Built History, community and partners. Compare current production ordering and mobile spacing with representative screenshots. |
| News & Articles listing | `DiscoverScreen`, `news_api_service.dart`, article list widgets | Implemented | Verify current category/geography taxonomy, ranking, filters, pagination and canonical links against production responses. |
| Article detail/editorial rendering | `ArticleDetailScreen`, content block models, `net_image.dart`, sharing widgets | Implemented with parity checks pending | Rich text, captions/credits, related content, maps and tagged projects have support; backend fields are optional. Confirm current production related-content rules and visual hierarchy. |
| Infrastructure Tracker | `ProjectsScreen`, `ProjectDetailScreen`, `ProjectsService`, tracker widgets | Implemented / needs production contract verification | Unknown cost/location/progress handling and long Project Overview need regression coverage. Project Sources remain pending until confirmed in production. |
| Private Projects | `PrivateProjectsScreen`, project models/services | Implemented | Align naming and category labels with live “Private Projects/Developments” navigation; preserve shared project taxonomy. |
| Africa & World | `AfricaWorldScreen`, project filters | Implemented | Confirm multi-location and country taxonomy IDs from backend; avoid Flutter-only geography lists. |
| Built History | `BuiltHistoryScreen`, project filters | Implemented | Confirm production archive scope and completion-date semantics; current list sorting uses unknown cost as a sort fallback only, not display data. |
| Site Safety alerts/articles/reports distinction | `IncidentsListScreen`, `IncidentDetailScreen`, `ReportsScreen` and report models | Partial | Incident records and reports exist, but audit route semantics and production content types before merging any unverified unified model. Keep nullable casualties/injuries. |
| Site Safety filtering/map | incident controllers/screens, map dependencies | Implemented / needs visual QA | Production exposes year, region/country, county, type, severity and grid/map/split views. Verify Flutter preserves filters and avoids mixing scopes. |
| Safety submission | `ReportIncidentScreen`, `IncidentsService` | Safe fix required | Form currently defaulted blank casualties/injuries to `0`; change to nullable omitted fields so unknown stays unknown. |
| Media & Feed | native `FeedScreen`, composer, discussions, voting; `VideosScreen` | Partial / backend and approval dependent | Native Feed read/publish/discussions/voting are present in pushed history; reporting/moderation and some tabs remain explicitly pending in `FLUTTER_TASK_TRACKER.md`. Do not advertise unsupported actions. |
| Search | `SearchScreen`, `SearchService`, AI search/chat models | Implemented / needs production verification | Confirm articles, projects and safety content coverage, debounce/cancellation and query/filter restoration. AI chat sign-in and server workflow remain authoritative. |
| Mjengo Hub AI | search AI/chat services and widgets | Partial / approval dependent | Preserve server prompts/provider routing; do not add client credentials or duplicate prompt logic. |
| Authentication/account | Firebase auth controller, login/reset/profile/account screens | Implemented | Verify return-to-content/action routing, session persistence and permission-aware actions. |
| Notifications | `NotificationsScreen`, controller/service, Firebase Messaging | Implemented / needs device verification | Verify permission flow, read/unread, duplicate prevention and deep-link destinations on Android/iOS. |
| Global navigation | `MainNavigation`, `AppHeader`, `AppRoutes` | Implemented / naming alignment pending | Native six-tab shell is appropriate; current bottom labels are Home, News, Tracker, Feed, Private, Profile. Secondary routes cover safety, search, media, notifications, account and legal/support. Check current website labels and deep-link back-stack behavior. |
| Sharing/deep links | `share_plus`, `app_links`, canonical URL helpers | Implemented / needs device verification | Preserve canonical website URLs and test article/project/incident/notification links with and without app installation. |
| Images/media | `net_image`, media pipeline, caching/display widgets | Implemented / visual QA pending | Verify portrait aspect ratios, loading/error placeholders, full-screen detail behavior and Cloudflare/R2-backed paths. |
| Light/dark themes/accessibility | `AppColors`, `AppColorsDark`, `ThemeController`, shared widgets | Partial | Theme wiring exists, but comments note many screens still hardcode colors. Audit high-traffic screens for dark contrast, text scaling, semantics and 44pt touch targets. |
| Performance/offline | connectivity controller, lazy lists/pagination in feature controllers | Partial | Inspect initial request fan-out, image sizes, cache staleness and rebuilds after visual parity baseline. |
| Admin-only workflows | No public admin shell identified in app routes | Correctly not recreated | Keep admin workflows out of public mobile app unless owner explicitly requires role-aware mobile administration and backend readiness. |

## Phase plan and acceptance gates

1. Audit and matrix: this document; baseline checks and production route evidence recorded.
2. Shared foundations: consolidate semantic tokens and shared content-card/image/state widgets; add theme and layout tests.
3. Public content: homepage, articles, projects and safety parity using live API contracts; add model/widget/navigation tests per screen.
4. Platform functionality: search, filters, sharing/deep links, auth return routing, Feed and notifications, only where backend readiness is confirmed.
5. Performance/accessibility: pagination, cache freshness, rebuild profiling, text scaling, semantics, light/dark verification.
6. Release candidate: `flutter analyze`, unit/widget/navigation/API/deep-link tests, Android/iOS build checks and device/emulator screenshots. No release or deployment without owner approval.

## Current blockers and pending items

- The working tree contains large untracked browser-capture artifacts; they are user-owned and were left untouched.
- Flutter tooling attempted a tag fetch during baseline analysis and failed with `No space left on device`; test/analyze results are therefore not yet valid acceptance evidence.
- Production attribution of backend commits and release readiness is not available from this repository alone.
- Project Sources, unreleased Project Overview/AI workflows, Feed reporting/moderation and any API/schema changes remain pending until production contracts and owner approval are confirmed.

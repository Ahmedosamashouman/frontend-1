# AGENTS.md — UpHeal

Flutter 3.41+ / Dart 3.11+ mental-health gamification app.

## Quick commands

```bash
flutter pub get                                    # install dependencies
flutter analyze                                    # static analysis (lints)
flutter test                                       # run all tests
flutter test test/models/                          # run a single test directory
flutter pub run build_runner build --delete-conflicting-outputs  # regenerate Hive adapters
flutter run --dart-define=SUPABASE_URL=...         # run with Supabase keys
flutter run --dart-define=SUPABASE_URL=... \
            --dart-define=SUPABASE_ANON_KEY=...    # with auth
```

- Lint config: `analysis_options.yaml` → uses `package:flutter_lints/flutter.yaml`.
- There is **no CI** or Makefile.

## Architecture

### State management
- **Provider + ChangeNotifier** — all models extend `ChangeNotifier`, call `notifyListeners()`.
- Providers are registered in `lib/main.dart` → `MultiProvider` inside `UpHealApp`.
- Use `context.read<T>()` for one-time reads, `context.watch<T>()` / `Consumer<T>` for reactive rebuilds.

### Navigation
- **go_router** with `StatefulShellRoute.indexedStack` — 4 bottom tabs: Home, Challenges, Community, Profile.
- All route definitions: `lib/navigation/app_router.dart` and `lib/navigation/app_routes.dart`.
- Auth gating: `_redirect` in `AppRouter` checks `AuthModel.isAuthenticated`; public routes listed in `publicRoutePrefixes`.
- Global keys in `lib/navigation/app_navigation_keys.dart`: `rootScaffoldMessengerKey`, `appNavigatorKey`.

### Backend
- **Supabase** (not Firebase) — initialized lazily by `CommunitySupabase.initializeIfConfigured()` in `main()`.
- Supabase keys come from `--dart-define` flags or a local `.vscode/supabase.keys.json` file (non-web debug only).
- Config chain: `CommunitySupabaseEnv` → `SupabaseConfig` → `CommunitySupabase`.
- Supabase auth JWT is exposed via `SupabaseService.idToken` for API requests to the UpHeal backend.
- There is also a Python backend at `UPHEAL_API_URL` (default `http://172.16.26.61:8000` via `--dart-define`).

### Local storage
- **Hive** (offline-first cache for screen-time data, focus sessions, block rules).
- Hive adapters are code-generated — run `build_runner build` after changing models in `lib/models/hive/`.
- Adapters registered in `main()`: `AppUsageCache`, `FocusSessionHistory`, `BlockRule`, `DailyUsage`.
- `UsageCacheService` is the central cache layer; `ScreenTimeService` falls back to it when permissions are denied.

### Key directories
| Directory | Purpose |
|---|---|
| `lib/screens/` | Full-screen pages (39 files) |
| `lib/models/` | State models (`ChangeNotifier`) |
| `lib/services/` | Business logic & API services (36 files) |
| `lib/features/` | Feature islands: community, onboarding, steps, ui_system |
| `lib/design_system/` | Design tokens, responsive utils, shared components |
| `lib/navigation/` | go_router setup, route classes, shell scaffold |
| `lib/constants/` | `AppColors`, theme builder |
| `lib/gamification/` | XP config, gamification models |
| `lib/avatar/` | Avatar feature (provider, UI, services) |
| `lib/widgets/` | Reusable UI widgets |
| `supabase/` | Supabase migrations, functions, config |

## Conventions

### Colors & theming
- Use `AppColors` class (e.g., `AppColors.purple`, `AppColors.teal`, `AppColors.surface`). Never hardcode hex colors.
- Check `Theme.of(context).brightness` for dark/light branching.
- The theme is Material 3; custom tokens in `lib/design_system/tokens/`.

### Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private members: `_prefix`

### Error handling
- Wrap async ops in try-catch; check `mounted` before `setState` in async callbacks.
- Use `debugPrint` for logging (not `print`).
- Service init failures in `main()` are caught and logged — the app continues degraded.

## Gotchas

- **`.cursorrules` is outdated** — it references "MindQuest", Firebase, and `RootNav`. The app is named UpHeal, uses Supabase, and routes via go_router. Prefer this file.
- **`workmanager` is disabled** in `pubspec.yaml` due to compatibility issues.
- **SMTP credentials** in `lib/config.dart` are empty placeholders — email features won't work until they're filled.
- **Code generation is required** after editing any model in `lib/models/hive/` — run `flutter pub run build_runner build --delete-conflicting-outputs`.
- **Supabase is optional** — the app starts without it (community features simply don't load).
- **`config.dart` (root of lib/) vs `config/` directory** — two separate things. The file holds SMTP, pepper, Supabase, and API URL constants. The directory contains community Supabase env loading.
- **Async initialization** — many services start asynchronously in `main()` after `runApp`. Their errors are non-fatal; the app runs with degraded features.

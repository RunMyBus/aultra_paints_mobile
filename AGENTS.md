# Repository Guidelines

## Project Structure & Module Organization
- `lib/` contains all Dart application code. Key areas include `screens/` (UI flows), `services/` (API/config/view models), `providers/` (state), `model/` (request/response objects), and `utility/` (shared helpers).
- `test/` contains Flutter tests (currently basic widget coverage).
- `assets/` stores images, fonts, and certificate files referenced in `pubspec.yaml`.
- Platform runners and native config live in `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/`.

## Build, Test, and Development Commands
- `flutter pub get`: install/update Dart and Flutter dependencies.
- `flutter run`: run locally on connected emulator/device.
- `flutter analyze`: run static analysis using `analysis_options.yaml` and `flutter_lints`.
- `flutter test`: execute unit/widget tests in `test/`.
- `flutter build apk --release` / `flutter build ios --release`: produce release artifacts for Android/iOS.

## Coding Style & Naming Conventions
- Follow Flutter defaults with 2-space indentation and formatter output (`dart format .`).
- Respect lints from `package:flutter_lints/flutter.yaml` (configured via `analysis_options.yaml`).
- Use `UpperCamelCase` for classes/widgets, `lowerCamelCase` for methods/variables, and descriptive screen/view model names (for example `ProductsCatalogScreen`, `LoginViewModel`).
- Keep files grouped by feature under `lib/screens/<feature>/` and shared logic under `services/`, `providers/`, or `utility/`.

## Testing Guidelines
- Use `flutter_test` for widget and unit tests.
- Name test files with `_test.dart` suffix and mirror source paths where possible (example: `test/screens/login_page_test.dart`).
- Run `flutter test` before opening a PR; run `flutter analyze` in the same check.
- Add tests for new view-model logic, validation helpers, and route-critical UI behavior.

## Commit & Pull Request Guidelines
- Recent commits are short, feature-focused summaries, often lowercase and starting with `with ...` (for example: `with cart checkout handling`). Keep messages concise and specific to one change set.
- PRs should include: what changed, why, impacted platforms (`android`/`ios`/others), test evidence (`flutter test`, `flutter analyze`), and screenshots/videos for UI updates.
- Link related issue/ticket IDs when available and call out any config or certificate changes explicitly.

## Security & Configuration Notes
- Treat files in `KEYSTORE/` and `assets/certificate/` as sensitive. Do not rotate, rename, or replace secrets/certs without owner approval.
- Avoid committing environment-specific local artifacts; keep runtime configuration centralized in service/config files.

## Visual Refresh — Theme & Primitives (as of 2026-04-26)
The app's visual layer was rebuilt to align with the Aultra Paints portal palette. Material 3 + Plus Jakarta Sans + a small primitive widget library are now the single source of truth for color, type, spacing, and surface shape. Every screen consumes these tokens — do not introduce hardcoded `Color(0xFF…)` literals or font-family strings outside `lib/theme/`.

### `lib/theme/` (design tokens)
- `app_colors.dart` — `AppColors` (15 const colors, brand seed `#10278C`) and an `AppSemantics` `ThemeExtension` for success/error/info/scanner tone pairs. Read semantic tokens via `Theme.of(context).extension<AppSemantics>()` or the `context.semantic` extension.
- `app_text_styles.dart` — `AppTextStyles.textTheme()` returns a `TextTheme` anchored to the bundled Plus Jakarta Sans variable font (`PlusJakartaSans` family). The `google_fonts` package is **not** used at runtime; do not import it.
- `app_spacing.dart`, `app_radius.dart`, `app_shadows.dart`, `app_gradients.dart` — spacing/radius/shadow/gradient constants. `AppGradients.signature` (3-stop) and `signatureCompact` (2-stop) are reserved for hero/identity surfaces (drawer header, balance hero, featured offer).
- `app_theme.dart` — `AppTheme.light()` builds the global `ThemeData`; light-only for v1. Wired into `MaterialApp.theme` in `lib/main.dart`. `themeMode: ThemeMode.light`.

### `lib/widgets/primitives/` (theme-driven widgets)
- `AppAppBar` (+ `AppAppBarAction`), `AppCard` (with `emphasis: AppCardEmphasis.{normal,hover,featured,form}`), `AppButton.filled/outlined/text` (supports `loading`/`fullWidth`/`icon`), `AppChip`, `AppBadge` (`AppBadgeTone.{info,success,error,neutral}`), `AppTextField` (supports `maxLength` + `inputFormatters`), `AppListRow`, `AppDialog` (`showAppDialog` + `AppDialogAction`), `AppSnack.show` (`AppSnackTone.{neutral,success,error,info}`), `AppLoader` (re-skins `flutter_easyloading`), `AppEmptyState`.
- Every primitive is paired with a widget test in `test/widgets/primitives/`.
- `_gallery.dart` exposes a debug-only route `/_gallery` (mounted in `lib/main.dart` under `kDebugMode`) that renders every primitive for QA.

### Removed during the refresh
- `lib/utility/Colors.dart`, `lib/utility/Fonts.dart` — deleted; their values moved into the theme tokens.
- `font_awesome_flutter` — removed from `pubspec.yaml`. Use Material outlined icons (`Icons.*_outlined`).
- Yellow→pink gradient (formerly on AppBar/drawer/SplashPage etc.) — replaced by solid navy or `AppGradients.signature*` for hero surfaces only.
- `AppTheme.dark` — dark mode is out of scope for v1.

### Conventions for new code
- Read colors via `Theme.of(context).colorScheme.*` or `AppColors.*`. Do not write raw hex except inside `lib/theme/`.
- Read text styles via `Theme.of(context).textTheme.*` or `AppTextStyles.*`.
- Prefer primitives over ad-hoc `Container(decoration: …)` shells. If you need a new primitive, add it under `lib/widgets/primitives/` with a test and an entry in `_gallery.dart`.
- Layout shell: `lib/screens/LayOut/LayOutPage.dart` wraps post-login screens with `AppAppBar` (hamburger + QR icon) and a drawer with grouped sections (Quick Actions / Browse / Settings + Log out). Don't add a Scaffold AppBar to a screen wrapped by `LayoutPage`.
- Splash cert check (`lib/screens/splash/SplashPage.dart`) routes through `onNavigate()` on any error so a missing network does not trap the user on splash.

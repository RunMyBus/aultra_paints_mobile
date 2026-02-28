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

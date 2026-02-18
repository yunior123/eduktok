# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Eduktok** is an iOS language learning app (similar to Rosetta Stone), live on the App Store (Canada & USA). Built with Swift/SwiftUI, Firebase (Firestore + Storage), and StoreKit for in-app purchases. The internal code name is "OrignaL" — the main struct is `OrignaLApp`, and theme constants use the `OrignaLTheme` prefix.

## Build & Test Commands

This is an Xcode project. Build and run via Xcode (open `eduktok.xcodeproj`) or using `xcodebuild`:

```bash
# Build
xcodebuild -scheme eduktok -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run unit tests
xcodebuild -scheme eduktok -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:eduktokTests

# Run UI tests (requires credentials)
UITEST_REAL_EMAIL="test@example.com" UITEST_REAL_PASSWORD="password" \
  xcodebuild -scheme eduktok -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:eduktokUITests
```

UI tests use environment variables `UITEST_REAL_EMAIL` and `UITEST_REAL_PASSWORD` for a real Firebase account. The `UITestLaunchFlags` enum in `Utils.swift` checks for `-ui-testing` and `-ui-testing-real` launch arguments, which show test-only helper buttons in `LessonView`.

## Architecture

### Layer Structure
- `eduktok/db/` — Firebase layer: `Db` class (Firestore CRUD) and `fs.swift` (Firebase Storage upload/delete)
- `eduktok/models/` — Data models (plain Swift structs/classes)
- `eduktok/view_models/` — `ObservableObject` ViewModels
- `eduktok/views/` — SwiftUI Views organized by feature (`auth_views/`, `languages/`, `settings/`, `storekitpro/`)
- `eduktok/utils/Utils.swift` — `OrignaLTheme` design system, `UITestLaunchFlags`, utility functions
- `eduktok/trash/` — Deprecated/disabled code, ignore it

### Entry Point & Navigation
`eduktokApp.swift` → `AuthView` → (on sign-in) → `HomeView` → `TabView` with:
- `LanguageView` (language picker → unit grid → `LessonView`)
- `StoreKitProViewMP` (only for non-premium users)
- `SettingsView`

### Lesson System
`LessonModel` is a protocol (`id`, `type`, `lessonNumber`, `audioUrlDict`). Three concrete types:
- `GListeningModel` — matching exercise: `foreModels` (question cards) + `backModels` (answer cards)
- `GListeningFourModel` — 4-option multiple choice listening
- `GSpeakingModel` — speech recognition practice with `SpeechRecognizer`

`LessonView` fetches all lessons for a unit via `Db.fetchLessonsForUnit(unitNumber:)`, parses them by `type` field into the correct model, and dispatches to `GListeningView`, `GListeningFourView`, or `GSpeakingView`.

### Data Layer
`Db` class is instantiated fresh per use (not a singleton). Firebase collections:
- `unitsNew` — ordered by `unitNumber`
- `lessonsNew` — filtered by `unitNumber`, ordered by `lessonNumber`
- `users` — keyed by email; progress structure: `languageProgress[language][unitId][lessonId] = Bool`
- `purchaseRecords` — StoreKit purchase records

`HomeViewModel` sets up a Firestore snapshot listener on the user document so `UserModel` stays live throughout the session.

### Image Caching
`CachedAsyncImage` in `views/languages/CacheAsyncImage.swift` provides two-tier caching (NSCache memory + disk at `~/Library/Caches/ImageCache/`). Use `CachedAsyncImage(url:placeholder:)` for all remote images.

### Admin Features
When `userModel.role == "admin"`, lesson views show image edit buttons that upload replacements to Firebase Storage via `uploadImageToFirebaseC` and update Firestore. This is only visible to admin-role users.

### Design System
All colors and gradients are in `OrignaLTheme` (Utils.swift): `navy`, `cobalt`, `aurora`, `ice`, `mint`, `rose`, `success`, `warning`, `pageGradient`, `surfaceGradient`, `buttonGradient`. Use `.orignalGlassCard()` view modifier for the standard frosted-glass card style. Use `OrignaLBackdrop()` for the full-screen gradient background.

### Auth
`AuthViewModel` handles email/password, Google Sign In (GIDSignIn), and Sign in with Apple (ASAuthorizationAppleIDCredential). Firebase Auth is configured in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`.

### Supported Languages
English, Spanish, French, German, Italian, Chinese, Portuguese, Russian, Japanese, Korean — mapped to language codes in `convertToLanguageCode(_:)` in Utils.swift.

### UI Test Accessibility Identifiers
Views use `.accessibilityIdentifier(...)` for UI tests. Key identifiers: `auth.emailField`, `auth.passwordField`, `auth.primaryButton`, `auth.toggleModeButton`, `auth.forgotPasswordButton`, `lesson.progressLabel`, `lesson.testCompleteButton`, `lesson.testCompleteUnitButton`, `unit.card.<N>`, `unit.locked.<N>`, `store.title`, `store.buyButton`, `store.testLifetimeButton`, `settings.signOutButton`.

## Firebase Data

### Lesson Document Shape
```json
{
  "id": "lesson-001",
  "lessonNumber": 1,
  "unitNumber": 1,
  "unitId": "unit-doc-id",
  "type": "Listening",
  "audioUrlDict": {
    "en": { "Word": "https://..." }
  },
  "foreModels": [{ "id": "...", "textDict": {"en": "Word"}, "imageUrl": "https://..." }],
  "backModels": [{ "id": "...", "textDict": {"en": "Word"}, "imageUrl": "https://...", "isCorrect": true }]
}
```

### Image/Audio Storage
Currently uses Firebase Storage (`fs.swift`). CDN migration to Cloudflare R2 (`https://assets.eduktok.com/`) is planned but not yet live. New lesson content should reference Firebase Storage URLs until R2 is configured.

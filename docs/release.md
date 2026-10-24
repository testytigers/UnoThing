# Releasing on Google Play

## One-time setup

1. **Upload key.** Create it once, back it up somewhere safe (losing it means
   asking Google to reset it), and never commit it:

   ```
   keytool -genkey -v -keystore ~/keys/the-one-thing-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **`android/key.properties`** (already in `android/.gitignore`):

   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/Users/<you>/keys/the-one-thing-upload.jks
   ```

   Without this file, release builds are signed with the debug key, which is
   fine for installing on your own phone and rejected by Play.

3. **Play App Signing:** accept it when creating the app. Google keeps the
   app signing key; you only ever upload with the upload key.

## Each release

1. Bump `version:` in `pubspec.yaml` (`1.1.0+2`: name + build number; the
   build number must always go up).
2. Decide on multi-habit: it ships visible while `FeatureFlags.multiHabit`
   defaults to `true`. To hide it until billing exists, build with
   `--dart-define=MULTI_HABIT=false` (or flip the default in
   `lib/core/feature_flags.dart`). The "Pro preview" switch in Settings goes
   with it.
3. `flutter analyze` and `flutter test` must be clean.
4. Build the bundle Play wants: `flutter build appbundle --release`
   → `build/app/outputs/bundle/release/app-release.aab`.

## Play Console declarations

- **Foreground service (specialUse):** the stopwatch keeps running with the
  app closed. Declare it under App content, Foreground service permissions,
  with the same reason as the manifest's `PROPERTY_SPECIAL_USE_FGS_SUBTYPE`
  ("user-started habit stopwatch...") and a short screen recording: start
  a pour, leave the app, show the notification counting, pause from it.
- **Notifications:** asked in context (first pour, or switching a reminder
  on).
- **Exact alarms:** the app declares `SCHEDULE_EXACT_ALARM` (the one the
  user grants on the system "Alarms & reminders" page, from Settings, On-time
  reminders), not the restricted `USE_EXACT_ALARM`, so no Play declaration is
  needed. Without the grant, reminders fall back to inexact alarms.
- **Data safety:** nothing is collected or shared. Pacts, days and the local
  account stay on the phone. Android's own backup can copy the database to
  the user's Google account (`res/xml/data_extraction_rules.xml`); that is
  the user's backup, not collection by the app.
- **Privacy policy:** Play asks for a URL even when nothing is collected; a
  short page saying the above is enough.
- **Target API:** builds target API 36 (Flutter's default), the level Play
  requires for new apps and updates in 2026.
- **New personal developer accounts** must run a closed test with at least
  12 testers for 14 days before production.

## What the build already does for Play's checks

- Edge-to-edge, predictive back (`enableOnBackInvokedCallback`), Android 12+
  splash, themed (monochrome) launcher icon.
- Large screens: phones stay portrait; Android 16 ignores the lock on
  tablets and foldables, and every screen is tested in landscape at tablet
  size (`test/features/accessibility_test.dart`).
- Accessibility: 48 dp touch targets, labelled controls and WCAG contrast,
  checked per screen in tests, plus layouts at 200% text.
- One notification channel per kind (Pouring, Session moments, Daily
  reminders, Last call, Milestones), so people can mute one and keep the
  rest.
- R8 shrinking with the Gson rules the notifications plugin needs
  (`android/app/proguard-rules.pro`).

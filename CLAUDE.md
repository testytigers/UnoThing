# The One Thing (Android, Flutter)

A minimalist, offline-only habit timer for one goal over a fixed Horizon
(1, 3, 6, 9 or 12 months). Each active day the user "pours" time into a cup
with a count-up stopwatch. 5 min saves the day, the daily target fills the cup,
a missed active day spills it.

Source of truth, in order: the build prompt (latest decisions) >
`docs/handoff.md` (not provided) > `docs/wireframes/*.png` > `docs/prototype/App.jsx`
(not provided).

**Design direction (user, 2026-10-21):** the wireframes are rough prototypes that
show flow, structure and copy only. The shipped visuals must be far more polished
and modern than them: depth, motion, refined typography, inside the color tokens below.
Match the wireframes' behavior, not their pixels.

## Stack

- Flutter stable, Dart null safety. Android only (keep code iOS-safe).
- State: `flutter_riverpod` (plain providers, no riverpod_generator).
- Routing: `go_router`.
- DB: `drift` (SQLite) + `drift_flutter`. Isar was rejected: `isar` has had no
  release since 2023-04.
- Background: `flutter_foreground_task`. It is actively released (v11, 2026-09)
  and `flutter_background_service` has had no release since 2024-12.
  FGS type `specialUse` (no type fits a stopwatch; shortService is ~3 min,
  dataSync is capped at 6h/day on Android 15+).
- Notifications: `flutter_local_notifications`. Haptics: `HapticFeedback` +
  `vibration`.
- Font: Inter 4.1, bundled in `assets/fonts/` (OFL). Never fetched at runtime.
- Tests: `flutter_test`, golden tests for the cup widget.
- Android: app id `io.passionatetalents.the_one_thing`, core library desugaring
  enabled (required by flutter_local_notifications), portrait only, edge-to-edge.
- Toolchain: Flutter 3.47.7 / Dart 3.13.5 (Homebrew cask), JDK 17,
  ANDROID_HOME=/opt/homebrew/share/android-commandlinetools.

## Folder structure (feature-first)

```
lib/
  main.dart
  app/            app.dart, router.dart, theme.dart
  core/           time/ (Clock), utils/, constants.dart
  data/           db/ (drift tables, dao), repositories/
  domain/         models/, services/ (day_status_service, timer_engine)
  features/
    auth/         frame_01_login
    onboarding/   frames 02-06 + onboarding_controller, onboarding_guide
    home/         home_screen (every goal), home_copy
    dock/         action_dock (buttons per page), dock_actions
    notifications/ reminder planner, scheduler, channels, taps
    pro/          proProvider, Pro sheet
    shelf/        frame_07_shelf (frame 10 = shelf + one-time fill anim)
    session/      frame_08_active, frame_11_stop, frame_12_banked_today
    day_detail/   frame_13_past_day, frame_14_spilled
    horizon/      frame_15_horizon
    settings/     (D5) reset goal + version
  widgets/        cup/, mascot/, paint/, dock/ (MorphingDock), primary_button,
                  secondary_button, edit_log_sheet, reminder_tile
test/
```

## Commands

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter analyze                                            # must be 0 issues
flutter test                                               # all tests
flutter test --update-goldens test/widgets/cup             # regenerate goldens
flutter run                                                # emulator/device
flutter build apk --release
```

## Business rules (implement exactly)

- **Units:** all durations are `int` seconds. Display `MM:SS`, `H:MM:SS` from an hour (`formatTimer`). Never store minutes.
- `safetyNetSeconds = 300` (fixed).
- **Goal:** `id, title (<=60 chars, trimmed non-empty),
  horizonMonths in {1,3,6,9,12}, dailyTargetSeconds in [300, 43200],
  activeWeekdays subset of 1..7 (Mon=1), non-empty, startDate (local date),
  reminderMinutes?, position`. One goal for free members; Pro members keep
  up to `maxProGoals` (3) side by side (user 2026-10-22, see Multi-habit).
- **Horizon:** `endDate = startDate + horizonMonths calendar months - 1 day`
  (clamp the day-of-month on short months: Jan 31 + 1 month = Feb 28/29).
  Total days = start..end inclusive.
- **DailyLog:** one row per goal and local date: `goalId, date, totalSeconds,
  status`.
- **dayStatus(date, totalSeconds, goal, today)**: pure, evaluated in this order:
  1. date > today -> FUTURE
  2. weekday not active -> REST
  3. total >= dailyTarget -> TARGET_REACHED
  4. total >= 300 -> SAVED
  5. date == today -> PENDING
  6. else -> SPILLED (includes 1..299s, D1)
- **Resume:** a session on a day that already has time starts from that day's
  `totalSeconds` (banked 00:05:06 -> Continue shows 00:05:06 and counts up).
- **Bank:** writes the stopwatch's current value as the day's new `totalSeconds`.
- **Discard:** drops only the unbanked part. Earlier banked total stays.
  Confirm only if the unbanked part is > 60s.
- **Safety net haptic:** fires once when the running total crosses 300s. Does not fire if
  the session resumed at >= 300. Must fire in the background (from the FGS) and
  show the notification "Safety net reached".
- **Edit Log:** minutes + seconds, overwrites `totalSeconds`, recomputes status.
  Today and past days inside the horizon only. Max 24h, non-negative.
  Setting 0 on a past active day makes it SPILLED again.

## Timer engine

- Persist `ActiveSession(date, baseSeconds, segmentStartedAt?, accumulatedSeconds)`.
- value = base + accumulated + (now - segmentStartedAt, if running).
- Pause: fold the running segment into accumulated, null segmentStartedAt. Resume: segmentStartedAt = now.
- On launch with an ActiveSession: route to Frame 8 (running) or 11 (paused).
- UI ticks 1/s for display only. The FGS keeps the process alive and updates the notification.
- **Midnight rollover:** bank up to 23:59:59 to the old date, then continue on the new date.
- Ask for the notification permission on the first session start, not at launch.

## Open decisions (defaults in use, flag them in reports)

- D1: 1-299s on a past active day = SPILLED.
- D2: non-active weekday = `rest` cup (very faded outline, no crack, no tap), never spilled.
- D3: Login is local only: `AuthRepository` with an on-device hashed-credential impl.
  Both buttons go to onboarding (no goal) or the Shelf (goal exists).
- D4: Horizon "X/Y days": X = SAVED + TARGET_REACHED days, Y = total horizon days.
- D5: Gear opens Settings (grew on 2026-10-22: reminders, Pro preview, delete a goal, Reset goal / Reset everything, version).
- D6: After endDate the Shelf shows the final week read-only and no new sessions start.
- D7 (new, not in spec): days before startDate or after endDate are
  `outsideHorizon` (checked first in dayStatus), never SPILLED. Shelf shows them
  like rest cups with no tap.
- Month-end horizon math clamps the day (Jan 31 + 1 month = Feb 28/29), then -1 day.

## Progress

- Phase 1 setup: done. Phase 2 data/rules: done. Phase 3 cup + goldens: done.
- Phase 4 onboarding (Frames 1-6) + Settings (D5): done. App opens on the Shelf
  when a goal exists, otherwise on Login. Login needs an existing local account;
  Create account needs a password of 6+ characters.
- Copy written by Claude (not in the spec, flagged to the user): login validation
  errors, the Daily Target min/max messages, the Reset goal dialog.
- Widget tests that reach screens watching drift streams must end with
  `unmountApp(tester)` (test/helpers/app_harness.dart), or a pending drift timer fails them.
- Phases 5 (Shelf, Horizon), 6 (timer engine) and 7 (session screens, Edit Log):
  done. No placeholder screens remain. Next: Phase 8 (foreground service,
  notification, background haptic, notification permission on first start).
- Phase 8 (pouring notification): `flutter_foreground_task` service, type
  `specialUse` (manifest has the PROPERTY_SPECIAL_USE_FGS_SUBTYPE explanation).
  `PourTaskHandler` (service isolate) opens its own drift connection, ticks 1 s,
  applies midnight rollover, fires the safety net once (vibration +
  "Safety net reached" notification when the app isn't in the foreground), and
  updates the ongoing notification (goal · HH:MM:SS, coach line, Pause/Resume +
  Stop). The DB is the source of truth. While the service is active, the app's
  ticker re-reads the DB and does not fire the alert itself. `PourService` is
  faked in tests (`NoopPourService` by default in the harness). The permission
  is asked on the first session start or restore, never at launch. The service
  keeps running when the app is swiped away (`stopWithTask: false`).
- UX revision (user-approved 2026-10-21, overrides the wireframes/spec):
  - No logo inside the app (superseded by the mascot redesign below).
  - Shelf: goal title + progress pill ("Day N of M · X saved" opens the
    Horizon), today's cup as the hero (large, thresholds) with one adaptive
    button (Start pouring / Keep pouring / Back to your pour / disabled on rest
    or after the horizon), then the week as a compact card of 7 small cups.
  - Onboarding is 5 steps (user 2026-10-21: the one-page pact builder was
    too crowded): goal, Horizon (`/onboarding/horizon`, tiles with each
    finish date), Daily Target (`/onboarding/target`, big number tiles
    10/15/25/45/60 + a Custom wheels sheet), Days (`/onboarding/days`, Every
    day / Weekdays / Weekends + the week as seven glasses: tap to switch
    pour/rest), then the contract. All "Next" rules kept.
  - Labels: Stop -> Finish, Bank time -> Save session (primary), Discard is a
    text link, Frame 12's Continue -> Keep pouring, Edit Log -> Adjust time.
  - Timer `MM:SS` under an hour, `H:MM:SS` after (`formatTimer`).
  - Future cups are whisper outlines. Threshold labels are "Goal" / "Saved".
  - Moments: gold pulse at 5:00, gold rim drawing + flake flare at the goal
    (running cups only, respects reduce motion), and a pour stream into
    today's cup after a save.
- Routes from the Shelf are nested under `/shelf` so Back always returns to it.
  Frames 13/14 share `/shelf/day/:date` and pick the view from the live status.
- Horizon (user decision 2026-10-21, overrides the spec's "from startDate"):
  a calendar. Rows are Monday-Sunday weeks with a pinned M T W T F S S header,
  and days before startDate / after endDate are blank cells.
- D8 (new): a paused session left from a past date is banked to that date on
  launch (no time lost), never resumed onto a new day.
- Future non-active weekdays keep status FUTURE (spec table order) but draw as
  rest cups so rest days are visible ahead (D2).
- Test harness uses a 412x915 dp viewport. Running cups animate forever, so on
  session screens use `settleAsync(tester, settle: false)`, not pumpAndSettle.

## Design system "Cream & Royal, with a mascot" (user, 2026-10-21; replaces "Royal Flake")

The user found the previous look outdated and asked for a redesign inspired by
"Talkie" (Aziza Guluzade, Behance): soft tinted canvas, flat white tiles, one
bold accent, a dark neutral button, a chunky playful headline font, and a big
friendly mascot. All tokens live in `lib/app/theme.dart` (`AppTokens.light`,
the only token set); widgets never hard-code colors.
- **Palette:** cream canvas `#F6F2EA`, white tiles, ink `#1A1B2E`. Brand
  periwinkle `#6A8DFF` (user, 2026-10-21: the deeper royal made the mascot's
  black face muddy; this gives 5.5:1) for the mascot, selected tiles,
  progress, today. Text on periwinkle is ink (`onBrand`); periwinkle text on
  light backgrounds uses `brandInk` `#3B5BDB`. Primary buttons are soft ink
  `#26283D` (flat, no glitter, no gradient), secondary buttons white. Gold
  for the target line / full rim (`goldInk` for gold text), coral `#F2564A`
  for spilled / errors.
- **Type:** Inter for everything, plus Rubik ExtraBold (OFL, Latin subset,
  `assets/fonts/Rubik-ExtraBold.ttf`) for headlines and big moments: Login,
  onboarding titles, the goal title on the Shelf, Horizon, day verdicts.
  User: "bold and yet fun, not too comic" (DynaPuff was rejected as too
  comic). Never serif.
- **Glitter only in the cup's liquid** (and the falling drop): `paint*` tokens,
  `shaders/royal_paint.frag` via `RoyalPaint.fill`, glints from `PaintMotion`.
  `RoyalPaint.enabled = false` in tests.
- **Cups** (vector-illustration style, user 2026-10-21: "like it's made with
  Illustrator"): a glass tumbler seen slightly from above. Rim and base are
  ellipses (`CupGeometry.tilt`), the far inner wall shows through the
  opening, the liquid has a lit elliptical surface that ripples, a darker
  band shades the right wall, two white highlight strokes run down the left,
  thin blue-grey edges, a flat ground shadow. Gold rim when full (draws
  itself round during the "full" moment). Thresholds are dashed arcs round
  the near side with labels by the walls. Spilled = the glass knocked over,
  opening to the left with a coral rim, milk pooling out. Future = faint
  silhouette; rest = dashed outline. `onCard` cools the glass for white cards.
- **Mascot** (`lib/widgets/mascot/`, user 2026-10-21, from GIF references
  of hand-drawn blob characters): a plump periwinkle **water drop** (one
  smooth teardrop: round belly, pointed tip; never a ball with a spike), flat
  color, a flat ground shadow. The outline "boils" (redraws with a soft
  wobble 8 times a second, like hand-drawn animation). A compact face of
  thick black strokes set high on the belly: two black oval "0" eyes, each
  with a small white catch-light (user 2026-10-21: not dashes), and an open
  "D" smile, white inside, inked round. Moods shape the ovals: star
  catch-lights (sparkle), brows (sad, angry), heavy lids (disappointed),
  squeezed to a line in a blink. The face maps
  onto the belly so it can turn; avatars rest turned 0.4 rad toward their
  speech bubble (three-quarter view, `facing`). Moods: idle, happy,
  sparkle, sleepy, shy (only mood with pink cheeks), wow, sad, focus, cool
  (black sunglasses), angry (scowl + anger mark), disappointed ("-_-" +
  sweat drop). It breathes, blinks, glances to the sides, and on every mood
  change spins a full turn with a hop, swapping the face while it looks
  away, then lands with a squash. The face is never one rigid stamp (user,
  2026-10-21): the eyes and the mouth are separate layers. The mouth
  follows a turn a beat later (at most 0.3 rad behind), sits deeper (less
  parallax when looking), and bunches up on landing while the eyes flatten.
  The eyes dart now and then and stretch on hops. Smiles breathe. The
  mouth talks (opens and closes about 4 times a second for 1.2 s)
  whenever `talkKey` changes: coach bubbles and the onboarding guide pass
  their message, and it says hello when it appears. Still under reduce motion and in tests
  (`Mascot.ambient = false` in `test/flutter_test_config.dart`).
  - `MascotPeek`: its huge body rises from the bottom of the screen with
    the Login form on its belly.
  - `MascotGuide` (onboarding, user 2026-10-21): a full-width card pinned on
    top of each step with the mascot, a message for that moment, and a
    progress pie ("1/5"). Copy lives in `onboarding_guide.dart`: a hello and
    a cheer for the goal; the horizon's promise; on the amount and days steps
    a fun fact ("That's about 38 hours of Learn Judo by 20 Jan", counted from
    the pour days to the finish line); no days = sad; on the contract,
    shades on once committed. The old top progress bar is gone.
  - `CoachBubble`: the mascot speaking the coach lines (Shelf, Frames 8, 11,
    12, 13/14). Moods come from `session_copy.dart` (`liveSessionMood`,
    `bankedTodayMood`, `shelfMood`): focus while pouring, happy once saved,
    cool at a full cup, sleepy on rest days.
  - Per situation: Login follows the email caret, shy on the password, wow
    at a typo, angry at a refused login, happy while signing in. Contract:
    shades once committed. Spilled day: disappointed. On target: cool.
    Discard dialog: disappointed. Reset dialog: sad. Toast: happy.
    Safety net crossed (top bubble): sparkle. Settings: sleepy.
  - Launcher icon = the whole drop in shades on cream:
    `flutter test tool/render_launcher_icons_test.dart`.
- No logo in the app (the old T-and-drop `AppLogo` was removed; the mascot is
  the brand).
- Session screens stay light. The mascot's message sits on top (under the
  date bar, user 2026-10-23, like Home and the Shelf, where it sits under the
  title); the cup and timer are centred below. Crossing the safety net, that
  top bubble says "Day saved. Nothing can spill it now." with sparkle (the
  separate gold banner is gone).
- Text in coral uses `dangerInk` (`#C0392B`, 5.4:1 on white); `danger` is for
  shapes and the big spilled timer only.
- Copy written by Claude in the redesign (flag to the user): pact section
  labels "How long?", "How much each day?", "Which days?"; login hints
  "Email" / "Password" (labels dropped); every guide message in
  `onboarding_guide.dart`; step titles "How long is your pact?", "How much
  each day?", "Which days will you pour?"; "Your week", "Tap a glass to make
  it a rest day.", "Pour" / "Rest", "min a day", "Your own", "Until <date>".
  The step counter is now "1/5" in the pie.

## Multi-habit (Pro), reminders, Play standards (user 2026-10-22)

- **Pro / flag:** `FeatureFlags.multiHabit` (`lib/core/feature_flags.dart`,
  `--dart-define=MULTI_HABIT=false` hides it) gates the habit pages, the
  "+" page and the "Pro preview" switch in Settings. No billing yet:
  `proProvider` is true only with the preview switch on (testing). Free = 1
  goal, Pro = 3 (`goalLimit`, enforced again in `OnboardingController.submit`).
  When Pro lapses, existing goals stay usable; only adding is blocked (to
  revisit with billing).
- **Data:** schema v2 (`AppDatabase.migration`): `daily_logs` keyed by
  `(goalId, date)`, `active_sessions` gains `goalId` + `targetFired`, goals
  gain `reminderMinutes` + `position`, new `preferences` key/value table
  (`Pref.*`). v1 data moves under its single goal (`test/data/migration_test.dart`).
- **One goal pours at a time.** The session carries its `goalId`; other
  goals' pages show "Back to your pour" and "You're pouring into X right
  now." `sessionGoalProvider` is the pouring goal; `goalProvider` is the
  selected page (`selectedGoalIdProvider`, persisted as `shelf.goal`).
- **Home + dock (user 2026-10-23, replaces the habit swipe pages):** the app
  opens on Home (`/home`): every goal as a card (today's mini cup, "7 / 25
  min today · Saved", a pact bar of days saved over days gone, "Day 9 of 90",
  "4 saved"), the mascot summing up the day, a gear to Settings. A card opens
  that goal's Shelf (`/home/habit`, the selected goal), which has a back
  arrow and no big button. Session pages hang under it
  (`/home/habit/session|stop|today|day/:date|horizon`).
- **The dock** (`lib/widgets/dock/morphing_dock.dart` + `features/dock/`):
  no tab bar (user: "do we really need a whole menu"), one floating black
  bar above every page (`MaterialApp.builder`) whose buttons are the page's
  actions, morphing between pages ("menu movements", not a drop shape):
  items keep their slot by id, stretch / shrink (a "Start pouring" pill
  folds into a round pause while play morphs to pause), new ones grow in,
  old ones fold away, the bar wobbles like jelly. Per page (`dockItems`):
  Home = New habit (Pro sheet when free); Shelf = Horizon · Start/Keep
  pouring (or Rest day / Horizon complete, disabled) · Reminder; pouring
  anywhere = pause · live timer (+ progress line, tap opens the session) ·
  Finish; Frame 8 = Pause · Finish; Frame 11 = Continue · Save session ·
  Discard; Frame 12 = Keep pouring · Adjust time; past day = Adjust time.
  Starting from the dock pours in place; tapping the big cup opens Frame 8.
  The dock hides under dialogs / sheets (`PopupRouteObserver`) and the
  keyboard; pages leave `MorphingDock.reserve` at the bottom. Actions live
  in `dock_actions.dart` (dialogs use `rootNavigatorKey`).
  Week arrows only on the Shelf. Hero tags are `cupHeroTag(goalId, date)`.
- **Adding a goal** reuses the onboarding steps (`addHabit`,
  `OnboardingDraft.adding`): step 1 reads "What's your next thing?". Sealing
  a pact lands on Home.
- **Reminders** (`lib/features/notifications/`): `planReminders` (pure)
  plans the next 7 days: daily reminder at the goal's time on pour days
  (skipped once today is saved or while pouring), the 9 PM last call for
  every goal still unsaved (one notification), and milestones at 9 AM
  (halfway, final week, last day). `RemindersController` (watched by the
  app root) reschedules on every change and on resume, and withdraws
  today's shown ones once saved. Exact alarms when the person allows
  "Alarms & reminders" (`SCHEDULE_EXACT_ALARM`, Settings > On-time
  reminders, `exactRemindersProvider`), inexact otherwise (Android may hold
  those up to an hour). Boot / update receivers in the manifest restore
  them. "Start pouring" button on
  reminders (`handleNotificationTap`). Cup full in the background:
  `PourTaskHandler` alerts once (`targetFired`). One channel per kind
  (`AppChannel`); the old `safety_net` channel is deleted at startup.
  Permission is asked in context (first pour, contract reminder, switching
  a reminder on); Settings shows a banner when blocked.
- **Contract** offers "Remind me" at 7 PM (default on, `defaultReminderMinutes`).
- **Settings:** reminders per goal + Last call + Milestones, Pro preview,
  delete a goal (Pro), Reset goal / Reset everything, version.
- **After a save** one drop falls into today's cup and the level rises as
  it lands (the old pour stream read as a stick poking into the cup).
- A save that completes a week of pour days shows "A full week saved!"
  with the cool mascot.
- **Play standards:** see `docs/release.md` (upload-key signing via
  `android/key.properties`, AAB, declarations). Backups include only the
  database (`res/xml/*_rules.xml`). Accessibility guideline tests per screen
  plus 200% text and tablet landscape (`test/features/accessibility_test.dart`).
- **Tests:** the harness disables `RemindersController` unless
  `pumpApp(reminders: true)`; fakes: `NoopNotificationScheduler`.
- Copy written by Claude (flag to the user): every reminder / last call /
  milestone / cup-full notification text, Home ("Your habits" / "Your one
  thing", the mascot's day lines in `home_copy.dart`, card lines), the dock
  labels ("New habit", "Reminder" sheet), the Pro
  sheet, "What's your next thing?", the step-1 line for another goal, the
  Settings labels and banner, "Remind me", "You're pouring into X right
  now.", "A full week saved! Keep it rolling.", the delete / reset dialogs.

## Do not

- Add screens, features, analytics, ads, or network calls not in the spec.
- Store durations in minutes.
- Use `Timer.periodic` as the source of truth for elapsed time.
- Fetch fonts or anything else from the internet at runtime.
- Silently resolve open decisions. Use the default and list it in the phase report.
- Invent copy. Fix wireframe typos only ("Tratget" -> "Target", "Gaol" -> "Goal").

## Work plan

Phases 1-9 (setup, data/rules, cup, onboarding, shelf/horizon, timer engine,
session screens, background, polish). Stop and report after each phase: what
was built, test results, assumptions, blockers.

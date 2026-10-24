/// Seconds a day needs to be "saved" (the Safety Net). Fixed by the spec.
const int safetyNetSeconds = 300;

/// Daily target bounds, in seconds.
const int minDailyTargetSeconds = safetyNetSeconds;
const int maxDailyTargetSeconds = 12 * 60 * 60;

/// Default daily target (0 hrs 25 min).
const int defaultDailyTargetSeconds = 25 * 60;

/// Upper bound accepted by the Edit Log sheet.
const int maxLoggableSeconds = 24 * 60 * 60;

const int maxGoalTitleLength = 60;

const List<int> horizonMonthOptions = [1, 3, 6, 9, 12];

/// The daily reminder offered when a pact is sealed: 7 PM.
const int defaultReminderMinutes = 19 * 60;

/// Goals a Pro member can keep at once. Free members keep one.
const int maxProGoals = 3;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../../data/repositories/preferences_repository.dart';

/// Whether Pro is unlocked. Until billing ships, only the test preview in
/// Settings unlocks it.
final proProvider = Provider<bool>(
  (ref) =>
      FeatureFlags.multiHabit && ref.watch(appPreferencesProvider).proPreview,
);

/// How many goals someone may keep: one, or [maxProGoals] with Pro.
int goalLimit({required bool pro}) => pro ? maxProGoals : 1;

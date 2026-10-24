import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';

/// Preference keys.
abstract final class Pref {
  /// The goal the Shelf shows (its last page).
  static const shelfGoal = 'shelf.goal';

  /// Pro unlocked locally for testing, until billing ships.
  static const proPreview = 'pro.preview';

  /// The evening "last call" when today isn't saved yet.
  static const lastCall = 'reminders.last_call';

  /// Horizon milestones (halfway, final week, last day).
  static const milestones = 'reminders.milestones';
}

class PreferencesRepository {
  PreferencesRepository(this._db);

  final AppDatabase _db;

  Stream<Map<String, String>> watchAll() => _db
      .select(_db.preferences)
      .watch()
      .map((rows) => {for (final r in rows) r.key: r.value});

  Future<Map<String, String>> getAll() => _db
      .select(_db.preferences)
      .get()
      .then((rows) => {for (final r in rows) r.key: r.value});

  /// Stores [value] under [key]; null removes it.
  Future<void> set(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.preferences)..where((t) => t.key.equals(key))).go();
      return;
    }
    await _db
        .into(_db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(key: key, value: value),
        );
  }

  Future<void> setBool(String key, bool value) => set(key, '$value');
}

/// The preferences, typed, with their defaults.
@immutable
class AppPreferences {
  const AppPreferences({
    this.proPreview = false,
    this.lastCall = true,
    this.milestones = true,
  });

  factory AppPreferences.from(Map<String, String> raw) => AppPreferences(
    proPreview: raw[Pref.proPreview] == 'true',
    lastCall: raw[Pref.lastCall] != 'false',
    milestones: raw[Pref.milestones] != 'false',
  );

  final bool proPreview;
  final bool lastCall;
  final bool milestones;

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.proPreview == proPreview &&
      other.lastCall == lastCall &&
      other.milestones == milestones;

  @override
  int get hashCode => Object.hash(proPreview, lastCall, milestones);
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.watch(databaseProvider)),
);

final _rawPreferencesProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(preferencesRepositoryProvider).watchAll(),
);

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) =>
      AppPreferences.from(ref.watch(_rawPreferencesProvider).value ?? const {}),
);

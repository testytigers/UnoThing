import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Authentication boundary. The app is offline-only, so the only
/// implementation is [LocalAuthRepository] (open decision D3).
abstract interface class AuthRepository {
  /// Throws [AuthException] if the email or password is wrong.
  Future<void> signIn({required String email, required String password});

  /// Throws [AuthException] if an account with this email already exists.
  Future<void> createAccount({required String email, required String password});
}

/// Stores credentials on the device only: salted PBKDF2-HMAC-SHA256.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final Random _random;

  static const _iterations = 20000;
  static const _keyLength = 32;

  @override
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    final key = _normalize(email);
    final existing = await _find(key);
    if (existing != null) {
      throw const AuthException(
        'This email already has an account here. Try Login instead.',
      );
    }
    final salt = Uint8List.fromList(
      List.generate(16, (_) => _random.nextInt(256)),
    );
    await _db
        .into(_db.localAccounts)
        .insert(
          LocalAccountsCompanion.insert(
            email: key,
            passwordHash: base64Encode(_pbkdf2(password, salt)),
            salt: base64Encode(salt),
          ),
        );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final account = await _find(_normalize(email));
    if (account == null) {
      throw const AuthException(
        "That email and password don't match. Try again?",
      );
    }
    final hash = _pbkdf2(password, base64Decode(account.salt));
    if (!_constantTimeEquals(hash, base64Decode(account.passwordHash))) {
      throw const AuthException(
        "That email and password don't match. Try again?",
      );
    }
  }

  Future<LocalAccountRow?> _find(String email) {
    final query = _db.select(_db.localAccounts)
      ..where((t) => t.email.equals(email));
    return query.getSingleOrNull();
  }

  static String _normalize(String email) => email.trim().toLowerCase();

  static Uint8List _pbkdf2(String password, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block);
    var u = block;
    for (var i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return Uint8List.sublistView(result, 0, _keyLength);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(ref.watch(databaseProvider)),
);

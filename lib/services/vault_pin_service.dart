import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A PIN dedicated to unlocking the Secure Vault — intentionally independent
/// of the device's own screen-lock PIN/pattern/biometric enrollment, so
/// anyone who can unlock the phone (family, a borrowed device) doesn't
/// automatically get into the vault too. Stored as a salted SHA-256 hash;
/// the PIN itself is never persisted.
class VaultPinService {
  VaultPinService._();
  static final VaultPinService instance = VaultPinService._();

  static const _hashKey = 'vault_pin_hash_v1';
  static const _saltKey = 'vault_pin_salt_v1';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<bool> hasPin() async {
    final p = await _p;
    return p.getString(_hashKey) != null;
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  String _newSalt() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<void> setPin(String pin) async {
    final p = await _p;
    final salt = _newSalt();
    // Write the salt first — if setting the hash fails partway, a stale salt
    // with no matching hash just means hasPin() still (correctly) reports
    // false, rather than a hash checked against the wrong salt.
    await p.setString(_saltKey, salt);
    await p.setString(_hashKey, _hash(pin, salt));
  }

  Future<bool> verifyPin(String pin) async {
    final p = await _p;
    final salt = p.getString(_saltKey);
    final hash = p.getString(_hashKey);
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  /// Removes the stored PIN, so the next vault access goes through setup
  /// again. Not currently wired to any UI action — reserved for a future
  /// "forgot PIN" recovery flow.
  Future<void> clearPin() async {
    final p = await _p;
    await p.remove(_hashKey);
    await p.remove(_saltKey);
  }
}

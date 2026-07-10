import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic [StateNotifier] for a simple on/off setting backed by a two-value
/// enum and persisted via a cached get/set pair (the app's established
/// `PlayerPreferencesService` pattern: a synchronously-readable cache plus an
/// async save). Used by [controlsStyleProvider] and [cardStyleProvider] (and
/// any future boolean-style toggle) so each doesn't hand-roll the same
/// seed-from-cache + toggle boilerplate.
class BoolPreferenceNotifier<T> extends StateNotifier<T> {
  final T Function(bool) _fromBool;
  final bool Function(T) _toBool;
  final Future<void> Function(bool) _save;

  BoolPreferenceNotifier({
    required bool initial,
    required T Function(bool) fromBool,
    required bool Function(T) toBool,
    required Future<void> Function(bool) save,
  })  : _fromBool = fromBool,
        _toBool = toBool,
        _save = save,
        super(fromBool(initial));

  Future<void> setValue(bool value) async {
    state = _fromBool(value);
    await _save(value);
  }

  Future<void> toggle() => setValue(!_toBool(state));
}

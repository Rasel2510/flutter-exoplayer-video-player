import 'media_session_service.dart';

/// Reference-counted guard around [MediaSessionService.setSecureScreen].
/// Vault screens call [activate] in initState and [deactivate] in dispose;
/// since the PIN screen and the vault list can briefly overlap mid-transition
/// (one disposing while the other is already mounted), a raw on/off call from
/// each screen would race and could clear the flag while the vault is still
/// visible. Counting active screens keeps the native flag on for as long as
/// any of them is up.
class SecureScreenGuard {
  SecureScreenGuard._();

  static int _count = 0;

  static void activate() {
    _count++;
    if (_count == 1) MediaSessionService.setSecureScreen(true);
  }

  static void deactivate() {
    if (_count == 0) return;
    _count--;
    if (_count == 0) MediaSessionService.setSecureScreen(false);
  }
}

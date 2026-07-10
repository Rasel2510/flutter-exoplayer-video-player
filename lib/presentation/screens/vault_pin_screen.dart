import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/data/services/secure_screen_guard.dart';
import 'package:flutter_video_player/data/services/vault_pin_service.dart';
import 'package:flutter_video_player/data/services/vault_service.dart';
import 'package:flutter_video_player/presentation/widgets/vault/vault_keypad.dart';

enum VaultPinMode { create, unlock }

/// Numeric PIN pad for the Secure Vault. In [VaultPinMode.create] the user
/// enters a new PIN twice (create then confirm) before it's saved. In
/// [VaultPinMode.unlock] the user enters their existing vault PIN; device
/// biometrics are offered as a secondary shortcut when available, but the
/// vault's own PIN is never derived from — or checked against — the device's
/// screen-lock credential. Pops `true` on success, `false`/null on cancel.
class VaultPinScreen extends StatefulWidget {
  final VaultPinMode mode;
  const VaultPinScreen({super.key, required this.mode});

  @override
  State<VaultPinScreen> createState() => _VaultPinScreenState();
}

class _VaultPinScreenState extends State<VaultPinScreen> {
  static const _pinLength = 6;
  String _entered = '';
  String? _firstEntry; // during create: the PIN typed on the first pass
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SecureScreenGuard.activate();
  }

  @override
  void dispose() {
    SecureScreenGuard.deactivate();
    super.dispose();
  }

  bool get _confirming =>
      widget.mode == VaultPinMode.create && _firstEntry != null;

  String get _title {
    if (widget.mode == VaultPinMode.unlock) return 'Enter Vault PIN';
    return _confirming ? 'Confirm PIN' : 'Create Vault PIN';
  }

  String get _subtitle {
    if (widget.mode == VaultPinMode.unlock) {
      return 'This PIN is separate from your device unlock';
    }
    return _confirming
        ? 'Enter the same PIN again'
        : 'Choose a PIN just for the vault — different from your device unlock';
  }

  void _onDigit(String d) {
    if (_busy || _entered.length >= _pinLength) return;
    setState(() {
      _error = null;
      _entered += d;
    });
    if (_entered.length == _pinLength) _onComplete();
  }

  void _onBackspace() {
    if (_busy || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _onComplete() async {
    if (widget.mode == VaultPinMode.create) {
      if (_firstEntry == null) {
        setState(() {
          _firstEntry = _entered;
          _entered = '';
        });
        return;
      }
      if (_entered != _firstEntry) {
        setState(() {
          _error = "PINs didn't match — try again";
          _firstEntry = null;
          _entered = '';
        });
        return;
      }
      setState(() => _busy = true);
      await VaultPinService.instance.setPin(_entered);
      if (mounted) Navigator.pop(context, true);
      return;
    }

    // Unlock
    setState(() => _busy = true);
    final ok = await VaultPinService.instance.verifyPin(_entered);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = 'Incorrect PIN';
        _entered = '';
      });
    }
  }

  Future<void> _useBiometrics() async {
    final ok = await VaultService.instance.authenticate();
    if (!mounted) return;
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.colors.textPrimary),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const Spacer(),
              Icon(Icons.lock_rounded, size: 40, color: context.colors.accent),
              const SizedBox(height: 20),
              Text(
                _title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.colors.textMuted),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          filled ? context.colors.accent : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? context.colors.accent
                            : context.colors.border,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: _error != null
                    ? Text(
                        _error!,
                        style:
                            TextStyle(color: context.colors.errorRed, fontSize: 12),
                      )
                    : null,
              ),
              const Spacer(),
              VaultKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                enabled: !_busy,
              ),
              if (widget.mode == VaultPinMode.unlock) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _busy ? null : _useBiometrics,
                  icon: Icon(Icons.fingerprint_rounded,
                      color: context.colors.accent),
                  label: Text('Use biometrics instead',
                      style: TextStyle(color: context.colors.accent)),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

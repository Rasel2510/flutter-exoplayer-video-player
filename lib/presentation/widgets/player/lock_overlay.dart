import 'package:flutter/material.dart';

class LockOverlay extends StatelessWidget {
  final VoidCallback onUnlock;

  const LockOverlay({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: onUnlock,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xA6000000),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0x40FFFFFF), width: 1),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

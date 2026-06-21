import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_player/core/utils/volume_color.dart';

void main() {
  const accent = Color(0xFF2196F3); // blue

  group('VolumeColor.boostT', () {
    test('is 0 at or below 100%', () {
      expect(VolumeColor.boostT(0), 0.0);
      expect(VolumeColor.boostT(50), 0.0);
      expect(VolumeColor.boostT(100), 0.0);
    });

    test('ramps linearly from 100% to 200%', () {
      expect(VolumeColor.boostT(150), closeTo(0.5, 1e-9));
      expect(VolumeColor.boostT(200), 1.0);
    });

    test('clamps above 200%', () {
      expect(VolumeColor.boostT(250), 1.0);
    });
  });

  group('VolumeColor.forVolume', () {
    test('returns the accent colour untouched at or below 100%', () {
      expect(VolumeColor.forVolume(80, accent), accent);
      expect(VolumeColor.forVolume(100, accent), accent);
    });

    test('is fully orange at 200%', () {
      expect(VolumeColor.forVolume(200, accent), VolumeColor.boost);
    });

    test('is a blend between accent and orange mid-boost', () {
      final mid = VolumeColor.forVolume(150, accent);
      expect(mid, isNot(accent));
      expect(mid, isNot(VolumeColor.boost));
      // Halfway, each channel should sit between the two endpoints.
      expect(mid.r, greaterThan(accent.r));
      expect(mid.g, lessThan(accent.g));
    });
  });
}

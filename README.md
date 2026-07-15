# Ayesha — Android Video Player

A local video player for Android built with Flutter, backed by a native ExoPlayer
(Media3) engine with an automatic software-decoder fallback for codecs the
device's hardware can't handle (e.g. some 10-bit HEVC files).

## Features

- **Fast library scanning** via Android's `MediaStore` (no recursive filesystem
  walk), with live updates when files are added/removed and manual folder
  scan-mode options.
- **Hardware-accelerated playback** through a custom native ExoPlayer/Media3
  bridge, with automatic fallback to a `media_kit` (libmpv/FFmpeg) software
  decoder when the device can't decode a video track in hardware.
- **Instant thumbnails**: MediaStore-cached thumbnail → `MediaMetadataRetriever`
  frame extraction → software-decoded frame grab, in that order, so even
  otherwise-undecodable HEVC files get a poster.
- **Player controls**: gesture-based brightness/volume swipe, double-tap seek,
  pinch zoom, hold-to-fast-forward, A-B repeat, sleep timer (by time or
  end-of-video), playback speed control, loop modes.
- **Tracks & subtitles**: audio track switching, embedded and external
  subtitle support with style customization and sync delay adjustment.
- **Lock-screen / notification media session** with playback controls and
  synced art.
- **Picture-in-picture**, resume-from-last-position, and a locked-controls
  overlay for accidental-touch protection.
- **Secure Vault**: Hide and protect private videos behind a PIN or biometric
  authentication, keeping them out of the main library.
- **Persistent Player Volume**: Automatically remembers and restores the
  video player's volume level across sessions.

## Tech stack

- Flutter + Riverpod for state management
- Native Kotlin ExoPlayer/Media3 bridge (`android/`) as the primary playback
  engine
- [`media_kit`](https://pub.dev/packages/media_kit) (libmpv/FFmpeg) as the
  software-decoding fallback engine
- `video_thumbnail` / native `MediaStore` bridge for thumbnail generation
- `local_auth` and `crypto` for Secure Vault authentication and PIN hashing

## Building

```bash
flutter pub get
flutter build apk --split-per-abi   # per-ABI release APKs
```

Split APKs are written to `build/app/outputs/flutter-apk/`. For a phone, the
`arm64-v8a` APK is the one to install.

## License

Licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE). Free for
personal and other noncommercial use; commercial use requires a separate
license — see the LICENSE file for contact details.

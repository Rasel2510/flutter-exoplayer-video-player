import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_player/core/utils/track_labels.dart';

void main() {
  group('TrackLabels.isPlaceholderId', () {
    test('treats media_kit synthetic ids as placeholders', () {
      expect(TrackLabels.isPlaceholderId('auto'), isTrue);
      expect(TrackLabels.isPlaceholderId('no'), isTrue);
    });

    test('treats real numeric ids as real tracks', () {
      expect(TrackLabels.isPlaceholderId('0'), isFalse);
      expect(TrackLabels.isPlaceholderId('1'), isFalse);
      expect(TrackLabels.isPlaceholderId('audio-en'), isFalse);
    });
  });

  group('TrackLabels.languageName', () {
    test('maps 2- and 3-letter codes to readable names', () {
      expect(TrackLabels.languageName('en'), 'English');
      expect(TrackLabels.languageName('eng'), 'English');
      expect(TrackLabels.languageName('fra'), 'French');
      expect(TrackLabels.languageName('zho'), 'Chinese');
    });

    test('is case-insensitive and trims whitespace', () {
      expect(TrackLabels.languageName('ENG'), 'English');
      expect(TrackLabels.languageName(' en '), 'English');
    });

    test('returns null for missing / undefined codes', () {
      expect(TrackLabels.languageName(null), isNull);
      expect(TrackLabels.languageName(''), isNull);
      expect(TrackLabels.languageName('und'), isNull);
    });

    test('falls back to upper-cased code for unknown languages', () {
      expect(TrackLabels.languageName('xyz'), 'XYZ');
    });
  });

  group('TrackLabels.trackLabel', () {
    test('prefers a non-empty title', () {
      expect(
        TrackLabels.trackLabel(
            title: 'Commentary', language: 'eng', index: 0, total: 2),
        'Commentary',
      );
    });

    test('falls back to language name when title is blank', () {
      expect(
        TrackLabels.trackLabel(
            title: '  ', language: 'eng', index: 0, total: 2),
        'English',
      );
    });

    test('numbers tracks only when more than one exists', () {
      expect(
        TrackLabels.trackLabel(title: null, language: null, index: 0, total: 1),
        'Default',
      );
      expect(
        TrackLabels.trackLabel(title: null, language: null, index: 0, total: 3),
        'Track 1',
      );
      expect(
        TrackLabels.trackLabel(title: null, language: null, index: 2, total: 3),
        'Track 3',
      );
    });
  });
}

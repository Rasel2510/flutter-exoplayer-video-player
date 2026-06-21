import 'package:flutter/material.dart';

enum SortOption { name, dateModified, size, duration }

extension SortOptionX on SortOption {
  String get label => switch (this) {
        SortOption.name => 'Name',
        SortOption.dateModified => 'Date modified',
        SortOption.size => 'File size',
        SortOption.duration => 'Duration',
      };
  IconData get icon => switch (this) {
        SortOption.name => Icons.sort_by_alpha_rounded,
        SortOption.dateModified => Icons.access_time_rounded,
        SortOption.size => Icons.data_usage_rounded,
        SortOption.duration => Icons.timer_rounded,
      };
}

import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color surface;
  final Color panel;
  final Color elevated;
  final Color border;
  final Color divider;
  final Color accent;
  final Color accentSoft;
  final Color accentGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDim;
  final Color folderTint;
  final Color folderIcon;
  final Color errorRed;
  final Color errorBg;
  final Color progressBg;
  final Color progressFill;

  const AppThemeColors({
    required this.bg,
    required this.surface,
    required this.panel,
    required this.elevated,
    required this.border,
    required this.divider,
    required this.accent,
    required this.accentSoft,
    required this.accentGlow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDim,
    required this.folderTint,
    required this.folderIcon,
    required this.errorRed,
    required this.errorBg,
    required this.progressBg,
    required this.progressFill,
  });

  @override
  AppThemeColors copyWith({
    Color? bg, Color? surface, Color? panel, Color? elevated,
    Color? border, Color? divider, Color? accent, Color? accentSoft,
    Color? accentGlow, Color? textPrimary, Color? textSecondary, Color? textMuted,
    Color? textDim, Color? folderTint, Color? folderIcon, Color? errorRed,
    Color? errorBg, Color? progressBg, Color? progressFill,
  }) {
    return AppThemeColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      panel: panel ?? this.panel,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentGlow: accentGlow ?? this.accentGlow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
      folderTint: folderTint ?? this.folderTint,
      folderIcon: folderIcon ?? this.folderIcon,
      errorRed: errorRed ?? this.errorRed,
      errorBg: errorBg ?? this.errorBg,
      progressBg: progressBg ?? this.progressBg,
      progressFill: progressFill ?? this.progressFill,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      folderTint: Color.lerp(folderTint, other.folderTint, t)!,
      folderIcon: Color.lerp(folderIcon, other.folderIcon, t)!,
      errorRed: Color.lerp(errorRed, other.errorRed, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      progressBg: Color.lerp(progressBg, other.progressBg, t)!,
      progressFill: Color.lerp(progressFill, other.progressFill, t)!,
    );
  }
}

class AppThemeTextStyles extends ThemeExtension<AppThemeTextStyles> {
  final TextStyle label;
  final TextStyle labelAccent;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle caption;
  final TextStyle mono;

  const AppThemeTextStyles({
    required this.label,
    required this.labelAccent,
    required this.body,
    required this.bodySmall,
    required this.caption,
    required this.mono,
  });

  @override
  AppThemeTextStyles copyWith({
    TextStyle? label, TextStyle? labelAccent, TextStyle? body,
    TextStyle? bodySmall, TextStyle? caption, TextStyle? mono,
  }) {
    return AppThemeTextStyles(
      label: label ?? this.label,
      labelAccent: labelAccent ?? this.labelAccent,
      body: body ?? this.body,
      bodySmall: bodySmall ?? this.bodySmall,
      caption: caption ?? this.caption,
      mono: mono ?? this.mono,
    );
  }

  @override
  AppThemeTextStyles lerp(ThemeExtension<AppThemeTextStyles>? other, double t) {
    if (other is! AppThemeTextStyles) return this;
    return AppThemeTextStyles(
      label: TextStyle.lerp(label, other.label, t)!,
      labelAccent: TextStyle.lerp(labelAccent, other.labelAccent, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
    );
  }
}

abstract final class AppRadius {
  static const xs  = BorderRadius.all(Radius.circular(6));
  static const sm  = BorderRadius.all(Radius.circular(10));
  static const md  = BorderRadius.all(Radius.circular(14));
  static const lg  = BorderRadius.all(Radius.circular(20));
  static const xl  = BorderRadius.all(Radius.circular(28));
}

// Extension to get colors easily
extension ThemeContext on BuildContext {
  AppThemeColors get colors => Theme.of(this).extension<AppThemeColors>()!;
  AppThemeTextStyles get textStyles => Theme.of(this).extension<AppThemeTextStyles>()!;
}

final class AppTheme {
  AppTheme._();

  static const _darkColors = AppThemeColors(
    bg: Color(0xFF0C0C0E),
    surface: Color(0xFF141416),
    panel: Color(0xFF1C1C1F),
    elevated: Color(0xFF242428),
    border: Color(0xFF2C2C30),
    divider: Color(0xFF1F1F23),
    accent: Color(0xFFFF8C00),
    accentSoft: Color(0x33FF8C00),
    accentGlow: Color(0x44FF8C00),
    textPrimary: Color(0xFFF0F0F2),
    textSecondary: Color(0xFF8A8A92),
    textMuted: Color(0xFF4A4A52),
    textDim: Color(0xFF2E2E34),
    folderTint: Color(0xFF2A1020),
    folderIcon: Color(0xFFFF6B8E),
    errorRed: Color(0xFFFF5C5C),
    errorBg: Color(0xFF2A1010),
    progressBg: Color(0xFF252528),
    progressFill: Color(0xFFFF8C00),
  );

  static const _lightColors = AppThemeColors(
    bg: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    panel: Color(0xFFF0F0F3),
    elevated: Color(0xFFEAEAED),
    border: Color(0xFFDCDCE0),
    divider: Color(0xFFE5E5E8),
    accent: Color(0xFFE07000),
    accentSoft: Color(0x33E07000),
    accentGlow: Color(0x40E07000),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6B6B70),
    textMuted: Color(0xFF909096),
    textDim: Color(0xFFB0B0B6),
    folderTint: Color(0xFFFFE5EC),
    folderIcon: Color(0xFFE8436B),
    errorRed: Color(0xFFE53935),
    errorBg: Color(0xFFFFEBEE),
    progressBg: Color(0xFFE0E0E0),
    progressFill: Color(0xFFE07000),
  );

  static AppThemeTextStyles _createTextStyles(AppThemeColors c) => AppThemeTextStyles(
    label: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: c.textSecondary),
    labelAccent: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: c.accent),
    body: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.textPrimary, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.3),
    caption: TextStyle(fontSize: 11, color: c.textMuted, letterSpacing: 0.2),
    mono: TextStyle(fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, letterSpacing: 0.5),
  );

  // Built once — ThemeData is expensive. A getter rebuilds it on every access.
  static final ThemeData dark = _buildDark();
  static final ThemeData light = _buildLight();

  static ThemeData _buildDark() {
    final styles = _createTextStyles(_darkColors);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkColors.accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: _darkColors.accent,
        surface: _darkColors.surface,
        onSurface: _darkColors.textPrimary,
        surfaceContainerHighest: _darkColors.panel,
      ),
      extensions: [_darkColors, styles],
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColors.surface,
        foregroundColor: _darkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: _darkColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(
          color: _darkColors.textSecondary,
          size: 22,
        ),
      ),
      sliderTheme: SliderThemeData(
        thumbColor: _darkColors.accent,
        activeTrackColor: _darkColors.accent,
        inactiveTrackColor: _darkColors.textDim,
        overlayColor: _darkColors.accentSoft,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 3,
      ),
      dividerColor: _darkColors.divider,
      iconTheme: IconThemeData(color: _darkColors.textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColors.panel,
        hintStyle: TextStyle(color: _darkColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: _darkColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: _darkColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: _darkColors.accent, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        dragHandleColor: _darkColors.border,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        titleTextStyle: TextStyle(
            color: _darkColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: _darkColors.textSecondary, fontSize: 14),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkColors.accent,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColors.accent,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _darkColors.accent,
        linearTrackColor: _darkColors.progressBg,
      ),
    );
  }

  static ThemeData _buildLight() {
    final styles = _createTextStyles(_lightColors);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: _lightColors.accent,
        surface: _lightColors.surface,
        onSurface: _lightColors.textPrimary,
        surfaceContainerHighest: _lightColors.panel,
      ),
      extensions: [_lightColors, styles],
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColors.surface,
        foregroundColor: _lightColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: _lightColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(
          color: _lightColors.textSecondary,
          size: 22,
        ),
      ),
      sliderTheme: SliderThemeData(
        thumbColor: _lightColors.accent,
        activeTrackColor: _lightColors.accent,
        inactiveTrackColor: _lightColors.textDim,
        overlayColor: _lightColors.accentSoft,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 3,
      ),
      dividerColor: _lightColors.divider,
      iconTheme: IconThemeData(color: _lightColors.textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColors.panel,
        hintStyle: TextStyle(color: _lightColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: _lightColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: _lightColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: _lightColors.accent, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _lightColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        dragHandleColor: _lightColors.border,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        titleTextStyle: TextStyle(
            color: _lightColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: _lightColors.textSecondary, fontSize: 14),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightColors.accent,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColors.accent,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _lightColors.accent,
        linearTrackColor: _lightColors.progressBg,
      ),
    );
  }
}

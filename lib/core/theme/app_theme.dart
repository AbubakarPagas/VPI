import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// VPI Secure — MaterialApp theme configuration.
///
/// Usage:
///   MaterialApp(theme: AppTheme.dark)
///
/// All component sub-themes are configured here so individual screens
/// never need to override Material defaults manually.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // ── Brand ──────────────────────────────────────────────────────────────
      primary: AppColors.primary,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primaryDim,
      onPrimaryContainer: AppColors.blue200,
      // ── Secondary (trusted / verified — green) ─────────────────────────────
      secondary: AppColors.trusted,
      onSecondary: AppColors.bg0,
      secondaryContainer: Color(0xFF003D1A),
      onSecondaryContainer: AppColors.greenA400,
      // ── Tertiary (warning — amber) ─────────────────────────────────────────
      tertiary: AppColors.warning,
      onTertiary: AppColors.bg0,
      tertiaryContainer: Color(0xFF3D2500),
      onTertiaryContainer: AppColors.amberA400,
      // ── Error (danger — red) ───────────────────────────────────────────────
      error: AppColors.danger,
      onError: AppColors.textPrimary,
      errorContainer: Color(0xFF3D0011),
      onErrorContainer: AppColors.redA400,
      // ── Surfaces ───────────────────────────────────────────────────────────
      surface: AppColors.bg1,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.bg3,
      onSurfaceVariant: AppColors.textSecondary,
      // ── Outline ────────────────────────────────────────────────────────────
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      // ── Misc ───────────────────────────────────────────────────────────────
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: AppColors.blue200,
      onInverseSurface: AppColors.bg0,
      inversePrimary: AppColors.primaryDim,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg0,
    );

    return base.copyWith(
      // ── System UI ──────────────────────────────────────────────────────────
      appBarTheme: _appBarTheme,

      // ── Typography ─────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),

      // ── Buttons ────────────────────────────────────────────────────────────
      elevatedButtonTheme: _elevatedButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: _inputDecorationTheme,

      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: _cardTheme,

      // ── Chips ──────────────────────────────────────────────────────────────
      chipTheme: _chipTheme,

      // ── Bottom sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: _bottomSheetTheme,

      // ── Navigation bar ─────────────────────────────────────────────────────
      navigationBarTheme: _navigationBarTheme,

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 1,
        thickness: 1,
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: _dialogTheme,

      // ── Snack bar ──────────────────────────────────────────────────────────
      snackBarTheme: _snackBarTheme,

      // ── Progress indicator ─────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.bg3,
        circularTrackColor: AppColors.bg3,
      ),

      // ── Switch / checkbox / radio ──────────────────────────────────────────
      switchTheme: _switchTheme,
      checkboxTheme: _checkboxTheme,

      // ── List tile ──────────────────────────────────────────────────────────
      listTileTheme: _listTileTheme,

      // ── Icon ───────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.primaryBright, size: 22),

      // ── Page transitions ───────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ── Visual density ─────────────────────────────────────────────────────
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg0,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Rajdhani',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 1.2,
    ),
    iconTheme: IconThemeData(color: AppColors.primaryBright, size: 22),
    actionsIconTheme: IconThemeData(color: AppColors.primaryBright, size: 22),
  );

  // ── Text theme ────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.rajdhani(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.rajdhani(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.rajdhani(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      headlineLarge: GoogleFonts.rajdhani(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
      ),
      headlineMedium: GoogleFonts.rajdhani(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.0,
      ),
      headlineSmall: GoogleFonts.rajdhani(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
      ),
      titleLarge: GoogleFonts.rajdhani(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.6,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.65,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.55,
      ),
      labelLarge: GoogleFonts.rajdhani(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Elevated button ───────────────────────────────────────────────────────

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.bg3,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shadowColor: AppColors.blueGlow40,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      );

  // ── Filled button (primary action) ───────────────────────────────────────

  static final FilledButtonThemeData _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textPrimary,
      disabledBackgroundColor: AppColors.bg3,
      disabledForegroundColor: AppColors.textDisabled,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      minimumSize: const Size(120, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
  );

  // ── Outlined button (secondary action) ───────────────────────────────────

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBright,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(100, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
      );

  // ── Text button ───────────────────────────────────────────────────────────

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryBright,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    ),
  );

  // ── Input decoration ──────────────────────────────────────────────────────

  static final InputDecorationTheme
  _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bg2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    hintStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textMuted,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
    floatingLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      color: AppColors.primaryBright,
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.danger, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
    errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.danger),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
  );

  // ── Card ──────────────────────────────────────────────────────────────────

  static final CardThemeData _cardTheme = CardThemeData(
    color: AppColors.bg2,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  // ── Chip ──────────────────────────────────────────────────────────────────

  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: AppColors.bg2,
    selectedColor: AppColors.primaryDim,
    disabledColor: AppColors.bg3,
    deleteIconColor: AppColors.textMuted,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    secondaryLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.primaryBright,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: const BorderSide(color: AppColors.outline),
    ),
  );

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.bg2,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    dragHandleColor: AppColors.outlineLight,
    dragHandleSize: Size(40, 4),
    showDragHandle: true,
  );

  // ── Navigation bar ────────────────────────────────────────────────────────

  static final NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
        backgroundColor: AppColors.bg2,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.blueGlow20,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primaryBright : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.primaryBright : AppColors.textMuted,
            size: 22,
          );
        }),
      );

  // ── Dialog ────────────────────────────────────────────────────────────────

  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.bg2,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.outline, width: 1),
    ),
    titleTextStyle: GoogleFonts.rajdhani(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0.8,
    ),
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textSecondary,
      height: 1.6,
    ),
  );

  // ── Snack bar ─────────────────────────────────────────────────────────────

  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.bg3,
    contentTextStyle: GoogleFonts.inter(
      fontSize: 13,
      color: AppColors.textPrimary,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.outline),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    actionTextColor: AppColors.primaryBright,
  );

  // ── Switch ────────────────────────────────────────────────────────────────

  static final SwitchThemeData _switchTheme = SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primary;
      return AppColors.bg3;
    }),
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.textPrimary;
      return AppColors.textMuted;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.transparent;
      return AppColors.outline;
    }),
  );

  // ── Checkbox ──────────────────────────────────────────────────────────────

  static final CheckboxThemeData _checkboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primary;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.textPrimary),
    side: const BorderSide(color: AppColors.outline, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );

  // ── List tile ─────────────────────────────────────────────────────────────

  static final ListTileThemeData _listTileTheme = ListTileThemeData(
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.blueGlow10,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    titleTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    subtitleTextStyle: GoogleFonts.inter(
      fontSize: 12,
      color: AppColors.textMuted,
    ),
    leadingAndTrailingTextStyle: GoogleFonts.inter(
      fontSize: 12,
      color: AppColors.textMuted,
    ),
    iconColor: AppColors.primaryBright,
    selectedColor: AppColors.primaryBright,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GenPay v3 palette — clean fintech minimalism (Linear / Stripe / Vercel feel).
///
/// One disciplined family of zinc neutrals + a single restrained indigo accent.
/// No gradients, no decorative colors, no "warning yellow" amber. Money numbers
/// stay neutral — colored only when functional (red for debit, green for credit).
///
/// The legacy `electricBlue`/`neonGreen`/`softRed`/`darkCard`/`darkBorder` names
/// are kept as aliases so existing screens compile and pick up the new palette
/// without manual edits. For proper light/dark behavior inside a screen, prefer
/// `Theme.of(context).colorScheme.*`.
class AppColors {
  // ─── Brand (theme-independent) ───────────────────────────────────────────
  static const Color ink         = Color(0xFF09090B); // near-black (primary CTA)
  static const Color paper       = Color(0xFFFAFAFA); // near-white (on-ink)
  static const Color accent      = Color(0xFF6366F1); // indigo — link/active
  static const Color accentSoft  = Color(0xFFEEF2FF); // tinted bg for accent
  static const Color credit      = Color(0xFF16A34A); // green-600 — money in
  static const Color debit       = Color(0xFFDC2626); // red-600 — money out
  static const Color amber       = Color(0xFFCA8A04); // muted gold — rare warnings only
  static const Color violet      = Color(0xFF8B5CF6); // tertiary, used sparingly

  // ─── Light surfaces ──────────────────────────────────────────────────────
  static const Color lightBg         = Color(0xFFF4F4F5); // zinc-100 — page bg
  static const Color lightSurface    = Color(0xFFFFFFFF); // card
  static const Color lightSurfaceHi  = Color(0xFFFAFAFA); // input fill
  static const Color lightBorder     = Color(0xFFE4E4E7); // zinc-200
  static const Color lightMuted      = Color(0xFF71717A); // zinc-500
  static const Color lightOnSurface  = Color(0xFF09090B); // zinc-950 — text

  // ─── Dark surfaces ───────────────────────────────────────────────────────
  static const Color darkBg          = Color(0xFF09090B); // zinc-950 page bg
  static const Color darkSurface     = Color(0xFF18181B); // zinc-900 card
  static const Color darkSurfaceHi   = Color(0xFF27272A); // zinc-800 input
  static const Color darkBorder      = Color(0xFF27272A); // zinc-800 subtle
  static const Color darkMuted       = Color(0xFFA1A1AA); // zinc-400
  static const Color darkOnSurface   = Color(0xFFFAFAFA); // zinc-50 text

  // ─── Legacy aliases ──────────────────────────────────────────────────────
  static const Color black         = darkBg;
  static const Color white         = darkOnSurface;
  static const Color electricBlue  = accent;
  static const Color neonGreen     = credit;
  static const Color softRed       = debit;
  static const Color warningAmber  = amber;
  static const Color darkCard      = darkSurface;
  static const Color mutedText     = darkMuted;
  static const Color darkGrey      = darkSurface;
  static const Color mediumGrey    = darkBorder;
  // darkBorder, darkSurface, amber are defined above with the new values.
}

/// 4-dp spacing rhythm.
class AppSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double xxxl = 48;
}

/// Corner radius scale — restrained.
class AppRadius {
  static const double pill   = 999;
  static const double button = 10;
  static const double card   = 14;
  static const double sheet  = 24;
  static const double chip   = 999;
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme  => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness b) {
    final dark = b == Brightness.dark;

    final bg         = dark ? AppColors.darkBg        : AppColors.lightBg;
    final surface    = dark ? AppColors.darkSurface   : AppColors.lightSurface;
    final surfaceHi  = dark ? AppColors.darkSurfaceHi : AppColors.lightSurfaceHi;
    final border     = dark ? AppColors.darkBorder    : AppColors.lightBorder;
    final onSurface  = dark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted      = dark ? AppColors.darkMuted     : AppColors.lightMuted;

    // Primary CTA: black-on-white in light, white-on-black in dark.
    final primary       = dark ? AppColors.paper : AppColors.ink;
    final onPrimary     = dark ? AppColors.ink   : AppColors.paper;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: b,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: surfaceHi,
        onPrimaryContainer: onSurface,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: dark
            ? AppColors.accent.withValues(alpha: 0.15)
            : AppColors.accentSoft,
        onSecondaryContainer: dark ? AppColors.accent : AppColors.accent,
        tertiary: AppColors.violet,
        onTertiary: Colors.white,
        error: AppColors.debit,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceHi,
        surfaceContainerHigh: surfaceHi,
        outline: border,
        outlineVariant: border,
      ),
      textTheme: _buildTextTheme(onSurface, muted),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: onSurface, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: onSurface, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.debit),
        ),
        labelStyle: GoogleFonts.inter(color: muted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: muted, fontSize: 14),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: muted.withValues(alpha: 0.2),
          disabledForegroundColor: muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onSurface,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: onSurface,
        unselectedItemColor: muted,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: onSurface, size: 22),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHi,
        selectedColor: onSurface,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: onSurface,
        linearTrackColor: border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? onPrimary : muted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : surfaceHi),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? AppColors.lightSurface : AppColors.darkSurface,
        contentTextStyle: GoogleFonts.inter(
          color: dark ? AppColors.lightOnSurface : AppColors.darkOnSurface,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w600, color: onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14, color: onSurface, height: 1.5,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: onSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13, color: muted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onSurface,
        unselectedLabelColor: muted,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: onSurface, width: 2),
          insets: EdgeInsets.zero,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color onSurface, Color muted) {
    final f = GoogleFonts.inter;
    final mono = GoogleFonts.jetBrainsMono;

    return TextTheme(
      // Display — hero amounts. Tight, dense Inter. No JetBrains Mono on big numbers.
      displayLarge: f(
        fontSize: 56, fontWeight: FontWeight.w700, color: onSurface,
        height: 1.0, letterSpacing: -2.0,
      ),
      displayMedium: f(
        fontSize: 44, fontWeight: FontWeight.w700, color: onSurface,
        height: 1.05, letterSpacing: -1.5,
      ),
      displaySmall: f(
        fontSize: 32, fontWeight: FontWeight.w700, color: onSurface,
        height: 1.1, letterSpacing: -1.0,
      ),
      // Headlines
      headlineLarge: f(
        fontSize: 28, fontWeight: FontWeight.w700, color: onSurface,
        height: 1.2, letterSpacing: -0.6,
      ),
      headlineMedium: f(
        fontSize: 22, fontWeight: FontWeight.w700, color: onSurface,
        height: 1.25, letterSpacing: -0.4,
      ),
      headlineSmall: f(
        fontSize: 18, fontWeight: FontWeight.w600, color: onSurface,
        height: 1.3, letterSpacing: -0.2,
      ),
      // Titles
      titleLarge: f(
        fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, height: 1.35,
      ),
      titleMedium: f(
        fontSize: 15, fontWeight: FontWeight.w600, color: onSurface, height: 1.4,
      ),
      titleSmall: f(
        fontSize: 13, fontWeight: FontWeight.w600, color: onSurface, height: 1.4,
      ),
      // Body
      bodyLarge: f(
        fontSize: 15, fontWeight: FontWeight.w400, color: onSurface, height: 1.5,
      ),
      bodyMedium: f(
        fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.5,
      ),
      bodySmall: f(
        fontSize: 12, fontWeight: FontWeight.w400, color: muted, height: 1.5,
      ),
      // Labels — small caps + mono only for tiny numeric tags.
      labelLarge: f(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: onSurface, letterSpacing: 0,
      ),
      labelMedium: f(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: muted, letterSpacing: 0,
      ),
      labelSmall: mono(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: muted, letterSpacing: 0.8,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color Tokens ──────────────────────────────────────────────────────────────

class AtlasColors {
  static const Color canvas     = Color(0xFFF5F5F5);
  static const Color paper      = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFAFA);
  static const Color ink        = Color(0xFF0A0A0A);
  static const Color inkSoft    = Color(0xFF171717);
  static const Color midGray    = Color(0xFF737373);
  static const Color hairline   = Color(0xFFE5E5E5);
  static const Color ember      = Color(0xFFE7000B);
}

// ── Spacing Tokens ────────────────────────────────────────────────────────────

class AtlasSpacing {
  static const double s4  = 4;
  static const double s8  = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s48 = 48;
}

// ── Radius Tokens ─────────────────────────────────────────────────────────────

class AtlasRadius {
  static const double card   = 24;
  static const double button = 18;
  static const double input  = 18;
  static const double badge  = 18;
  static const double nested = 10;
  static const double small  = 6;

  static BorderRadius get cardBR   => BorderRadius.circular(card);
  static BorderRadius get buttonBR => BorderRadius.circular(button);
  static BorderRadius get inputBR  => BorderRadius.circular(input);
  static BorderRadius get badgeBR  => BorderRadius.circular(badge);
  static BorderRadius get nestedBR => BorderRadius.circular(nested);
  static BorderRadius get smallBR  => BorderRadius.circular(small);
}

// ── Shadow Tokens ─────────────────────────────────────────────────────────────

class AtlasShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF171717).withOpacity(0.05),
          blurRadius: 0,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 2,
          offset: const Offset(0, 1),
          spreadRadius: -1,
        ),
      ];
}

// ── Text Style Tokens ─────────────────────────────────────────────────────────

class AtlasTextStyles {
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        letterSpacing: -2.4,
        height: 1.1,
        color: AtlasColors.ink,
      );

  static TextStyle get headingLg => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.9,
        height: 1.11,
        color: AtlasColors.ink,
      );

  static TextStyle get heading => GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.75,
        height: 1.2,
        color: AtlasColors.ink,
      );

  static TextStyle get headingSm => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.33,
        color: AtlasColors.ink,
      );

  static TextStyle get subheading => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.56,
        color: AtlasColors.ink,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AtlasColors.ink,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: AtlasColors.ink,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        color: AtlasColors.ink,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.6,
        height: 1.33,
        color: AtlasColors.midGray,
      );

  static TextStyle get captionMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        height: 1.33,
        color: AtlasColors.midGray,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AtlasColors.ink,
      );
}

// ── Theme ─────────────────────────────────────────────────────────────────────

class AtlasTheme {
  static ThemeData get light {
    final base = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AtlasColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AtlasColors.inkSoft,
        onPrimary: AtlasColors.paper,
        secondary: AtlasColors.midGray,
        onSecondary: AtlasColors.paper,
        surface: AtlasColors.paper,
        onSurface: AtlasColors.ink,
        surfaceContainerHighest: AtlasColors.surfaceAlt,
        outline: AtlasColors.hairline,
        outlineVariant: AtlasColors.hairline,
        error: AtlasColors.ember,
        onError: AtlasColors.paper,
      ),
      textTheme: base.copyWith(
        displayLarge: AtlasTextStyles.display,
        headlineLarge: AtlasTextStyles.headingLg,
        headlineMedium: AtlasTextStyles.heading,
        headlineSmall: AtlasTextStyles.headingSm,
        titleLarge: AtlasTextStyles.subheading,
        titleMedium: AtlasTextStyles.bodyLg,
        titleSmall: AtlasTextStyles.bodyMedium,
        bodyLarge: AtlasTextStyles.bodyLg,
        bodyMedium: AtlasTextStyles.body,
        bodySmall: AtlasTextStyles.caption,
        labelLarge: AtlasTextStyles.label,
        labelMedium: AtlasTextStyles.captionMedium,
        labelSmall: AtlasTextStyles.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AtlasColors.paper,
        foregroundColor: AtlasColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AtlasColors.ink,
        ),
        iconTheme: const IconThemeData(color: AtlasColors.ink, size: 20),
        actionsIconTheme: const IconThemeData(color: AtlasColors.midGray, size: 20),
        shape: const Border(bottom: BorderSide(color: AtlasColors.hairline)),
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AtlasRadius.cardBR,
          side: const BorderSide(color: AtlasColors.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.canvas,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AtlasColors.midGray),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AtlasColors.midGray),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: const BorderSide(color: AtlasColors.hairline),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: const BorderSide(color: AtlasColors.ember),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: const BorderSide(color: AtlasColors.ember),
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AtlasColors.ink,
          foregroundColor: AtlasColors.paper,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AtlasColors.ink,
          side: const BorderSide(color: AtlasColors.hairline),
          shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AtlasColors.ink,
          shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.ink,
          foregroundColor: AtlasColors.paper,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AtlasColors.canvas,
        selectedColor: AtlasColors.inkSoft,
        side: const BorderSide(color: AtlasColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.badgeBR),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      dividerTheme: const DividerThemeData(
        color: AtlasColors.hairline,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: AtlasTextStyles.body,
        subtitleTextStyle: AtlasTextStyles.caption,
        iconColor: AtlasColors.midGray,
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.nestedBR),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AtlasColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AtlasColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.cardBR),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AtlasColors.inkSoft,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AtlasColors.paper),
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.nestedBR),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AtlasColors.ink,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AtlasColors.ink,
        foregroundColor: AtlasColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AtlasColors.paper : AtlasColors.midGray),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AtlasColors.ink : AtlasColors.hairline),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AtlasColors.ink : Colors.transparent),
        checkColor: WidgetStateProperty.all(AtlasColors.paper),
        side: const BorderSide(color: AtlasColors.hairline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AtlasColors.ink,
        inactiveTrackColor: AtlasColors.hairline,
        thumbColor: AtlasColors.ink,
        overlayColor: AtlasColors.ink.withOpacity(0.08),
        trackHeight: 2,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AtlasColors.ink,
        unselectedLabelColor: AtlasColors.midGray,
        labelStyle: AtlasTextStyles.bodyMedium,
        unselectedLabelStyle: AtlasTextStyles.body,
        indicatorColor: AtlasColors.ink,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AtlasColors.hairline,
      ),
    );
  }

  static ThemeData get dark {
    const bgDark        = Color(0xFF0A0A0A);
    const surfaceDark   = Color(0xFF141414);
    const surfaceAltDk  = Color(0xFF1A1A1A);
    const inkLight      = Color(0xFFFAFAFA);
    const inkSoftLight  = Color(0xFFE5E5E5);
    const midGrayDark   = Color(0xFF737373);
    const hairlineDark  = Color(0xFF262626);

    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: inkSoftLight,
        onPrimary: bgDark,
        secondary: midGrayDark,
        onSecondary: bgDark,
        surface: surfaceDark,
        onSurface: inkLight,
        surfaceContainerHighest: surfaceAltDk,
        outline: hairlineDark,
        outlineVariant: hairlineDark,
        error: AtlasColors.ember,
        onError: inkLight,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: inkLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: inkLight,
        ),
        iconTheme: const IconThemeData(color: inkLight, size: 20),
        actionsIconTheme: const IconThemeData(color: midGrayDark, size: 20),
        shape: const Border(bottom: BorderSide(color: hairlineDark)),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AtlasRadius.cardBR,
          side: const BorderSide(color: hairlineDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAltDk,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: midGrayDark),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: midGrayDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AtlasRadius.inputBR,
          borderSide: const BorderSide(color: hairlineDark),
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: inkSoftLight,
          foregroundColor: bgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkLight,
          side: const BorderSide(color: hairlineDark),
          shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: hairlineDark,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.cardBR),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inkSoftLight,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: bgDark),
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.nestedBR),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: inkSoftLight,
        foregroundColor: bgDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.buttonBR),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAltDk,
        selectedColor: inkSoftLight,
        side: const BorderSide(color: hairlineDark),
        shape: RoundedRectangleBorder(borderRadius: AtlasRadius.badgeBR),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: inkSoftLight,
      ),
    );
  }
}

// ── Mood / Importance tokens (used by existing logic) ─────────────────────────

const moodColors = {
  'happy':   Color(0xFF16A34A),
  'excited': Color(0xFFD97706),
  'neutral': Color(0xFF737373),
  'stressed':Color(0xFFDC2626),
  'sad':     Color(0xFF2563EB),
  'angry':   Color(0xFFDC2626),
  'anxious': Color(0xFFD97706),
  'calm':    Color(0xFF0891B2),
};

const moodEmojis = {
  'happy':   '😊',
  'excited': '🤩',
  'neutral': '😐',
  'stressed':'😰',
  'sad':     '😢',
  'angry':   '😠',
  'anxious': '😟',
  'calm':    '😌',
};

const importanceColors = {
  1: Color(0xFF737373),
  2: Color(0xFF16A34A),
  3: Color(0xFF2563EB),
  4: Color(0xFFD97706),
  5: Color(0xFFDC2626),
};

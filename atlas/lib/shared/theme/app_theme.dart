import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtlasTheme {
  static const _seed = Color(0xFF6750A4);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

// Mood colors
const moodColors = {
  'happy': Color(0xFF4CAF50),
  'excited': Color(0xFFFF9800),
  'neutral': Color(0xFF9E9E9E),
  'stressed': Color(0xFFFF5722),
  'sad': Color(0xFF2196F3),
  'angry': Color(0xFFF44336),
  'anxious': Color(0xFFFF9800),
  'calm': Color(0xFF00BCD4),
};

const moodEmojis = {
  'happy': '😊',
  'excited': '🤩',
  'neutral': '😐',
  'stressed': '😰',
  'sad': '😢',
  'angry': '😠',
  'anxious': '😟',
  'calm': '😌',
};

const importanceColors = {
  1: Color(0xFF9E9E9E),
  2: Color(0xFF4CAF50),
  3: Color(0xFF2196F3),
  4: Color(0xFFFF9800),
  5: Color(0xFFF44336),
};

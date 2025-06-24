import 'package:flutter/material.dart';

class AppTheme {
  // Pink feminine color palette
  static const Color primaryColor = Color(0xFFE91E63); // Pink
  static const Color secondaryColor = Color(0xFFF06292); // Light Pink
  static const Color accentColor = Color(0xFFAD1457); // Dark Pink
  static const Color errorColor = Color(0xFFF06292);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  // Priority colors - pink themed
  static const Color lowPriority = Color(0xFFC8E6C9); // Light Green
  static const Color mediumPriority = Color(0xFFFFE0B2); // Light Orange
  static const Color highPriority = Color(0xFFFFCDD2); // Light Red

  // Additional pink shades
  static const Color lightPink = Color(0xFFFCE4EC);
  static const Color mediumPink = Color(0xFFF8BBD9);
  static const Color darkPink = Color(0xFF880E4F);
  static const Color softPink = Color(0xFFF48FB1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFFFFFBFF),
        background: lightPink,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkPink,
        onBackground: darkPink,
        onError: Colors.white,
        tertiary: softPink,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.white,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: mediumPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: softPink),
        ),
        filled: true,
        fillColor: lightPink,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: primaryColor),
        hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightPink,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Tab bar theme
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFFFB3C6),
        indicatorColor: Colors.white,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: lightPink,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: primaryColor, size: 24),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: softPink,
        secondary: mediumPink,
        surface: Color(0xFF1A1A1A),
        background: Color(0xFF121212),
        error: errorColor,
        onPrimary: darkPink,
        onSecondary: darkPink,
        onSurface: lightPink,
        onBackground: lightPink,
        onError: Colors.white,
        tertiary: primaryColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkPink,
        foregroundColor: lightPink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: lightPink,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        color: const Color(0xFF2A2A2A),
        shadowColor: softPink.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softPink,
          foregroundColor: darkPink,
          elevation: 3,
          shadowColor: softPink.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: softPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: softPink, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: softPink),
        hintStyle: TextStyle(color: softPink.withOpacity(0.6)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: softPink,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: lightPink,
        unselectedLabelColor: softPink.withOpacity(0.7),
        indicatorColor: lightPink,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),

      iconTheme: const IconThemeData(color: softPink, size: 24),
    );
  }

  // Utility methods for colors
  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return highPriority;
      case 'medium':
        return mediumPriority;
      case 'low':
        return lowPriority;
      default:
        return mediumPriority;
    }
  }

  // Gradient decorations for special UI elements
  static BoxDecoration get pinkGradientDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [primaryColor, softPink],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration get lightPinkGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [lightPink, mediumPink.withOpacity(0.3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(15),
  );
}

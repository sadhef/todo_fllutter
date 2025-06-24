import 'package:flutter/material.dart';

class AppTheme {
  // Primary color palette - improved for better contrast
  static const Color primaryColor = Color(0xFFE91E63); // Pink
  static const Color secondaryColor = Color(0xFFF06292); // Light Pink
  static const Color accentColor = Color(0xFFAD1457); // Dark Pink
  static const Color errorColor = Color(0xFFD32F2F); // Better red for errors
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  // Priority colors - improved visibility
  static const Color lowPriority = Color(0xFF4CAF50); // Green
  static const Color mediumPriority = Color(0xFFFF9800); // Orange
  static const Color highPriority = Color(0xFFE91E63); // Pink/Red

  // Additional color shades
  static const Color lightPink = Color(0xFFFCE4EC);
  static const Color mediumPink = Color(0xFFF8BBD9);
  static const Color darkPink = Color(0xFF880E4F);
  static const Color softPink = Color(0xFFF48FB1);

  // Text colors for better readability
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color lightText = Color(0xFFFFFFFF);
  static const Color mediumText = Color(0xFF666666);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFFFFFBFF),
        background: Color(0xFFFAFAFA),
        error: errorColor,
        onPrimary: lightText,
        onSecondary: lightText,
        onSurface: darkText,
        onBackground: darkText,
        onError: lightText,
        tertiary: softPink,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: lightText,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: lightText),
      ),

      // Text theme with better contrast
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: darkText, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: TextStyle(
            color: darkText, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: TextStyle(
            color: darkText, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: darkText, fontSize: 16),
        bodyMedium: TextStyle(color: darkText, fontSize: 14),
        bodySmall: TextStyle(color: mediumText, fontSize: 12),
        labelLarge: TextStyle(color: darkText, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: mediumText, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: mediumText, fontWeight: FontWeight.w500),
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
          foregroundColor: lightText,
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
        foregroundColor: lightText,
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
        labelStyle:
            const TextStyle(color: darkText, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: mediumText.withOpacity(0.7)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightPink,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Tab bar theme
      tabBarTheme: const TabBarThemeData(
        labelColor: lightText,
        unselectedLabelColor: Color(0xFFFFB3C6),
        indicatorColor: lightText,
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
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: softPink,
        secondary: mediumPink,
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: errorColor,
        onPrimary: darkText,
        onSecondary: darkText,
        onSurface: Color(0xFFE1E1E1),
        onBackground: Color(0xFFE1E1E1),
        onError: lightText,
        tertiary: primaryColor,
      ),

      // Text theme with proper contrast for dark mode
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: Color(0xFFE1E1E1), fontWeight: FontWeight.bold),
        displayMedium:
            TextStyle(color: Color(0xFFE1E1E1), fontWeight: FontWeight.bold),
        displaySmall:
            TextStyle(color: Color(0xFFE1E1E1), fontWeight: FontWeight.bold),
        headlineLarge:
            TextStyle(color: Color(0xFFE1E1E1), fontWeight: FontWeight.w600),
        headlineMedium:
            TextStyle(color: Color(0xFFE1E1E1), fontWeight: FontWeight.w600),
        headlineSmall:
            TextStyle(color: Color(0xFFE1E1E1), fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: Color(0xFFE1E1E1),
            fontWeight: FontWeight.w600,
            fontSize: 20),
        titleMedium: TextStyle(
            color: Color(0xFFE1E1E1),
            fontWeight: FontWeight.w500,
            fontSize: 16),
        titleSmall: TextStyle(
            color: Color(0xFFE1E1E1),
            fontWeight: FontWeight.w500,
            fontSize: 14),
        bodyLarge: TextStyle(color: Color(0xFFE1E1E1), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFE1E1E1), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
        labelLarge:
            TextStyle(color: Color(0xFFE1E1E1), fontWeight: FontWeight.w500),
        labelMedium:
            TextStyle(color: Color(0xFFB0B0B0), fontWeight: FontWeight.w500),
        labelSmall:
            TextStyle(color: Color(0xFFB0B0B0), fontWeight: FontWeight.w500),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE1E1E1),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE1E1E1),
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFFE1E1E1)),
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
          foregroundColor: darkText,
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
        foregroundColor: lightText,
        elevation: 6,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: softPink, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
            color: Color(0xFFE1E1E1), fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: softPink,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE1E1E1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFFE1E1E1),
        unselectedLabelColor: Color(0xFFB0B0B0),
        indicatorColor: softPink,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: softPink,
        linearTrackColor: Color(0xFF444444),
      ),

      iconTheme: const IconThemeData(color: Color(0xFFE1E1E1), size: 24),
    );
  }

  // Helper method to get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
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

  // Helper method to get priority color with opacity
  static Color getPriorityColorWithOpacity(String priority, double opacity) {
    return getPriorityColor(priority).withOpacity(opacity);
  }

  // Pink gradient decoration for backward compatibility
  static BoxDecoration get pinkGradientDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor,
          accentColor,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Sleek, refined theme system for CodeNyx hackathon platform
/// Minimalist aesthetic with precision spacing and typography
class AppTheme {
  // ============ Color Palette ============
  // Refined dark mode with subtle accents
  static const Color primaryBackground = Color(0xFF0A0E27); // Deep navy
  static const Color secondaryBackground = Color(
    0xFF111B3F,
  ); // Slightly lighter navy
  static const Color surfaceLight = Color(0xFF1A2847); // Surface highlights
  static const Color accentPrimary = Color(0xFF00D9FF); // Cyan accent
  static const Color accentSecondary = Color(0xFF6366F1); // Indigo
  static const Color accentTertiary = Color(0xFF8B5CF6); // Purple
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFF94A3B8); // Slate gray
  static const Color textTertiary = Color(0xFF64748B); // Darker slate
  static const Color borderColor = Color(0xFF1E293B); // Subtle borders
  static const Color dividerColor = Color(0xFF0F172A); // Very subtle dividers

  // ============ Gradients ============
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBackground, secondaryBackground, Color(0xFF0D1628)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0x14FFFFFF), // 8% white opacity
      Color(0x08FFFFFF), // 3% white opacity
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPrimary, accentSecondary],
  );

  // ============ Text Styles ============
  /// Hackathon name display
  static const TextStyle hackathonTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: accentPrimary,
    letterSpacing: 0.5,
  );

  /// Page titles
  static const TextStyle pageTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Section headers
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  /// Card titles
  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  /// Card body text
  static const TextStyle cardBody = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.3,
    height: 1.5,
  );

  /// Meta information (small text)
  static const TextStyle metaText = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    letterSpacing: 0.2,
  );

  /// Navigation labels
  static const TextStyle navLabel = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // ============ Border Radius ============
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  // ============ Spacing ============
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  // ============ Helper Methods ============
  static BoxDecoration cardDecoration({
    bool elevated = false,
    double borderRadius = radiusMedium,
  }) {
    return BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration accentCardDecoration({
    double borderRadius = radiusMedium,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          accentPrimary.withOpacity(0.12),
          accentSecondary.withOpacity(0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: accentPrimary.withOpacity(0.3), width: 1.5),
    );
  }

  static BoxDecoration navBarDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.3),
          Colors.black.withOpacity(0.7),
        ],
      ),
    );
  }

  static BoxDecoration bannerDecoration({bool isTimer = false}) {
    return BoxDecoration(
      gradient: isTimer
          ? LinearGradient(
              colors: [
                accentPrimary.withOpacity(0.15),
                accentSecondary.withOpacity(0.1),
              ],
            )
          : cardGradient,
      borderRadius: BorderRadius.circular(radiusLarge),
      border: Border.all(
        color: isTimer ? accentPrimary.withOpacity(0.3) : borderColor,
        width: 1,
      ),
    );
  }
}

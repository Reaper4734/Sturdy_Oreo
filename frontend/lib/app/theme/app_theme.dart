import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Hallmark Modern-Minimal Monochrome Dark Palette (PURPLE STRICTLY FORBIDDEN)
class AppColors {
  static const Color bgCanvas = Color(0xFF0D0D0D);       // Pitch dark matte background
  static const Color bgActivityBar = Color(0xFF141414);  // Left activity rail
  static const Color bgSidebar = Color(0xFF171717);      // Collapsible sidebar
  static const Color bgSurface = Color(0xFF212121);      // Dark input pill & user bubble
  static const Color bgSecondary = Color(0xFF262626);    // Slightly lighter than surface
  static const Color bgElevated = Color(0xFF2F2F2F);     // Hover & active chip surface
  static const Color borderSubtle = Color(0xFF333333);   // Crisp hairline border
  static const Color borderActive = Color(0xFFFFFFFF);   // High-contrast active white border

  static const Color fgPrimary = Color(0xFFECECEC);      // High-contrast text
  static const Color fgSecondary = Color(0xFF878787);    // Muted captions
  static const Color fgTertiary = Color(0xFF6B6B6B);     // Even more muted
  static const Color fgAccent = Color(0xFF67E8F9);       // Electric Cyan for code/links

  static const Color accentPrimary = Color(0xFFFFFFFF);  // Pure white primary accent
  static const Color accentEmerald = Color(0xFF10B981);  // Success / Quest completion
  static const Color accentAmber = Color(0xFFF59E0B);    // Warning / Watchdog alerts
  static const Color accentWarning = Color(0xFFF59E0B);  // Warning alias
  static const Color accentRose = Color(0xFFEF4444);     // Danger / Error states
  static const Color accentDestructive = Color(0xFFEF4444); // Danger alias
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgCanvas,
      cardColor: AppColors.bgSurface,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgSurface,
        primary: AppColors.accentPrimary,
        secondary: AppColors.fgAccent,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
        displayMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.fgPrimary),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.fgPrimary, height: 1.5),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.fgSecondary, height: 1.4),
        labelLarge: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.fgAccent),
      ),
    );
  }
}

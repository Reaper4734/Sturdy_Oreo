import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// OREO DESIGN TOKENS — ENHANCED SEMANTIC SYSTEM (AFFiNE INSPIRED)
/// ============================================================================

/// Static dark tokens fallback & dynamic theme-aware resolver
class AppColors {
  // Static dark fallback tokens (preserving backwards compatibility)
  static const Color bgCanvas = Color(0xFF0D0D0D);       // Deep pitch matte canvas
  static const Color bgBase = Color(0xFF121212);         // Base structural layer
  static const Color bgActivityBar = Color(0xFF141414);  // Left vertical activity rail
  static const Color bgSidebar = Color(0xFF171717);      // Collapsible drawer / side panels
  static const Color bgSecondary = Color(0xFF1C1C1C);    // Secondary container backgrounds
  static const Color bgTertiary = Color(0xFF242424);     // Tertiary block / card backgrounds

  static const Color bgSurface = Color(0xFF1E1E1E);      // Standard card & input surface
  static const Color bgSurfaceHover = Color(0xFF262626); // Hover state on surface elements
  static const Color bgElevated = Color(0xFF282828);     // Elevated chips, popovers, active tools
  static const Color bgElevatedHover = Color(0xFF323232);// Hover state on elevated components
  static const Color bgModal = Color(0xFF222222);        // Modal dialogs and sheets
  static const Color bgSelected = Color(0x1FFFFFFF);     // Selected item highlight (8% white)
  static const Color bgTooltip = Color(0xFF18181B);      // Floating tooltips and indicator pills
  static const Color bgCard = Color(0xFF1A1A1A);         // Dedicated card background

  static const Color borderSubtle = Color(0xFF27272A);   // Hairline separation border
  static const Color borderDefault = Color(0xFF3F3F46);  // Standard interactive border
  static const Color borderStrong = Color(0xFF52525B);   // High-visibility border
  static const Color borderActive = Color(0xFFFFFFFF);   // Pure white active selection border
  static const Color borderFocused = Color(0xFF67E8F9);  // Focus ring border (cyan)
  static const Color borderHover = Color(0xFF71717A);    // Border hover state

  static const Color fgPrimary = Color(0xFFF4F4F5);      // High-contrast primary text
  static const Color fgSecondary = Color(0xFFA1A1AA);    // Muted secondary descriptions & captions
  static const Color fgTertiary = Color(0xFF71717A);     // De-emphasized placeholder text
  static const Color fgMuted = Color(0xFF71717A);        // Alias for fgTertiary
  static const Color fgDisabled = Color(0xFF52525B);     // Inactive controls and disabled text
  static const Color fgInverse = Color(0xFF09090B);      // Inverted text for solid white buttons
  static const Color fgAccent = Color(0xFF67E8F9);       // Electric cyan for links, code terms
  static const Color fgAccentHover = Color(0xFFA5F3FC);  // Cyan hover

  static const Color accentPrimary = Color(0xFFFFFFFF);  // Pure white primary accent
  static const Color accentSecondary = Color(0xFFA1A1AA);// Secondary neutral accent
  static const Color accentCyan = Color(0xFF67E8F9);     // Electric cyan
  static const Color accentBlue = Color(0xFF38BDF8);     // Sky blue
  static const Color accentViolet = Color(0xFF818CF8);   // Soft violet / concept link
  static const Color accentEmerald = Color(0xFF10B981);  // Success / Achievement
  static const Color accentAmber = Color(0xFFF59E0B);    // Warning / XP points
  static const Color accentWarning = Color(0xFFF59E0B);  // Warning alias
  static const Color accentRose = Color(0xFFEF4444);     // Error / Destructive
  static const Color accentDestructive = Color(0xFFEF4444); // Destructive alias

  static const Color successSubtle = Color(0x2010B981);  // 12% opacity emerald
  static const Color successBorder = Color(0x4D10B981);  // 30% opacity emerald
  static const Color warningSubtle = Color(0x20F59E0B);  // 12% opacity amber
  static const Color warningBorder = Color(0x4DF59E0B);  // 30% opacity amber
  static const Color errorSubtle = Color(0x20EF4444);    // 12% opacity rose
  static const Color errorBorder = Color(0x4DEF4444);    // 30% opacity rose
  static const Color infoSubtle = Color(0x2006B6D4);     // 12% opacity cyan
  static const Color infoBorder = Color(0x4D06B6D4);     // 30% opacity cyan
  static const Color accentCyanSubtle = Color(0x2067E8F9);
  static const Color accentVioletSubtle = Color(0x20818CF8);

  /// Dynamic context-aware accessor: AppColors.of(context).bgCanvas
  static AppColorsExtension of(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.light
        ? AppColorsExtension.light
        : AppColorsExtension.dark;
  }
}

/// ThemeExtension for seamless runtime switching between Dark and AFFiNE Light themes.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color bgCanvas;
  final Color bgBase;
  final Color bgActivityBar;
  final Color bgSidebar;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgSurface;
  final Color bgSurfaceHover;
  final Color bgElevated;
  final Color bgElevatedHover;
  final Color bgModal;
  final Color bgSelected;
  final Color bgTooltip;
  final Color bgCard;

  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderActive;
  final Color borderFocused;
  final Color borderHover;

  final Color fgPrimary;
  final Color fgSecondary;
  final Color fgTertiary;
  final Color fgMuted;
  final Color fgDisabled;
  final Color fgInverse;
  final Color fgAccent;
  final Color fgAccentHover;

  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentCyan;
  final Color accentBlue;
  final Color accentViolet;
  final Color accentEmerald;
  final Color accentAmber;
  final Color accentWarning;
  final Color accentRose;
  final Color accentDestructive;

  final Color successSubtle;
  final Color successBorder;
  final Color warningSubtle;
  final Color warningBorder;
  final Color errorSubtle;
  final Color errorBorder;
  final Color infoSubtle;
  final Color infoBorder;

  const AppColorsExtension({
    required this.bgCanvas,
    required this.bgBase,
    required this.bgActivityBar,
    required this.bgSidebar,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgSurface,
    required this.bgSurfaceHover,
    required this.bgElevated,
    required this.bgElevatedHover,
    required this.bgModal,
    required this.bgSelected,
    required this.bgTooltip,
    required this.bgCard,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderActive,
    required this.borderFocused,
    required this.borderHover,
    required this.fgPrimary,
    required this.fgSecondary,
    required this.fgTertiary,
    required this.fgMuted,
    required this.fgDisabled,
    required this.fgInverse,
    required this.fgAccent,
    required this.fgAccentHover,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentCyan,
    required this.accentBlue,
    required this.accentViolet,
    required this.accentEmerald,
    required this.accentAmber,
    required this.accentWarning,
    required this.accentRose,
    required this.accentDestructive,
    required this.successSubtle,
    required this.successBorder,
    required this.warningSubtle,
    required this.warningBorder,
    required this.errorSubtle,
    required this.errorBorder,
    required this.infoSubtle,
    required this.infoBorder,
  });

  /// Canonical Dark Theme Tokens (Oreo Default)
  static const AppColorsExtension dark = AppColorsExtension(
    bgCanvas: Color(0xFF0D0D0D),
    bgBase: Color(0xFF121212),
    bgActivityBar: Color(0xFF141414),
    bgSidebar: Color(0xFF171717),
    bgSecondary: Color(0xFF1C1C1C),
    bgTertiary: Color(0xFF242424),
    bgSurface: Color(0xFF1E1E1E),
    bgSurfaceHover: Color(0xFF262626),
    bgElevated: Color(0xFF282828),
    bgElevatedHover: Color(0xFF323232),
    bgModal: Color(0xFF222222),
    bgSelected: Color(0x1FFFFFFF),
    bgTooltip: Color(0xFF18181B),
    bgCard: Color(0xFF1A1A1A),
    borderSubtle: Color(0xFF27272A),
    borderDefault: Color(0xFF3F3F46),
    borderStrong: Color(0xFF52525B),
    borderActive: Color(0xFFFFFFFF),
    borderFocused: Color(0xFF67E8F9),
    borderHover: Color(0xFF71717A),
    fgPrimary: Color(0xFFF4F4F5),
    fgSecondary: Color(0xFFA1A1AA),
    fgTertiary: Color(0xFF71717A),
    fgMuted: Color(0xFF71717A),
    fgDisabled: Color(0xFF52525B),
    fgInverse: Color(0xFF09090B),
    fgAccent: Color(0xFF67E8F9),
    fgAccentHover: Color(0xFFA5F3FC),
    accentPrimary: Color(0xFFFFFFFF),
    accentSecondary: Color(0xFFA1A1AA),
    accentCyan: Color(0xFF67E8F9),
    accentBlue: Color(0xFF38BDF8),
    accentViolet: Color(0xFF818CF8),
    accentEmerald: Color(0xFF10B981),
    accentAmber: Color(0xFFF59E0B),
    accentWarning: Color(0xFFF59E0B),
    accentRose: Color(0xFFEF4444),
    accentDestructive: Color(0xFFEF4444),
    successSubtle: Color(0x2010B981),
    successBorder: Color(0x4D10B981),
    warningSubtle: Color(0x20F59E0B),
    warningBorder: Color(0x4DF59E0B),
    errorSubtle: Color(0x20EF4444),
    errorBorder: Color(0x4DEF4444),
    infoSubtle: Color(0x2006B6D4),
    infoBorder: Color(0x4D06B6D4),
  );

  /// Authentic AFFiNE-Inspired Light Theme Tokens (High Contrast)
  static const AppColorsExtension light = AppColorsExtension(
    bgCanvas: Color(0xFFEEF1F6),       // Distinct cool gray paper canvas
    bgBase: Color(0xFFFFFFFF),         // Clean base
    bgActivityBar: Color(0xFFE4E7ED),  // Distinct light activity rail
    bgSidebar: Color(0xFFE8ECF2),      // Clean sidebar
    bgSecondary: Color(0xFFE2E6EC),    // Light secondary background
    bgTertiary: Color(0xFFD6DBE4),     // Subtle tertiary divider surface
    bgSurface: Color(0xFFFFFFFF),      // Pure bright white card surfaces
    bgSurfaceHover: Color(0xFFF8FAFC), // Subtle hover tint
    bgElevated: Color(0xFFFFFFFF),     // Elevated card
    bgElevatedHover: Color(0xFFF1F5F9),
    bgModal: Color(0xFFFFFFFF),        // White modal sheet
    bgSelected: Color(0x180F172A),     // 10% dark slate selection
    bgTooltip: Color(0xFF1E293B),      // Dark floating tooltip
    bgCard: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFCBD5E1),   // Crisp hairline gray border (clearly defines white cards on gray)
    borderDefault: Color(0xFF94A3B8),  // Standard border
    borderStrong: Color(0xFF64748B),   // Strong border
    borderActive: Color(0xFF0F172A),   // Solid dark active border
    borderFocused: Color(0xFF0284C7),  // Sky blue focus ring
    borderHover: Color(0xFF475569),
    fgPrimary: Color(0xFF0F172A),      // Deep slate primary text
    fgSecondary: Color(0xFF475569),    // Muted secondary text
    fgTertiary: Color(0xFF64748B),     // Light caption / placeholder
    fgMuted: Color(0xFF64748B),
    fgDisabled: Color(0xFF94A3B8),
    fgInverse: Color(0xFFFFFFFF),      // White text on dark buttons
    fgAccent: Color(0xFF0284C7),       // Sky blue accent
    fgAccentHover: Color(0xFF0369A1),
    accentPrimary: Color(0xFF0F172A),  // Solid dark action button in light mode
    accentSecondary: Color(0xFF64748B),
    accentCyan: Color(0xFF0284C7),
    accentBlue: Color(0xFF2563EB),
    accentViolet: Color(0xFF7C3AED),
    accentEmerald: Color(0xFF059669),
    accentAmber: Color(0xFFD97706),
    accentWarning: Color(0xFFD97706),
    accentRose: Color(0xFFDC2626),
    accentDestructive: Color(0xFFDC2626),
    successSubtle: Color(0x1A059669),
    successBorder: Color(0x40059669),
    warningSubtle: Color(0x1AD97706),
    warningBorder: Color(0x40D97706),
    errorSubtle: Color(0x1ADC2626),
    errorBorder: Color(0x40DC2626),
    infoSubtle: Color(0x1A0284C7),
    infoBorder: Color(0x400284C7),
  );

  @override
  AppColorsExtension copyWith({
    Color? bgCanvas,
    Color? bgBase,
    Color? bgActivityBar,
    Color? bgSidebar,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? bgSurface,
    Color? bgSurfaceHover,
    Color? bgElevated,
    Color? bgElevatedHover,
    Color? bgModal,
    Color? bgSelected,
    Color? bgTooltip,
    Color? bgCard,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderActive,
    Color? borderFocused,
    Color? borderHover,
    Color? fgPrimary,
    Color? fgSecondary,
    Color? fgTertiary,
    Color? fgMuted,
    Color? fgDisabled,
    Color? fgInverse,
    Color? fgAccent,
    Color? fgAccentHover,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentCyan,
    Color? accentBlue,
    Color? accentViolet,
    Color? accentEmerald,
    Color? accentAmber,
    Color? accentWarning,
    Color? accentRose,
    Color? accentDestructive,
    Color? successSubtle,
    Color? successBorder,
    Color? warningSubtle,
    Color? warningBorder,
    Color? errorSubtle,
    Color? errorBorder,
    Color? infoSubtle,
    Color? infoBorder,
  }) {
    return AppColorsExtension(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgBase: bgBase ?? this.bgBase,
      bgActivityBar: bgActivityBar ?? this.bgActivityBar,
      bgSidebar: bgSidebar ?? this.bgSidebar,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceHover: bgSurfaceHover ?? this.bgSurfaceHover,
      bgElevated: bgElevated ?? this.bgElevated,
      bgElevatedHover: bgElevatedHover ?? this.bgElevatedHover,
      bgModal: bgModal ?? this.bgModal,
      bgSelected: bgSelected ?? this.bgSelected,
      bgTooltip: bgTooltip ?? this.bgTooltip,
      bgCard: bgCard ?? this.bgCard,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderActive: borderActive ?? this.borderActive,
      borderFocused: borderFocused ?? this.borderFocused,
      borderHover: borderHover ?? this.borderHover,
      fgPrimary: fgPrimary ?? this.fgPrimary,
      fgSecondary: fgSecondary ?? this.fgSecondary,
      fgTertiary: fgTertiary ?? this.fgTertiary,
      fgMuted: fgMuted ?? this.fgMuted,
      fgDisabled: fgDisabled ?? this.fgDisabled,
      fgInverse: fgInverse ?? this.fgInverse,
      fgAccent: fgAccent ?? this.fgAccent,
      fgAccentHover: fgAccentHover ?? this.fgAccentHover,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentCyan: accentCyan ?? this.accentCyan,
      accentBlue: accentBlue ?? this.accentBlue,
      accentViolet: accentViolet ?? this.accentViolet,
      accentEmerald: accentEmerald ?? this.accentEmerald,
      accentAmber: accentAmber ?? this.accentAmber,
      accentWarning: accentWarning ?? this.accentWarning,
      accentRose: accentRose ?? this.accentRose,
      accentDestructive: accentDestructive ?? this.accentDestructive,
      successSubtle: successSubtle ?? this.successSubtle,
      successBorder: successBorder ?? this.successBorder,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      warningBorder: warningBorder ?? this.warningBorder,
      errorSubtle: errorSubtle ?? this.errorSubtle,
      errorBorder: errorBorder ?? this.errorBorder,
      infoSubtle: infoSubtle ?? this.infoSubtle,
      infoBorder: infoBorder ?? this.infoBorder,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgActivityBar: Color.lerp(bgActivityBar, other.bgActivityBar, t)!,
      bgSidebar: Color.lerp(bgSidebar, other.bgSidebar, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgTertiary, other.bgTertiary, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceHover: Color.lerp(bgSurfaceHover, other.bgSurfaceHover, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgElevatedHover: Color.lerp(bgElevatedHover, other.bgElevatedHover, t)!,
      bgModal: Color.lerp(bgModal, other.bgModal, t)!,
      bgSelected: Color.lerp(bgSelected, other.bgSelected, t)!,
      bgTooltip: Color.lerp(bgTooltip, other.bgTooltip, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderActive: Color.lerp(borderActive, other.borderActive, t)!,
      borderFocused: Color.lerp(borderFocused, other.borderFocused, t)!,
      borderHover: Color.lerp(borderHover, other.borderHover, t)!,
      fgPrimary: Color.lerp(fgPrimary, other.fgPrimary, t)!,
      fgSecondary: Color.lerp(fgSecondary, other.fgSecondary, t)!,
      fgTertiary: Color.lerp(fgTertiary, other.fgTertiary, t)!,
      fgMuted: Color.lerp(fgMuted, other.fgMuted, t)!,
      fgDisabled: Color.lerp(fgDisabled, other.fgDisabled, t)!,
      fgInverse: Color.lerp(fgInverse, other.fgInverse, t)!,
      fgAccent: Color.lerp(fgAccent, other.fgAccent, t)!,
      fgAccentHover: Color.lerp(fgAccentHover, other.fgAccentHover, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentViolet: Color.lerp(accentViolet, other.accentViolet, t)!,
      accentEmerald: Color.lerp(accentEmerald, other.accentEmerald, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      accentRose: Color.lerp(accentRose, other.accentRose, t)!,
      accentDestructive: Color.lerp(accentDestructive, other.accentDestructive, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      errorSubtle: Color.lerp(errorSubtle, other.errorSubtle, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      infoSubtle: Color.lerp(infoSubtle, other.infoSubtle, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
    );
  }
}

/// Convenience extension on BuildContext to easily access theme tokens
extension ThemeContextExt on BuildContext {
  AppColorsExtension get colors {
    final ext = Theme.of(this).extension<AppColorsExtension>();
    if (ext != null) return ext;
    return Theme.of(this).brightness == Brightness.light
        ? AppColorsExtension.light
        : AppColorsExtension.dark;
  }
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Centralized typographic scale for uniform readability and visual hierarchy.
class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.fgPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.fgPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle get heading1 => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.fgPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.fgPrimary,
    height: 1.35,
  );

  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.fgPrimary,
    height: 1.4,
  );

  static TextStyle get title => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.fgPrimary,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.fgPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.fgSecondary,
    height: 1.45,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.fgSecondary,
    height: 1.4,
  );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.fgPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.fgSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.fgTertiary,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static TextStyle get codeBlock => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.fgPrimary,
    height: 1.5,
  );

  static TextStyle get codeInline => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.fgAccent,
    height: 1.3,
  );
}

/// Centralized spacing scale based on 4px / 8px increments.
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;

  static const EdgeInsets pXs = EdgeInsets.all(xs);
  static const EdgeInsets pSm = EdgeInsets.all(sm);
  static const EdgeInsets pMd = EdgeInsets.all(md);
  static const EdgeInsets pBase = EdgeInsets.all(base);
  static const EdgeInsets pLg = EdgeInsets.all(lg);
  static const EdgeInsets pXl = EdgeInsets.all(xl);
  static const EdgeInsets pXxl = EdgeInsets.all(xxl);

  static const EdgeInsets hSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets hMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets hBase = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets hLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets hXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets hXxl = EdgeInsets.symmetric(horizontal: xxl);

  static const EdgeInsets vSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets vMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets vBase = EdgeInsets.symmetric(vertical: base);
  static const EdgeInsets vLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets vXl = EdgeInsets.symmetric(vertical: xl);

  static const SizedBox vGapXs = SizedBox(height: xs);
  static const SizedBox vGapSm = SizedBox(height: sm);
  static const SizedBox vGapMd = SizedBox(height: md);
  static const SizedBox vGapBase = SizedBox(height: base);
  static const SizedBox vGapLg = SizedBox(height: lg);
  static const SizedBox vGapXl = SizedBox(height: xl);
  static const SizedBox vGapXxl = SizedBox(height: xxl);

  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapBase = SizedBox(width: base);
  static const SizedBox hGapLg = SizedBox(width: lg);
  static const SizedBox hGapXl = SizedBox(width: xl);
  static const SizedBox hGapXxl = SizedBox(width: xxl);
}

/// Centralized border radius tokens.
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double round = 999.0;

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rRound = BorderRadius.all(Radius.circular(round));
}

/// Centralized shadows and elevations.
class AppElevation {
  static const List<BoxShadow> none = [];

  static final List<BoxShadow> low = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> high = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> cyanGlow = [
    BoxShadow(
      color: AppColors.accentCyan.withValues(alpha: 0.18),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 0),
    ),
  ];

  static final List<BoxShadow> emeraldGlow = [
    BoxShadow(
      color: AppColors.accentEmerald.withValues(alpha: 0.18),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 0),
    ),
  ];
}

/// Global Application Theme Configuration.
class AppTheme {
  /// Dark Theme (Default)
  static ThemeData get darkTheme {
    const colors = AppColorsExtension.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.bgCanvas,
      canvasColor: colors.bgCanvas,
      cardColor: colors.bgSurface,
      dividerColor: colors.borderSubtle,
      extensions: const [colors],
      
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1E1E1E),
        primary: Color(0xFFFFFFFF),
        secondary: Color(0xFF67E8F9),
        tertiary: Color(0xFF818CF8),
        error: Color(0xFFEF4444),
        outline: Color(0xFF27272A),
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        headlineLarge: AppTypography.heading1,
        headlineMedium: AppTypography.heading2,
        headlineSmall: AppTypography.heading3,
        titleMedium: AppTypography.title,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.caption,
      ),

      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rXl,
          side: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: const Color(0xFF09090B),
          disabledBackgroundColor: const Color(0xFF1C1C1C),
          disabledForegroundColor: const Color(0xFF52525B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF4F4F5),
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Color(0xFF3F3F46), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFA1A1AA),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF71717A), fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFA1A1AA), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rLg,
          borderSide: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rLg,
          borderSide: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rLg,
          borderSide: BorderSide(color: Color(0xFF67E8F9), width: 1.5),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF27272A),
        thickness: 1,
        space: 1,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF222222),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rXl,
          side: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
    );
  }

  /// AFFiNE-Inspired Clean Light Theme
  static ThemeData get lightTheme {
    const colors = AppColorsExtension.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.bgCanvas,
      canvasColor: colors.bgCanvas,
      cardColor: colors.bgSurface,
      dividerColor: colors.borderSubtle,
      extensions: const [colors],
      
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFFFFFFF),
        primary: Color(0xFF0F172A),
        secondary: Color(0xFF0284C7),
        tertiary: Color(0xFF7C3AED),
        error: Color(0xFFDC2626),
        outline: Color(0xFFE2E8F0),
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: colors.fgPrimary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: colors.fgPrimary, letterSpacing: -0.3),
        headlineLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: colors.fgPrimary),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: colors.fgPrimary),
        headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: colors.fgPrimary),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: colors.fgPrimary),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, color: colors.fgPrimary, height: 1.5),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, color: colors.fgSecondary, height: 1.45),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, color: colors.fgSecondary),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: colors.fgPrimary),
        labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: colors.fgSecondary),
        labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, color: colors.fgTertiary),
      ),

      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rXl,
          side: BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: const Color(0xFFFFFFFF),
          disabledBackgroundColor: const Color(0xFFEDF2F7),
          disabledForegroundColor: const Color(0xFFCBD5E1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rLg,
          borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rLg,
          borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rLg,
          borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rXl,
          side: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
    );
  }
}

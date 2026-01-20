import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// Oxy Color Palette
// =============================================================================

class AppColors {
  // Primary Navy Blue (Oxy signature color)
  static const Color primaryNavy = Color(0xFF0d173d);
  static const Color primaryDark = Color(0xFF080f28);
  static const Color primaryLight = Color(0xFF3a57d3);
  
  // Backward compatibility alias
  static const Color primaryTeal = primaryNavy;
  
  // Accent colors
  static const Color accent = Color(0xFF3a57d3);
  static const Color accentLight = Color(0xFFD6DEFF);
  
  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF3a57d3);
  
  // Light mode
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF7F8FA);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightOnSurfaceVariant = Color(0xFF667781);
  static const Color lightOutline = Color(0xFFE9EDEF);
  static const Color lightDivider = Color(0xFFE9EDEF);
  
  // Dark mode
  static const Color darkBackground = Color(0xFF111B21);
  static const Color darkSurface = Color(0xFF1F2C33);
  static const Color darkSurfaceVariant = Color(0xFF233138);
  static const Color darkOnSurface = Color(0xFFE9EDEF);
  static const Color darkOnSurfaceVariant = Color(0xFF8696A0);
  static const Color darkOutline = Color(0xFF374248);
  static const Color darkDivider = Color(0xFF374248);
}

class LightModeColors {
  static const lightPrimary = AppColors.primaryNavy;
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFD6DEFF);
  static const lightOnPrimaryContainer = AppColors.primaryDark;
  static const lightSecondary = AppColors.primaryDark;
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = AppColors.accent;
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = AppColors.error;
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);
  static const lightSurface = AppColors.lightSurface;
  static const lightOnSurface = AppColors.lightOnSurface;
  static const lightBackground = AppColors.lightBackground;
  static const lightSurfaceVariant = AppColors.lightSurfaceVariant;
  static const lightOnSurfaceVariant = AppColors.lightOnSurfaceVariant;
  static const lightOutline = AppColors.lightOutline;
  static const lightShadow = Color(0x1A000000);
  static const lightInversePrimary = AppColors.primaryLight;
}

class DarkModeColors {
  static const darkPrimary = AppColors.primaryLight;
  static const darkOnPrimary = Color(0xFFFFFFFF);
  static const darkPrimaryContainer = AppColors.primaryDark;
  static const darkOnPrimaryContainer = Color(0xFFD6DEFF);
  static const darkSecondary = AppColors.primaryNavy;
  static const darkOnSecondary = Color(0xFFFFFFFF);
  static const darkTertiary = AppColors.accent;
  static const darkOnTertiary = Color(0xFFFFFFFF);
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);
  static const darkSurface = AppColors.darkSurface;
  static const darkOnSurface = AppColors.darkOnSurface;
  static const darkSurfaceVariant = AppColors.darkSurfaceVariant;
  static const darkOnSurfaceVariant = AppColors.darkOnSurfaceVariant;
  static const darkOutline = AppColors.darkOutline;
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = AppColors.primaryNavy;
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 20.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
    onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
    outline: LightModeColors.lightOutline,
    shadow: LightModeColors.lightShadow,
    inversePrimary: LightModeColors.lightInversePrimary,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: LightModeColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primaryNavy,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: LightModeColors.lightSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: EdgeInsets.zero,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryNavy,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: CircleBorder(),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primaryNavy,
    unselectedItemColor: AppColors.lightOnSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    indicatorColor: Colors.white,
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.lightDivider,
    thickness: 1,
    space: 0,
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: LightModeColors.lightSurfaceVariant,
    selectedColor: AppColors.primaryNavy,
    labelStyle: const TextStyle(fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LightModeColors.lightSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryNavy,
      side: const BorderSide(color: AppColors.primaryNavy),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryNavy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  textTheme: _buildTextTheme(Brightness.light),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
    surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
    onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
    outline: DarkModeColors.darkOutline,
    shadow: DarkModeColors.darkShadow,
    inversePrimary: DarkModeColors.darkInversePrimary,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnSurface,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: DarkModeColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: EdgeInsets.zero,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryLight,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: CircleBorder(),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.primaryLight,
    unselectedItemColor: AppColors.darkOnSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: AppColors.darkOnSurface,
    unselectedLabelColor: AppColors.darkOnSurfaceVariant,
    indicatorColor: AppColors.primaryLight,
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkDivider,
    thickness: 1,
    space: 0,
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: DarkModeColors.darkSurfaceVariant,
    selectedColor: AppColors.primaryLight,
    labelStyle: const TextStyle(fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: DarkModeColors.darkSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      side: const BorderSide(color: AppColors.primaryLight),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  textTheme: _buildTextTheme(Brightness.dark),
);

TextTheme _buildTextTheme(Brightness brightness) {
  final color = brightness == Brightness.light 
      ? AppColors.lightOnSurface 
      : AppColors.darkOnSurface;
  
  return TextTheme(
    displayLarge: GoogleFonts.cabin(fontSize: FontSizes.displayLarge, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: color),
    displayMedium: GoogleFonts.cabin(fontSize: FontSizes.displayMedium, fontWeight: FontWeight.w400, color: color),
    displaySmall: GoogleFonts.cabin(fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w400, color: color),
    headlineLarge: GoogleFonts.cabin(fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: color),
    headlineMedium: GoogleFonts.cabin(fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w600, color: color),
    headlineSmall: GoogleFonts.cabin(fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.w600, color: color),
    titleLarge: GoogleFonts.cabin(fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w600, color: color),
    titleMedium: GoogleFonts.cabin(fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w500, color: color),
    titleSmall: GoogleFonts.cabin(fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500, color: color),
    labelLarge: GoogleFonts.cabin(fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: color),
    labelMedium: GoogleFonts.cabin(fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: color),
    labelSmall: GoogleFonts.cabin(fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: color),
    bodyLarge: GoogleFonts.cabin(fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.w400, letterSpacing: 0.15, color: color),
    bodyMedium: GoogleFonts.cabin(fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: color),
    bodySmall: GoogleFonts.cabin(fontSize: FontSizes.bodySmall, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: color),
  );
}

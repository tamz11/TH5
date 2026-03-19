import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/habit_provider.dart';
import 'services/habit_storage_service.dart';
import 'services/theme_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<HabitProvider>(
          create: (_) => HabitProvider(HabitStorageService())..loadHabits(),
        ),
      ],
      child: const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  static const Color _bgColor = Color(0xFFF6F7F4);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF1E5B4F);
  static const Color _mutedTextColor = Color(0xFF63706C);
  static const List<String> _fontFallbacks = <String>[
    'Noto Sans',
    'Noto Sans Symbols',
    'Arial Unicode MS',
    'sans-serif',
  ];

  ThemeData _buildTheme(Brightness brightness) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      fontFamilyFallback: _fontFallbacks,
    );

    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101714) : _bgColor;
    final surfaceColor = isDark ? const Color(0xFF18211D) : _surfaceColor;
    final textColor = isDark
        ? const Color(0xFFF3F7F4)
        : const Color(0xFF1C2521);
    final mutedText = isDark ? const Color(0xFFB7C6BF) : _mutedTextColor;
    final dividerColor = isDark
        ? const Color(0xFF31423B)
        : const Color(0xFFDCE3DD);

    return ThemeData(
      useMaterial3: true,
      iconTheme: IconThemeData(
        color: isDark ? textColor : Colors.black,
      ),
      primaryIconTheme: IconThemeData(
        color: isDark ? textColor : Colors.black,
      ),
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: brightness,
        surface: surfaceColor,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textColor,
          height: 1.35,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: mutedText,
          height: 1.35,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        backgroundColor: isDark
            ? const Color(0xFF223029)
            : const Color(0xFFEAEFEA),
        labelStyle: baseTextTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? textColor : const Color(0xFF395049),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF213029) : const Color(0xFFEEF1ED),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dividerColor: dividerColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Habit Tracker',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}

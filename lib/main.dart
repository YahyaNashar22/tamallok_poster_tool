import 'package:flutter/material.dart';
import 'package:poster_tool/routes/app_routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const TamellakPosterTool());
}

class TamellakPosterTool extends StatelessWidget {
  const TamellakPosterTool({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Monda',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF17652F),
        primary: const Color(0xFF17652F),
        secondary: const Color(0xFFC98F21),
        surface: const Color(0xFFF7F4EA),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tamellak Poster Tool',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F1E7),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFF4F1E7),
          foregroundColor: Color(0xFF1D2A22),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF17652F), width: 1.5),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: const WidgetStatePropertyAll(true),
          thumbColor: WidgetStateProperty.all<Color>(
            const Color(0xFF17652F).withValues(alpha: 0.8),
          ),
          crossAxisMargin: -12,
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

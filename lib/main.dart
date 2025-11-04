import 'package:flutter/material.dart';
import 'package:poster_tool/routes/app_routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for Windows/Linux/Mac
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const TamellakPosterTool());
}

class TamellakPosterTool extends StatelessWidget {
  const TamellakPosterTool({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tamellak Poster Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

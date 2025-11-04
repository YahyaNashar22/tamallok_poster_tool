import 'package:flutter/material.dart';
import 'package:poster_tool/screens/all_posters_screen.dart';
import 'package:poster_tool/screens/home_screen.dart';
import 'package:poster_tool/screens/not_found_screen.dart';
import 'package:poster_tool/screens/splash_screen.dart';

class AppRoutes {
  static const splash = "/";
  static const home = "/home";
  static const allPosters = "/all_posters";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case allPosters:
        return MaterialPageRoute(builder: (_) => const AllPostersScreen());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }
}

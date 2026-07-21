import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routing_name.dart';

class AppRouting {
  AppRouting._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutingName.splash,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutingName.splash,
        name: AppRoutingName.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: AppRoutingName.onboarding,
        name: AppRoutingName.onboarding,
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingPage();
        },
      ),
      GoRoute(
        path: AppRoutingName.login,
        name: AppRoutingName.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutingName.home,
        name: AppRoutingName.home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomePage();
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        body: Center(child: Text('Route not found: ${state.uri}')),
      );
    },
  );
}

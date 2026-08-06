import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/advisor/presentation/pages/advisor_profile_page.dart';
import '../../features/advisor/presentation/pages/batch_details_page.dart';
import '../../features/auth/presentation/pages/interest_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';
import '../../features/discover/data/models/discover_analyst_model.dart';
import '../../features/home/domain/entities/home_trade.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/saved_trades/presentation/pages/saved_trades_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import '../../features/subscriptions/presentation/pages/payment_success_page.dart';
import '../../features/subscriptions/presentation/pages/payment_history_page.dart';
import '../../features/subscriptions/presentation/pages/subscriptions_page.dart';
import '../../features/trades/presentation/pages/trade_details_page.dart';
import '../../features/trades/presentation/pages/trades_page.dart';
import 'app_routing_name.dart';
class AuthUserExtra {
  const AuthUserExtra(this.user);
  final AuthUser user;
}
class AppRouting {
  AppRouting._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutingName.splash,
    debugLogDiagnostics: kDebugMode,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutingName.splash,
        name: AppRoutingName.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutingName.onboarding,
        name: AppRoutingName.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutingName.login,
        name: AppRoutingName.login,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutingName.otp,
        name: AppRoutingName.otp,
        builder: (BuildContext context, GoRouterState state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpPage(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutingName.interest,
        name: AppRoutingName.interest,
        builder: (_, _) => const InterestPage(),
      ),
      GoRoute(
        path: AppRoutingName.home,
        name: AppRoutingName.home,
        builder: (_, _) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutingName.discover,
        name: AppRoutingName.discover,
        builder: (_, _) => const DiscoverPage(),
      ),
      GoRoute(
        path: AppRoutingName.tradeFeed,
        name: AppRoutingName.tradeFeed,
        builder: (_, _) => const TradesPage(),
      ),
      GoRoute(
        path: AppRoutingName.profile,
        name: AppRoutingName.profile,
        builder: (_, _) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutingName.editProfile,
        name: AppRoutingName.editProfile,
        builder: (_, state) {
          final user = state.extra;
          if (user is! AuthUserExtra) return const ProfilePage();
          return EditProfilePage(user: user.user);
        },
      ),
      GoRoute(
        path: AppRoutingName.settings,
        name: AppRoutingName.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutingName.notifications,
        name: AppRoutingName.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutingName.search,
        name: AppRoutingName.search,
        builder: (_, _) => const SearchPage(),
      ),
      GoRoute(
        path: AppRoutingName.advisorProfile,
        name: AppRoutingName.advisorProfile,
        builder: (_, state) {
          final extra = state.extra;
          final analystIdFromQuery = state.uri.queryParameters['analystId'];
          return AdvisorProfilePage(
            analystId: analystIdFromQuery ??
                (extra is String ? extra : null),
            initialProfile:
                extra is DiscoverAnalystModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutingName.batchDetails,
        name: AppRoutingName.batchDetails,
        builder: (_, state) {
          final planIdFromQuery = state.uri.queryParameters['planId'];
          return BatchDetailsPage(
            planId: planIdFromQuery ??
                (state.extra is String ? state.extra as String : null),
          );
        },
      ),
      GoRoute(
        path: AppRoutingName.tradeDetails,
        builder: (context, state) {
          final tradeId = state.uri.queryParameters['tradeId'];
          return TradeDetailsPage(
            trade: state.extra is HomeTrade ? state.extra as HomeTrade : null,
            tradeId: tradeId,
          );
        },
      ),
      GoRoute(
        path: AppRoutingName.subscriptions,
        name: AppRoutingName.subscriptions,
        builder: (_, state) {
          final args = state.extra;
          final q = state.uri.queryParameters;
          return SubscriptionsPage(
            planId: q['planId'] ??
                (args is SubscriptionPageArgs ? args.planId : null),
            analystId: q['analystId'] ??
                (args is SubscriptionPageArgs ? args.analystId : null),
            batchId: q['batchId'] ??
                (args is SubscriptionPageArgs ? args.batchId : null),
          );
        },
      ),
      GoRoute(
        path: AppRoutingName.paymentSuccess,
        name: AppRoutingName.paymentSuccess,
        builder: (_, _) => const PaymentSuccessPage(),
      ),
      GoRoute(
        path: AppRoutingName.mySubscriptions,
        name: AppRoutingName.mySubscriptions,
        builder: (_, _) => const MySubscriptionsPage(),
      ),
      GoRoute(
        path: AppRoutingName.paymentHistory,
        name: AppRoutingName.paymentHistory,
        builder: (_, _) => const PaymentHistoryPage(),
      ),
      GoRoute(
        path: AppRoutingName.savedTrades,
        name: AppRoutingName.savedTrades,
        builder: (_, _) => const SavedTradesPage(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        body: Center(child: Text('Route not found: ${state.uri}')),
      );
    },
  );
}

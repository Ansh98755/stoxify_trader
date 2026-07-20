import 'app_routing_name.dart';

enum AppRoutingEnum {
  splash,
  onboarding,
  login,
  otp,
  interest,
  home,
  discover,
  advisorProfile,
  tradeFeed,
  tradeDetails,
  subscriptions,
  paymentSuccess,
  notifications,
  search,
  profile,
  settings,
  mySubscriptions,
}

extension AppRoutingEnumX on AppRoutingEnum {
  String get path {
    switch (this) {
      case AppRoutingEnum.splash:
        return AppRoutingName.splash;
      case AppRoutingEnum.onboarding:
        return AppRoutingName.onboarding;
      case AppRoutingEnum.login:
        return AppRoutingName.login;
      case AppRoutingEnum.otp:
        return AppRoutingName.otp;
      case AppRoutingEnum.interest:
        return AppRoutingName.interest;
      case AppRoutingEnum.home:
        return AppRoutingName.home;
      case AppRoutingEnum.discover:
        return AppRoutingName.discover;
      case AppRoutingEnum.advisorProfile:
        return AppRoutingName.advisorProfile;
      case AppRoutingEnum.tradeFeed:
        return AppRoutingName.tradeFeed;
      case AppRoutingEnum.tradeDetails:
        return AppRoutingName.tradeDetails;
      case AppRoutingEnum.subscriptions:
        return AppRoutingName.subscriptions;
      case AppRoutingEnum.paymentSuccess:
        return AppRoutingName.paymentSuccess;
      case AppRoutingEnum.notifications:
        return AppRoutingName.notifications;
      case AppRoutingEnum.search:
        return AppRoutingName.search;
      case AppRoutingEnum.profile:
        return AppRoutingName.profile;
      case AppRoutingEnum.settings:
        return AppRoutingName.settings;
      case AppRoutingEnum.mySubscriptions:
        return AppRoutingName.mySubscriptions;
    }
  }
}

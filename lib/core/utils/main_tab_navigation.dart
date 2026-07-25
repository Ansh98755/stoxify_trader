import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes/app_routing_name.dart';

/// Shared bottom-nav routing for the main app tabs.
void navigateMainTab(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRoutingName.home);
    case 1:
      context.go(AppRoutingName.discover);
    case 2:
      context.go(AppRoutingName.tradeFeed);
    case 3:
      context.go(AppRoutingName.profile);
  }
}

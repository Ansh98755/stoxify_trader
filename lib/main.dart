import 'package:flutter/material.dart';

import 'app/routes/app_routing.dart';
import 'app/theme/app_theme.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StoXify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouting.router,
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/routes/app_routing.dart';
import 'app/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/api_log.dart';
import 'core/notifications/fcm_service.dart';
import 'core/ota/ota_update_service.dart';
import 'core/widgets/no_network_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  // Background isolate handler is mobile-only (unsupported on web).
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await configureDependencies();
  await FcmService.instance.initialize();
  runApp(const MyApp());

  // OTA: never block UI / splash. Shorebird engines also auto-check;
  // this is an extra explicit download attempt after launch. Skipped on web only.
  if (!kIsWeb) {
    unawaited(OtaUpdateService.instance.checkAndDownload(silent: true));
  }
}

/// Mobile: same as before — native google-services / GoogleService-Info, errors propagate.
/// Web: options + soft-fail so a missing web app does not blank the site.
Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  if (kIsWeb) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } catch (e, st) {
      debugPrint('[Firebase] initializeApp failed (web): $e\n$st');
    }
    return;
  }
  await Firebase.initializeApp();
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
      builder: (context, child) => _ConnectivityWrapper(child: child!),
    );
  }
}

/// Sits above every screen. When connectivity drops it slides the
/// [NoNetworkScreen] over the entire navigator; when it returns the overlay
/// is removed immediately so the user sees the screen they were on.
class _ConnectivityWrapper extends StatefulWidget {
  const _ConnectivityWrapper({required this.child});

  final Widget child;

  @override
  State<_ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<_ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  final _service = ConnectivityService.instance;
  StreamSubscription<bool>? _sub;
  bool _isOffline = false;

  // Slide + fade animation controller
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    // Check once at startup, then subscribe to changes.
    _service.isConnected.then((connected) {
      if (!mounted) return;
      if (!connected) _showOverlay();
    });

    _sub = _service.onConnectivityChanged.listen((connected) {
      if (!mounted) return;
      if (!connected && !_isOffline) {
        _showOverlay();
      } else if (connected && _isOffline) {
        _hideOverlay();
      }
    });
  }

  void _showOverlay() {
    setState(() => _isOffline = true);
    _animCtrl.forward(from: 0);
  }

  void _hideOverlay() {
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _isOffline = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: const NoNetworkScreen(),
            ),
          ),
        if (kDebugMode)
          Positioned(
            right: 16,
            bottom: 88,
            child: FloatingActionButton.small(
              heroTag: 'api-log-button',
              // This widget sits above the router's navigator, so a FAB
              // tooltip would not have an Overlay ancestor here.
              onPressed: _showApiLogs,
              child: const Icon(Icons.network_check_rounded),
            ),
          ),
      ],
    );
  }

  void _showApiLogs() {
    final context = AppRouting.rootNavigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            children: <Widget>[
              ListTile(
                title: const Text('Live API logs'),
                trailing: TextButton(
                  onPressed: ApiLogStore.instance.clear,
                  child: const Text('Clear'),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ValueListenableBuilder<List<ApiLogEntry>>(
                  valueListenable: ApiLogStore.instance.entries,
                  builder: (_, entries, __) => entries.isEmpty
                      ? const Center(child: Text('No API calls yet'))
                      : ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (_, index) {
                            final entry = entries[index];
                            final status = entry.status?.toString() ?? 'ERR';
                            return ListTile(
                              dense: true,
                              onTap: () => _showApiLogDetail(context, entry),
                              title: Text('${entry.method} ${entry.path}'),
                              subtitle: Text(
                                '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}:${entry.time.second.toString().padLeft(2, '0')}  •  ${entry.duration.inMilliseconds} ms',
                              ),
                              trailing: Text(status),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApiLogDetail(BuildContext context, ApiLogEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .82,
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text('${entry.method} ${entry.path}'),
                subtitle: Text(
                  '${entry.status?.toString() ?? 'ERROR'} • ${entry.duration.inMilliseconds} ms',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    'SENT\n${_prettyLogValue(entry.requestBody)}\n\nRECEIVED\n${_prettyLogValue(entry.responseBody)}${entry.error == null ? '' : '\n\nERROR\n${entry.error}'}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prettyLogValue(Object? value) {
    if (value == null) return '—';
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activities/activities_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/clock/clock_screen.dart';
import '../features/pomodoro/pomodoro_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers.dart';
import 'session_tray.dart';
import 'theme.dart';

class ChronoflowApp extends ConsumerWidget {
  const ChronoflowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(selectedAccountProvider);
    return MaterialApp.router(
      title: 'Chronoflow',
      debugShowCheckedModeBanner: false,
      theme: ChronoflowTheme.light(),
      darkTheme: ChronoflowTheme.dark(),
      routerConfig: _router(account),
      builder: (context, child) {
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;
        final navigationColor = theme.navigationBarTheme.backgroundColor ??
            theme.scaffoldBackgroundColor;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: navigationColor,
            systemNavigationBarDividerColor: navigationColor,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

GoRouter _router(AsyncValue<Object?> account) => GoRouter(
      initialLocation: '/pomodoro',
      redirect: (context, state) {
        final authenticated = account.value != null;
        final goingToLogin = state.matchedLocation == '/login';
        if (!authenticated) return goingToLogin ? null : '/login';
        return goingToLogin ? '/pomodoro' : null;
      },
      routes: [
        GoRoute(
            path: '/login', builder: (context, state) => const LoginScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _ChronoflowShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/pomodoro',
                  builder: (context, state) => const PomodoroScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/clock',
                  builder: (context, state) => const ClockScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/summary',
                  builder: (context, state) => const SummaryScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/activities',
                  builder: (context, state) => const ActivitiesScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen()),
            ]),
          ],
        ),
      ],
    );

class _ChronoflowShell extends ConsumerStatefulWidget {
  const _ChronoflowShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<_ChronoflowShell> createState() => _ChronoflowShellState();
}

class _ChronoflowShellState extends ConsumerState<_ChronoflowShell> {
  String? _startedAccountId;
  bool _starting = false;
  final _tray = SessionTrayController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfReady());
  }

  Future<void> _syncIfReady() async {
    final accountId = ref.read(selectedAccountProvider).value?.id;
    if (accountId == null || accountId == _startedAccountId || _starting) {
      return;
    }
    _starting = true;
    try {
      await ref.read(syncCoordinatorProvider).start(
            accountId: accountId,
            connectivity: Connectivity().onConnectivityChanged.map((results) =>
                results.any((result) => result != ConnectivityResult.none)),
          );
      _startedAccountId = accountId;
      // Keep the locally cached admin flag in sync with the server.
      unawaited(ref.read(authRepositoryProvider).refreshRole(accountId));
    } catch (_) {
    } finally {
      _starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedAccountProvider, (_, __) => _syncIfReady());
    final account = ref.watch(selectedAccountProvider).value;
    if (account != null) {
      final timer = ref.watch(pomodoroProvider(account.id));
      unawaited(_tray.update(timer));
    }
    final wide = MediaQuery.sizeOf(context).width >= 900;
    const destinations = [
      NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Timer'),
      NavigationDestination(
          icon: Icon(Icons.schedule_outlined), label: 'Clock'),
      NavigationDestination(
          icon: Icon(Icons.insights_outlined), label: 'Summary'),
      NavigationDestination(
          icon: Icon(Icons.category_outlined), label: 'Things'),
      NavigationDestination(
          icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ];
    final navigation = wide
        ? NavigationRail(
            selectedIndex: widget.shell.currentIndex,
            onDestinationSelected: widget.shell.goBranch,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircleAvatar(child: Icon(Icons.alarm)),
            ),
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: destination.icon,
                  selectedIcon: destination.selectedIcon,
                  label: Text(destination.label),
                ),
            ],
          )
        : null;
    return Scaffold(
      body: wide
          ? Row(children: [
              SizedBox(width: 112, child: navigation),
              Expanded(child: widget.shell),
            ])
          : widget.shell,
      bottomNavigationBar: navigation == null
          ? NavigationBar(
              selectedIndex: widget.shell.currentIndex,
              onDestinationSelected: widget.shell.goBranch,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              destinations: destinations,
            )
          : null,
    );
  }

  @override
  void dispose() {
    unawaited(ref.read(syncCoordinatorProvider).stop());
    unawaited(_tray.dispose());
    super.dispose();
  }
}

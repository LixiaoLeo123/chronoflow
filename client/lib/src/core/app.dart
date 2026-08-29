import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activities/activities_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/clock/clock_screen.dart';
import '../features/pomodoro/pomodoro_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers.dart';
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
    } catch (_) {
    } finally {
      _starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedAccountProvider, (_, __) => _syncIfReady());
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: widget.shell.goBranch,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.timer_outlined), label: 'Timer'),
          NavigationDestination(
              icon: Icon(Icons.schedule_outlined), label: 'Clock'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), label: 'Summary'),
          NavigationDestination(
              icon: Icon(Icons.category_outlined), label: 'Things'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    unawaited(ref.read(syncCoordinatorProvider).stop());
    super.dispose();
  }
}

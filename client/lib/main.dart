import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:window_manager/window_manager.dart';

import 'src/core/app.dart';
import 'src/providers.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final container = ProviderContainer();
    try {
      final account = await container.read(selectedAccountProvider.future);
      if (account == null) return true;
      await container.read(syncEngineProvider).synchronize(account.id);
      return true;
    } catch (_) {
      return false;
    } finally {
      await container.read(databaseProvider).closeDatabase();
      container.dispose();
    }
  });
}

/// Close-to-tray: the window hides instead of quitting so the tray menu's
/// "Show" can bring it back and the pomodoro keeps running in the background.
class _CloseToTray extends WindowListener {
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  if (!Platform.isAndroid) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(_CloseToTray());
  }
  await container.read(phaseNotificationsProvider).initialize();
  if (Platform.isAndroid) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      'chronoflow-periodic-sync',
      'chronoflowPeriodicSync',
      frequency: const Duration(minutes: 15),
    );
  }
  runApp(UncontrolledProviderScope(container: container, child: const ChronoflowApp()));
}

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/domain.dart';

class PhaseNotifications {
  PhaseNotifications();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  int _nextId = 1;

  Future<void> initialize() async {
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          linux: LinuxInitializationSettings(
            defaultActionName: 'Open Chronoflow',
            defaultIcon: AssetsLinuxIcon('assets/icon/chronoflow.png'),
          ),
        ),
      );
    } catch (_) {
      // Some minimal Linux sessions do not expose a DBus notification server.
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showPhase(BlockKind kind, int round) async {
    const android = AndroidNotificationDetails(
      'chronoflow-phases',
      'Pomodoro phases',
      channelDescription: 'Notifications when a focus or break phase changes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const linux = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
    );
    const title = 'Chronoflow';
    final body = '${_label(kind)} is starting — round $round';
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails:
            const NotificationDetails(android: android, linux: linux),
      );
      return;
    } catch (_) {
      if (!Platform.isLinux) rethrow;
    }
    try {
      await Process.run('notify-send', [
        '--app-name=Chronoflow',
        '--urgency=critical',
        title,
        body,
      ]);
    } catch (_) {
      // Notifications are best effort and must never stop the timer.
    }
  }
}

String _label(BlockKind kind) => switch (kind) {
      BlockKind.focus => 'Focus',
      BlockKind.shortBreak => 'Short break',
      BlockKind.longBreak => 'Long break',
    };

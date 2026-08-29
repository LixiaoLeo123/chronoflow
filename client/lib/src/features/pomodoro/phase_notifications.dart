import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/domain.dart';

class PhaseNotifications {
  PhaseNotifications();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open Chronoflow',
        ),
      ),
    );
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
    const linux = LinuxNotificationDetails();
    await _plugin.show(
      id: 1,
      title: 'Chronoflow',
      body: '${_label(kind)} is starting — round $round',
      notificationDetails:
          const NotificationDetails(android: android, linux: linux),
    );
  }
}

String _label(BlockKind kind) => switch (kind) {
      BlockKind.focus => 'Focus',
      BlockKind.shortBreak => 'Short break',
      BlockKind.longBreak => 'Long break',
    };

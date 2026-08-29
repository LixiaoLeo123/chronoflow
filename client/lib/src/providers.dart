import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'database/app_database.dart';
import 'features/pomodoro/phase_notifications.dart';
import 'features/pomodoro/pomodoro_controller.dart';
import 'repositories/activity_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/block_repository.dart';
import 'repositories/secure_session_store.dart';
import 'repositories/summary_repository.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_repository.dart';
import 'models/domain.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final secureSessionStoreProvider =
    Provider<SecureSessionStore>((ref) => SecureSessionStore());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(authApiProvider),
    ref.watch(secureSessionStoreProvider),
  ),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(databaseProvider)),
);
final blockRepositoryProvider = Provider<BlockRepository>(
  (ref) => BlockRepository(ref.watch(databaseProvider)),
);
final summaryRepositoryProvider = Provider<SummaryRepository>(
  (ref) => SummaryRepository(ref.watch(blockRepositoryProvider)),
);
final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(ref.watch(databaseProvider)),
);
final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    ref.watch(syncRepositoryProvider),
    ref.watch(apiClientProvider),
    ref.watch(authRepositoryProvider),
  ),
);

final syncCoordinatorProvider = Provider<SyncCoordinator>(
  (ref) => SyncCoordinator(ref.watch(syncEngineProvider)),
);

final selectedAccountProvider = FutureProvider<Account?>(
  (ref) => ref.watch(authRepositoryProvider).selectedAccount(),
);
final accountsProvider = FutureProvider<List<Account>>(
  (ref) => ref.watch(authRepositoryProvider).accounts(),
);

final activitiesProvider =
    StreamProvider.family<List<Activity>, String>((ref, accountId) {
  return ref.watch(activityRepositoryProvider).watchActivities(accountId);
});
final timeBlocksProvider =
    StreamProvider.family<List<TimeBlock>, String>((ref, accountId) {
  return ref.watch(blockRepositoryProvider).watchBlocks(accountId);
});

final timerSettingsProvider =
    FutureProvider.family<TimerSettings, String>((ref, accountId) {
  return ref.watch(databaseProvider).settingsFor(accountId);
});

final phaseNotificationsProvider = Provider<PhaseNotifications>(
  (ref) => PhaseNotifications(),
);

final pomodoroProvider =
    StateNotifierProvider.family<PomodoroController, PomodoroState, String>(
  (ref, accountId) => PomodoroController(
    accountId: accountId,
    database: ref.watch(databaseProvider),
    blockRepository: ref.watch(blockRepositoryProvider),
    notifications: ref.watch(phaseNotificationsProvider),
  ),
);

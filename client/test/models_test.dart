import 'package:flutter_test/flutter_test.dart';

import 'package:chronoflow/src/features/pomodoro/pomodoro_controller.dart';
import 'package:chronoflow/src/models/domain.dart';
import 'package:chronoflow/src/models/time_bounds.dart';
import 'package:chronoflow/src/repositories/summary_repository.dart';

void main() {
  group('local time boundaries', () {
    test('weeks begin on Monday', () {
      final wednesday = DateTime(2026, 8, 26, 14, 30);
      expect(startOfWeek(wednesday), DateTime(2026, 8, 24));
      expect(endOfWeek(wednesday), DateTime(2026, 8, 31));
    });

    test('detects midnight-spanning blocks', () {
      expect(
        spansMidnight(
          DateTime(2026, 8, 29, 23, 30),
          DateTime(2026, 8, 30, 0, 30),
        ),
        isTrue,
      );
      expect(
        spansMidnight(DateTime(2026, 8, 29, 9), DateTime(2026, 8, 29, 10)),
        isFalse,
      );
    });
  });

  group('pomodoro progression', () {
    test('uses a short break for non-final rounds', () {
      expect(
        phaseAfterFocus(completedFocusRounds: 1, roundsBeforeLongBreak: 4),
        BlockKind.shortBreak,
      );
    });

    test('uses a long break after the configured rounds', () {
      expect(
        phaseAfterFocus(completedFocusRounds: 4, roundsBeforeLongBreak: 4),
        BlockKind.longBreak,
      );
    });
  });

  group('summary aggregation', () {
    final activities = [
      Activity(
        id: 'writing',
        accountId: 'account',
        name: 'Writing',
        color: 0xFF2563EB,
        archived: false,
        deleted: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      Activity(
        id: 'reading',
        accountId: 'account',
        name: 'Reading',
        color: 0xFF059669,
        archived: false,
        deleted: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];

    TimeBlock block(
            String id, String activity, DateTime start, Duration duration,
            {BlockKind kind = BlockKind.focus, bool deleted = false}) =>
        TimeBlock(
          id: id,
          accountId: 'account',
          activityId: activity,
          kind: kind,
          start: start,
          end: start.add(duration),
          status: BlockStatus.completed,
          deleted: deleted,
          createdAt: start,
          updatedAt: start,
        );

    test('ranks completed focus blocks and excludes breaks and tombstones', () {
      final day = DateTime(2026, 8, 29, 9);
      final blocks = [
        block('one', 'writing', day, const Duration(minutes: 50)),
        block('two', 'reading', day.add(const Duration(hours: 2)),
            const Duration(minutes: 25)),
        block('break', 'reading', day.add(const Duration(hours: 3)),
            const Duration(minutes: 5),
            kind: BlockKind.shortBreak),
        block('deleted', 'reading', day.add(const Duration(hours: 4)),
            const Duration(hours: 2),
            deleted: true),
      ];
      final totals =
          SummaryRepository.aggregate(blocks, activities, null, null);
      expect(totals.map((item) => item.name), ['Writing', 'Reading']);
      expect(totals.first.duration, const Duration(minutes: 50));
      expect(totals.last.blockCount, 1);
      expect(totals.last.percentageOf(totals), closeTo(1 / 3, 0.001));
    });
  });
}

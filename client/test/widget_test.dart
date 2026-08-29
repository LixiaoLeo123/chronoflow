import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronoflow/src/core/app.dart';

void main() {
  testWidgets('shows authentication when no account is selected',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ChronoflowApp()),
    );
    await tester.pump();
    expect(find.text('Chronoflow'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

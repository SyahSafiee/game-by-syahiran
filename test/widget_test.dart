import 'package:flutter_test/flutter_test.dart';

import 'package:game_by_syahiran/main.dart';

void main() {
  testWidgets('GameApp builds without throwing', (tester) async {
    await tester.pumpWidget(const GameApp());
    // The Flame GameWidget kicks off async asset loading; just verify the
    // widget tree mounts cleanly for this phase's smoke test.
    await tester.pump();
    expect(find.byType(GameApp), findsOneWidget);
  });
}

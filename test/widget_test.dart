import 'package:flutter_test/flutter_test.dart';

import 'package:fitorskip/main.dart';

void main() {
  testWidgets('FitOrSkip smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FitOrSkipApp());

    expect(find.text('FitOrSkip'), findsWidgets);
    expect(
      find.text('Snap a shirt. See it on you. Get the verdict.'),
      findsOneWidget,
    );
    expect(find.text('Made by Mohammad Sidique Ibrahim'), findsOneWidget);
  });
}

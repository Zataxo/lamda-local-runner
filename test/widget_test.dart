import 'package:flutter_test/flutter_test.dart';

import 'package:zataxo_pipeline/app.dart';

void main() {
  testWidgets('app boots to landing', (WidgetTester tester) async {
    await tester.pumpWidget(const ZataxoApp());
    await tester.pump();
    expect(find.text('Zataxo Pipeline'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/app.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AtlasApp());
  });
}

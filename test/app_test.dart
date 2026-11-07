import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const HydrateSirApp());

    expect(find.text('Hargreaves, at your service.'), findsOneWidget);
  });
}

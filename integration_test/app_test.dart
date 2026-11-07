// End-to-end tests that run on a real device:
//   flutter test integration_test
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches on device', (tester) async {
    await tester.pumpWidget(const HydrateSirApp());
    await tester.pumpAndSettle();

    expect(find.text('Hargreaves, at your service.'), findsOneWidget);
  });
}

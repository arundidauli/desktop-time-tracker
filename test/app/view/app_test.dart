import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/app/app.dart';
import 'package:tracker/counter/counter.dart';

void main() {
  group('App', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.byType(CounterPage), findsOneWidget);
    });
  });
}

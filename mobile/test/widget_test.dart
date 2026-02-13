import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/app.dart';

void main() {
  testWidgets('renders three home tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MaxpeedApp());

    expect(find.text('Inventario'), findsWidgets);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Ventas'), findsOneWidget);
  });
}

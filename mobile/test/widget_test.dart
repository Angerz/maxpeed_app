import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('muestra el login cuando no hay sesión almacenada', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaxpeedApp());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets(
    'restaura la sesión sin conexión: conserva token y no muestra login',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'session_token': 'tok-stored',
        'session_capabilities': '{"can_view_inventory":true}',
      });

      await tester.pumpWidget(const MaxpeedApp());
      await tester.pumpAndSettle();

      // fetchCapabilities() falla sin red en el entorno de test (HTTP 400):
      // la sesión debe conservarse y el usuario NO debe volver al login.
      expect(find.text('Iniciar sesión'), findsNothing);
    },
  );
}

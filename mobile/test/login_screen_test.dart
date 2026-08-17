import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/src/screens/login_screen.dart';
import 'package:mobile/src/services/catalog_api_service.dart';
import 'package:mobile/src/store/session_store.dart';

void main() {
  testWidgets('el toggle muestra y oculta la contraseña', (
    WidgetTester tester,
  ) async {
    final api = CatalogApiService(
      client: MockClient((request) async => http.Response('{}', 200)),
      host: 'api.test',
      port: 80,
      scheme: 'http',
    );
    final store = SessionStore(api);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(sessionStore: store)),
    );

    final passwordField = find.byType(TextFormField).at(1);
    bool isObscured() => tester
        .widget<EditableText>(
          find.descendant(
            of: passwordField,
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;
    expect(isObscured(), isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(isObscured(), isFalse);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(isObscured(), isTrue);
  });
}

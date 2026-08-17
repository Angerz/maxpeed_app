import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/src/models/capabilities.dart';
import 'package:mobile/src/services/catalog_api_service.dart';
import 'package:mobile/src/store/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiService extends CatalogApiService {
  _FakeApiService({required this.onFetchCapabilities});

  final Future<Capabilities> Function() onFetchCapabilities;
  int fetchCapabilitiesCalls = 0;
  bool logoutCalled = false;

  @override
  Future<Capabilities> fetchCapabilities() {
    fetchCapabilitiesCalls += 1;
    return onFetchCapabilities();
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  const tokenKey = 'session_token';
  const capabilitiesKey = 'session_capabilities';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('offline al iniciar: conserva token y sesión, reutiliza capabilities', () async {
    SharedPreferences.setMockInitialValues({
      tokenKey: 'tok-offline',
      capabilitiesKey: '{"can_view_inventory":true}',
    });
    final api = _FakeApiService(
      onFetchCapabilities: () async {
        throw const ApiException('Error de conexión: no hay red');
      },
    );
    final store = SessionStore(api);
    await store.initialize();

    expect(store.isAuthenticated, isTrue);
    expect(api.fetchCapabilitiesCalls, 2);
    expect(store.capabilities.can('can_view_inventory'), isTrue);
    expect(store.isInitializing, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), 'tok-offline');
  });

  test('timeout al iniciar: conserva sesión', () async {
    SharedPreferences.setMockInitialValues({tokenKey: 'tok-timeout'});
    final api = _FakeApiService(
      onFetchCapabilities: () async {
        throw const ApiException('Tiempo de espera agotado al cargar datos');
      },
    );
    final store = SessionStore(api);
    await store.initialize();

    expect(store.isAuthenticated, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), 'tok-timeout');
  });

  test('5xx al iniciar: conserva sesión', () async {
    SharedPreferences.setMockInitialValues({tokenKey: 'tok-5xx'});
    final api = _FakeApiService(
      onFetchCapabilities: () async {
        throw const ApiException('Error del servidor', statusCode: 503);
      },
    );
    final store = SessionStore(api);
    await store.initialize();

    expect(store.isAuthenticated, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), 'tok-5xx');
  });

  test('401 al iniciar: elimina sesión y token (sin reintento)', () async {
    SharedPreferences.setMockInitialValues({tokenKey: 'tok-invalido'});
    final api = _FakeApiService(
      onFetchCapabilities: () async {
        throw const ApiException('Token inválido', statusCode: 401);
      },
    );
    final store = SessionStore(api);
    await store.initialize();

    expect(store.isAuthenticated, isFalse);
    expect(api.fetchCapabilitiesCalls, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), isNull);
  });

  test('403 al iniciar: conserva sesión (token válido sin permiso)', () async {
    SharedPreferences.setMockInitialValues({tokenKey: 'tok-403'});
    final api = _FakeApiService(
      onFetchCapabilities: () async {
        throw const ApiException('Prohibido', statusCode: 403);
      },
    );
    final store = SessionStore(api);
    await store.initialize();

    expect(store.isAuthenticated, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), 'tok-403');
  });

  test('capabilities frescas al iniciar: actualiza y persiste', () async {
    SharedPreferences.setMockInitialValues({
      tokenKey: 'tok-ok',
      capabilitiesKey: '{"can_view_inventory":false}',
    });
    final api = _FakeApiService(
      onFetchCapabilities: () async =>
          const Capabilities({'can_view_inventory': true, 'can_create_sale': true}),
    );
    final store = SessionStore(api);
    await store.initialize();

    expect(store.isAuthenticated, isTrue);
    expect(store.capabilities.can('can_view_inventory'), isTrue);
    expect(api.fetchCapabilitiesCalls, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(capabilitiesKey), contains('can_create_sale'));
  });

  test('logout explícito desde el menú: llama al servidor y limpia sesión', () async {
    SharedPreferences.setMockInitialValues({tokenKey: 'tok-logout'});
    final api = _FakeApiService(
      onFetchCapabilities: () async => const Capabilities(<String, bool>{}),
    );
    final store = SessionStore(api);
    await store.initialize();
    expect(store.isAuthenticated, isTrue);

    await store.logout();

    expect(api.logoutCalled, isTrue);
    expect(store.isAuthenticated, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), isNull);
  });

  test('401 real de fetchCapabilities: dispara el handler de sesión inválida', () async {
    final client = MockClient(
      (request) async => http.Response('{"detail":"Invalid token."}', 401),
    );
    final api = CatalogApiService(
      client: client,
      host: 'api.test',
      port: 80,
      scheme: 'http',
    );
    var unauthorizedCalled = false;
    CatalogApiService.setAuthToken('tok-real');
    CatalogApiService.setUnauthorizedHandler(() {
      unauthorizedCalled = true;
    });

    await expectLater(api.fetchCapabilities(), throwsA(isA<ApiException>()));

    expect(unauthorizedCalled, isTrue);
  });

  test('error de conexión real: NO dispara el handler de sesión inválida', () async {
    final client = MockClient(
      (request) async => throw http.ClientException('No connection'),
    );
    final api = CatalogApiService(
      client: client,
      host: 'api.test',
      port: 80,
      scheme: 'http',
    );
    var unauthorizedCalled = false;
    CatalogApiService.setAuthToken('tok-real');
    CatalogApiService.setUnauthorizedHandler(() {
      unauthorizedCalled = true;
    });

    await expectLater(api.fetchCapabilities(), throwsA(isA<ApiException>()));

    expect(unauthorizedCalled, isFalse);
  });
}
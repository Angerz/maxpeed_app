import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/capabilities.dart';
import '../services/catalog_api_service.dart';

class SessionStore extends ChangeNotifier {
  SessionStore(this._apiService);

  static const _tokenKey = 'session_token';
  static const _capabilitiesKey = 'session_capabilities';
  static const _usernameKey = 'session_username';
  static const _groupsKey = 'session_groups';

  final CatalogApiService _apiService;

  bool _isInitializing = true;
  String? _token;
  Capabilities _capabilities = const Capabilities(<String, bool>{});
  String? _username;
  List<String> _groups = const [];
  bool _justLoggedIn = false;

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;
  String? get username => _username;
  List<String> get groups => _groups;
  Capabilities get capabilities => _capabilities;
  bool get justLoggedIn => _justLoggedIn;

  bool can(String capability) => _capabilities.can(capability);

  void consumeJustLoggedInFlag() {
    if (!_justLoggedIn) {
      return;
    }
    _justLoggedIn = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _groups = prefs.getStringList(_groupsKey) ?? const [];

    final rawCapabilities = prefs.getString(_capabilitiesKey);
    if (rawCapabilities != null && rawCapabilities.trim().isNotEmpty) {
      try {
        _capabilities = Capabilities.fromDynamic(jsonDecode(rawCapabilities));
      } catch (_) {
        _capabilities = const Capabilities(<String, bool>{});
      }
    }

    CatalogApiService.setAuthToken(_token);

    if (isAuthenticated) {
      try {
        final fresh = await _apiService.fetchCapabilities();
        _capabilities = fresh;
        await prefs.setString(_capabilitiesKey, jsonEncode(fresh.toJson()));
      } catch (_) {
        await clearSession(notify: false);
      }
    }

    _isInitializing = false;
    _justLoggedIn = false;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final loginResponse = await _apiService.login(
      username: username,
      password: password,
    );
    _token = loginResponse.token;
    _username = loginResponse.user ?? username;
    _groups = loginResponse.groups;
    _capabilities = loginResponse.capabilities.values.isNotEmpty
        ? loginResponse.capabilities
        : await _apiService.fetchCapabilities();

    CatalogApiService.setAuthToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_usernameKey, _username ?? username);
    await prefs.setStringList(_groupsKey, _groups);
    await prefs.setString(_capabilitiesKey, jsonEncode(_capabilities.toJson()));

    _justLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      // Best effort.
    }
    await clearSession();
  }

  Future<void> clearSession({bool notify = true}) async {
    _token = null;
    _username = null;
    _groups = const [];
    _capabilities = const Capabilities(<String, bool>{});
    _justLoggedIn = false;
    CatalogApiService.setAuthToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_capabilitiesKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_groupsKey);
    if (notify) {
      notifyListeners();
    }
  }
}

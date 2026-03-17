import 'package:flutter/material.dart';
import 'dart:async';

import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'services/catalog_api_service.dart';
import 'store/session_store.dart';

class MaxpeedApp extends StatefulWidget {
  const MaxpeedApp({super.key});

  @override
  State<MaxpeedApp> createState() => _MaxpeedAppState();
}

class _MaxpeedAppState extends State<MaxpeedApp> {
  late final CatalogApiService _apiService;
  late final SessionStore _sessionStore;
  bool _showPostLoginAnimation = false;

  @override
  void initState() {
    super.initState();
    _apiService = CatalogApiService();
    _sessionStore = SessionStore(_apiService);
    CatalogApiService.setUnauthorizedHandler(() {
      _sessionStore.clearSession();
    });
    _sessionStore.addListener(_onSessionChanged);
    _sessionStore.initialize();
  }

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }
    final shouldShow =
        !_sessionStore.isInitializing &&
        _sessionStore.isAuthenticated &&
        _sessionStore.justLoggedIn;
    if (shouldShow && !_showPostLoginAnimation) {
      setState(() {
        _showPostLoginAnimation = true;
      });
      return;
    }
    if (!shouldShow && _showPostLoginAnimation) {
      setState(() {
        _showPostLoginAnimation = false;
      });
    }
  }

  @override
  void dispose() {
    CatalogApiService.setUnauthorizedHandler(null);
    _sessionStore.removeListener(_onSessionChanged);
    _sessionStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandDark = Color(0xFF181C23);
    const brandYellow = Color(0xFFFEC70A);
    const brandOrange = Color(0xFFFC9A10);
    const brandLight = Color(0xFFEBEBE5);
    const brandDarkSoft = Color(0xFF232833);
    const brandBrown = Color(0xFF634C1C);

    return AnimatedBuilder(
      animation: _sessionStore,
      builder: (context, _) {
        final home = _sessionStore.isInitializing
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _showPostLoginAnimation
            ? _PostLoginLogoTransition(
                onCompleted: () {
                  if (!mounted) {
                    return;
                  }
                  _sessionStore.consumeJustLoggedInFlag();
                  setState(() {
                    _showPostLoginAnimation = false;
                  });
                },
              )
            : _sessionStore.isAuthenticated
            ? HomeShell(sessionStore: _sessionStore)
            : LoginScreen(sessionStore: _sessionStore);

        return MaterialApp(
          title: 'Maxpeed',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.dark(
              primary: brandYellow,
              secondary: brandOrange,
              surface: brandDark,
              surfaceContainerHighest: brandDarkSoft,
              onPrimary: brandDark,
              onSecondary: brandDark,
              onSurface: brandLight,
              outline: Color(0xFF969693),
              outlineVariant: Color(0xFFB38D23),
            ),
            scaffoldBackgroundColor: brandDark,
            appBarTheme: const AppBarTheme(
              backgroundColor: brandDark,
              foregroundColor: brandLight,
            ),
            cardTheme: const CardThemeData(
              color: brandDarkSoft,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: brandDarkSoft.withValues(alpha: 0.82),
              labelStyle: const TextStyle(color: brandLight),
              hintStyle: const TextStyle(color: Color(0xFF969693)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x44969693)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x44969693)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: brandYellow, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: brandOrange),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: brandOrange, width: 1.4),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandOrange,
                foregroundColor: brandDark,
                disabledBackgroundColor: brandBrown,
                disabledForegroundColor: brandLight,
                elevation: 0,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: brandYellow,
                foregroundColor: brandDark,
                disabledBackgroundColor: brandBrown,
                disabledForegroundColor: brandLight,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: brandOrange,
                side: const BorderSide(color: brandOrange),
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: brandOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: brandDarkSoft,
              indicatorColor: brandYellow,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: brandYellow,
                    fontWeight: FontWeight.w700,
                  );
                }
                return const TextStyle(color: brandLight);
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: brandDark);
                }
                return const IconThemeData(color: brandLight);
              }),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: brandOrange,
              contentTextStyle: TextStyle(
                color: brandDark,
                fontWeight: FontWeight.w600,
              ),
              actionTextColor: brandDark,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: brandYellow,
              foregroundColor: brandDark,
            ),
          ),
          home: home,
        );
      },
    );
  }
}

class _PostLoginLogoTransition extends StatefulWidget {
  const _PostLoginLogoTransition({required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<_PostLoginLogoTransition> createState() =>
      _PostLoginLogoTransitionState();
}

class _PostLoginLogoTransitionState extends State<_PostLoginLogoTransition> {
  bool _zoom = false;
  bool _completed = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _zoom = true;
      });
    });
    _fallbackTimer = Timer(const Duration(milliseconds: 850), _finish);
  }

  void _finish() {
    if (_completed) {
      return;
    }
    _completed = true;
    _fallbackTimer?.cancel();
    widget.onCompleted();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AnimatedScale(
            scale: _zoom ? 3.0 : 1.0,
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeInCubic,
            onEnd: _finish,
            child: Image.asset(
              'assets/maxpeed.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.local_offer, size: 100),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      ),
    );
  }
}

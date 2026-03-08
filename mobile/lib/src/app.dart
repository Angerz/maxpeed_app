import 'package:flutter/material.dart';

import 'screens/home_shell.dart';

class MaxpeedApp extends StatelessWidget {
  const MaxpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandDark = Color(0xFF181C23);
    const brandYellow = Color(0xFFFEC70A);
    const brandOrange = Color(0xFFFC9A10);
    const brandLight = Color(0xFFEBEBE5);
    const brandDarkSoft = Color(0xFF232833);
    const brandBrown = Color(0xFF634C1C);

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: brandOrange,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      home: const HomeShell(),
    );
  }
}

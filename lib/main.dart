
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sango/screen/homeScreen.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/screen/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Create a ChangeNotifier for locale changes
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr'); // Set French as default

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    try {
      if (!S.supportedLocales.contains(locale)) return;

      _locale = locale;

      // Save to shared preferences with error handling
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);

      notifyListeners();
    } catch (e) {
      print('Error setting locale: $e');
      // Continue with default locale if setting fails
    }
  }

  // Initialize from shared preferences
  Future<void> initLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? languageCode = prefs.getString('language_code');

      if (languageCode != null) {
        _locale = Locale(languageCode);
      }
    } catch (e) {
      print('Error initializing locale: $e');
      // Continue with default French locale
    }
  }
}

void main() async {
  // Set up comprehensive error handling
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    };

    // Set up platform error handling for async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      print('Platform Error: $error');
      print('Stack trace: $stack');
      return true;
    };

    try {
      // Create and initialize the locale provider with error handling
      final localeProvider = LocaleProvider();
      await localeProvider.initLocale();

      runApp(
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => localeProvider,
          child: const MyApp(),
        ),
      );
    } catch (e, stackTrace) {
      print('Critical error during app initialization: $e');
      print('Stack trace: $stackTrace');
      
      // Run a minimal error app if initialization fails
      runApp(const ErrorApp());
    }
  }, (error, stackTrace) {
    print('Uncaught error: $error');
    print('Stack trace: $stackTrace');
  });
}

// Error fallback app
class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sango Taxi',
      home: Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please restart the app',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to the locale provider
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Sango Taxi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFF07723D),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Configure localization
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      locale: localeProvider.locale,
      home: const SplashScreen(),
    );
  }
}

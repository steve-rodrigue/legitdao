import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/main/main_layout.dart';
import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/contact_page.dart';
import 'pages/referrals_page.dart';
import 'pages/marketplaces_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'lib/localization',
      fallbackLocale: const Locale('en'),
      child: MyApp(), // Removed `const` if MyApp is not fully const
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: ThemeData(
        fontFamily: 'HugeIcons',
        scaffoldBackgroundColor: const Color.fromARGB(255, 28, 28, 28),
        colorScheme: ColorScheme(
          primary: Colors.black,
          onPrimary: const Color.fromARGB(255, 207, 149, 33),
          secondary: Colors.white,
          onSecondary: Colors.black,
          brightness: Brightness.dark,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
          bodySmall: TextStyle(fontSize: 12, color: Colors.white),
          headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 207, 149, 33)),
          headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 207, 149, 33)),
          headlineSmall: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 207, 149, 33)),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        // Handle dynamic route `/referrals/:walletAddress`
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'referrals') {
          final walletAddress = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => MainLayout(
              child: ReferralsPage(walletAddress: walletAddress),
            ),
          );
        }

        // Default routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => MainLayout(child: HomePage()),
            );
          case '/about':
            return MaterialPageRoute(
              builder: (context) => MainLayout(child: AboutPage()),
            );
          case '/contact':
            return MaterialPageRoute(
              builder: (context) => MainLayout(child: ContactPage()),
            );
          case '/marketplaces':
            return MaterialPageRoute(
              builder: (context) => MainLayout(child: MarketplacesPage()),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('404 - Page not found'),
                ),
              ),
            );
        }
      },
    );
  }
}

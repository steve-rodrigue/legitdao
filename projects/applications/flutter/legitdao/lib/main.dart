import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'presentation/components/main_layout.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/about_page.dart';
import 'presentation/pages/contact_page.dart';
import 'presentation/pages/referrals.dart';

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
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 12, color: Colors.black87),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainLayout(child: HomePage()),
        '/about': (context) => MainLayout(child: AboutPage()),
        '/contact': (context) => MainLayout(child: ContactPage()),
        '/referrals': (context) => MainLayout(child: Referral()),
      },
    );
  }
}

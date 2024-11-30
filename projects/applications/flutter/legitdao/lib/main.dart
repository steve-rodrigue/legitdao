import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/main/main_layout.dart';
import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/contact_page.dart';
import 'pages/referrals_page.dart';
import 'pages/marketplaces_page.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('fr')],
          path: 'lib/localization',
          fallbackLocale: const Locale('en'),
          child: MyApp(),
        )),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    ReownAppKitModalTheme theme = ReownAppKitModalTheme(
      isDarkMode: themeProvider.isDark(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        theme: themeProvider.getTheme(),
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
                isDarkTheme: themeProvider.isDark(),
                onThemeToggle: () {
                  themeProvider.toggleTheme();
                },
              ),
            );
          }

          // Default routes
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (context) => MainLayout(
                  child: HomePage(),
                  isDarkTheme: themeProvider.isDark(),
                  onThemeToggle: () {
                    themeProvider.toggleTheme();
                  },
                ),
              );
            case '/about':
              return MaterialPageRoute(
                builder: (context) => MainLayout(
                  child: AboutPage(),
                  isDarkTheme: themeProvider.isDark(),
                  onThemeToggle: () {
                    themeProvider.toggleTheme();
                  },
                ),
              );
            case '/contact':
              return MaterialPageRoute(
                builder: (context) => MainLayout(
                  child: ContactPage(),
                  isDarkTheme: themeProvider.isDark(),
                  onThemeToggle: () {
                    themeProvider.toggleTheme();
                  },
                ),
              );
            case '/marketplaces':
              return MaterialPageRoute(
                builder: (context) => MainLayout(
                  child: MarketplacesPage(),
                  isDarkTheme: themeProvider.isDark(),
                  onThemeToggle: () {
                    themeProvider.toggleTheme();
                  },
                ),
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
      ),
    );

    return theme;
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = true;

  bool get isDarkTheme => _isDarkTheme;

  final darkTheme = ThemeData(
    fontFamily: 'HugeIcons',
    colorScheme: ColorScheme(
      primary: Colors.white,
      onPrimary: const Color.fromARGB(255, 28, 28, 28),
      secondary: Colors.white,
      onSecondary: const Color.fromARGB(255, 28, 28, 28),
      brightness: Brightness.light,
      error: Colors.red,
      onError: Colors.white,
      surface: const Color.fromARGB(255, 28, 28, 28),
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
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(fontSize: 16, color: Colors.white),
    ),
  );

  final lightTheme = ThemeData(
    fontFamily: 'HugeIcons',
    colorScheme: ColorScheme(
      primary: Colors.white,
      onPrimary: const Color.fromARGB(255, 28, 28, 28),
      secondary: Colors.white,
      onSecondary: const Color.fromARGB(255, 28, 28, 28),
      brightness: Brightness.light,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.white,
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
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(fontSize: 16, color: Colors.white),
    ),
  );

  ThemeData getTheme() {
    return _isDarkTheme ? darkTheme : lightTheme;
  }

  bool isDark() {
    return isDarkTheme;
  }

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }
}

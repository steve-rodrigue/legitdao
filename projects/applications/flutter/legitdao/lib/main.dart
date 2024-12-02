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

    final MaterialPageRoute notFoundPage = MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: MainLayout(
            child: Center(
              // Centering the text horizontally and vertically
              child: Text(
                '404 - Wallet Address Not Found',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            isDarkTheme: themeProvider.isDark(),
            onThemeToggle: () {
              themeProvider.toggleTheme();
            },
          ),
        ),
      ),
    );

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

            // Check if walletAddress is null or empty
            if (walletAddress.isEmpty) {
              return notFoundPage;
            }

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
              return notFoundPage;
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
    fontFamily: 'SourceSerif',
    colorScheme: ColorScheme(
      primary: Colors.white,
      onPrimary: const Color.fromARGB(255, 28, 28, 28),
      secondary: Colors.white,
      onSecondary: const Color.fromARGB(255, 28, 28, 28),
      brightness: Brightness.dark,
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
    // Customize TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: const BorderSide(
            color: Color.fromARGB(255, 207, 149, 33), // Border color
            width: 2.0, // Border width
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(fontSize: 16, color: Colors.white),
    ),
  );

  final lightTheme = ThemeData(
    fontFamily: 'SourceSerif',
    colorScheme: ColorScheme(
      primary: const Color.fromARGB(255, 28, 28, 28),
      onPrimary: Colors.white,
      secondary: const Color.fromARGB(255, 28, 28, 28),
      onSecondary: Colors.white,
      brightness: Brightness.light,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: const Color.fromARGB(255, 28, 28, 28),
    ),
    textTheme: const TextTheme(
      bodyLarge:
          TextStyle(fontSize: 16, color: const Color.fromARGB(255, 28, 28, 28)),
      bodyMedium:
          TextStyle(fontSize: 14, color: const Color.fromARGB(255, 28, 28, 28)),
      bodySmall:
          TextStyle(fontSize: 12, color: const Color.fromARGB(255, 28, 28, 28)),
      headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 28, 28, 28)),
      headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 28, 28, 28)),
      headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: const Color.fromARGB(255, 28, 28, 28)),
    ),
    // Customize TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: const BorderSide(
            color: const Color.fromARGB(255, 0, 0, 0),
            width: 2.0, // Border width
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
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

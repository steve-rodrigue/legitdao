import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../logos/responsive_logo.dart';
import '../../visuals/buttons/connect_button.dart';
import '../../networks/network_manager_interface.dart';
import '../../visuals/buttons/hover_link.dart';

class TopSection extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;
  final Function() onLeftMenuToggle;
  final Function() onDisconnect;
  final NetworkManager networkManager;

  const TopSection({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
    required this.onLeftMenuToggle,
    required this.onDisconnect,
    required this.networkManager,
  });

  @override
  _TopSectionState createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection> {
  bool showHamburgerMenu = false;
  bool isDark = true;
  String darkLogo = 'lib/assets/images/logo-darkmode.png';
  String lightLogo = 'lib/assets/images/logo.png';
  String currentLogo = '';

  @override
  void initState() {
    super.initState();
    isDark = widget.isDark;
    currentLogo = isDark ? darkLogo : lightLogo;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMenuVisibility();
  }

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
      currentLogo = isDark ? darkLogo : lightLogo;
    });
  }

  void _updateMenuVisibility() {
    final totalWidth = MediaQuery.of(context).size.width;

    // Dynamically determine whether to show the hamburger menu
    setState(() {
      showHamburgerMenu =
          totalWidth < 800; // Adjust threshold for responsiveness
    });
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 20),
      child: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
                child: ResponsiveLogo(
                  logoPath: currentLogo,
                ),
              ),
              const Spacer(),

              // Menu Items for Large Screens
              if (!showHamburgerMenu)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Home
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: HoverLink(
                        text: "menu_home".tr(),
                        isInMenu: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/');
                        },
                      ),
                    ),

                    // Tokens
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: HoverLink(
                        text: "menu_tokens".tr(),
                        isInMenu: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/tokens');
                        },
                      ),
                    ),

                    // About
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: HoverLink(
                        text: "menu_about".tr(),
                        isInMenu: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                    ),

                    // Contact
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: HoverLink(
                        text: "menu_contact".tr(),
                        isInMenu: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/contact');
                        },
                      ),
                    ),
                  ],
                ),
              const Spacer(),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Language Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: DropdownButton<Locale>(
                      value: context.locale,
                      icon: const Icon(
                        Icons.language,
                      ),
                      underline: Container(),
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: Locale('en'),
                          child: Text("EN"),
                        ),
                        DropdownMenuItem(
                          value: Locale('fr'),
                          child: Text("FR"),
                        ),
                      ],
                    ),
                  ),

                  // Theme Switcher
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: IconButton(
                      icon: Icon(
                        widget.isDark ? Icons.light_mode : Icons.dark_mode,
                        size: 40,
                      ),
                      onPressed: () {
                        toggleTheme();
                        widget.onThemeToggle();
                      },
                      tooltip: 'Switch Theme',
                    ),
                  ),

                  // Hamburger Menu for Small Screens
                  if (showHamburgerMenu)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.menu,
                        ),
                        onPressed: widget.onLeftMenuToggle,
                      ),
                    ),

                  // Connect Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: ConnectButton(
                      connectLabel: "Connect",
                      disconnectLabel: "Profile",
                      onDisconnect: widget.onDisconnect,
                      networkManager: widget.networkManager,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

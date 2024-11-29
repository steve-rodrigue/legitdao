import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../logos/responsive_logo.dart';
import '../../connections/connect_button.dart';
import '../../networks/network_manager_interface.dart';

class TopSection extends StatefulWidget {
  final Function() onLeftMenuToggle;
  final Function() onRightMenuToggle;
  final NetworkManager networkManager;

  const TopSection({
    super.key,
    required this.onLeftMenuToggle,
    required this.onRightMenuToggle,
    required this.networkManager,
  });

  @override
  _TopSectionState createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection> {
  bool showHamburgerMenu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMenuVisibility();
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
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
                child: ResponsiveLogo(
                  logoPath: 'lib/assets/images/logo-darkmode.png',
                ),
              ),
              const Spacer(),

              // Menu Items for Large Screens
              if (!showHamburgerMenu)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 207, 149, 33),
                      ),
                      child: const Text("menu_home").tr(),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/about'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 207, 149, 33),
                      ),
                      child: const Text("menu_about").tr(),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/contact'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 207, 149, 33),
                      ),
                      child: const Text("menu_contact").tr(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: DropdownButton<Locale>(
                      value: context.locale,
                      icon: const Icon(
                        Icons.language,
                        color: Colors.white,
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

                  // Hamburger Menu for Small Screens
                  if (showHamburgerMenu)
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                        ),
                        onPressed: widget.onLeftMenuToggle,
                      ),
                    ),

                  // Connect Button
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ConnectButton(
                      onMenuToggle: widget.onRightMenuToggle,
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

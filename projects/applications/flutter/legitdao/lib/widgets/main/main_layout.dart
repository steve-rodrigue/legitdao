import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../networks/network_manager_widget.dart';
import '../menus/left/left_sliding_menu.dart';
import '../menus/right/right_sliding_menu.dart';
import '../menus/top/top_section.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final VoidCallback onThemeToggle;

  const MainLayout({
    Key? key,
    required this.isDark,
    required this.onThemeToggle,
    required this.child,
  }) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isLeftMenuVisible = false;
  bool _isRightMenuVisible = false;

  void _toggleLeftMenu() {
    setState(() {
      _isLeftMenuVisible = !_isLeftMenuVisible;
    });
  }

  void _closeLeftMenu() {
    if (_isLeftMenuVisible) {
      setState(() {
        _isLeftMenuVisible = false;
      });
    }
  }

  void _toggleRightMenu() {
    setState(() {
      _isRightMenuVisible = !_isRightMenuVisible;
    });
  }

  void _closeRightMenu() {
    if (_isRightMenuVisible) {
      setState(() {
        _isRightMenuVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkManagerWidget(
      builder: (context, networkManager) {
        return Scaffold(
          body: SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _closeAllMenus,
                    child: Column(
                      children: [
                        TopSection(
                          isDark: widget.isDark,
                          onThemeToggle: widget.onThemeToggle,
                          networkManager: networkManager,
                          onLeftMenuToggle: _toggleLeftMenu,
                          onDisconnect: () {
                            _toggleRightMenu();
                          },
                        ),
                        Expanded(
                          child: KeyedSubtree(
                            key: ValueKey(EasyLocalization.of(context)!.locale),
                            child: Scaffold(
                              body: Scrollbar(
                                thumbVisibility: false,
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: widget.child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  LeftSlidingMenu(
                    isVisible: _isLeftMenuVisible,
                    onClose: _closeLeftMenu,
                    networkManager: networkManager,
                  ),
                  RightSlidingMenu(
                    isDark: widget.isDark,
                    isVisible: _isRightMenuVisible,
                    onClose: _closeRightMenu,
                    networkManager: networkManager,
                    onDisconnected: () async {
                      await networkManager.disconnectWallet();
                      _closeRightMenu();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeAllMenus() {
    _closeLeftMenu();
    _closeRightMenu();
  }
}

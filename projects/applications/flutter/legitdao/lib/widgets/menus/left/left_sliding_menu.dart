import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../networks/network_manager_interface.dart';

class LeftSlidingMenu extends StatefulWidget {
  final bool isVisible;
  final Function() onClose;
  final NetworkManager networkManager;

  const LeftSlidingMenu({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.networkManager,
  });

  @override
  _LeftSlidingMenuState createState() => _LeftSlidingMenuState();
}

class _LeftSlidingMenuState extends State<LeftSlidingMenu> {
  late bool _isVisible;
  late NetworkManager _networkManager;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.isVisible;
    _networkManager = widget.networkManager;
  }

  @override
  void didUpdateWidget(covariant LeftSlidingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      setState(() {
        _isVisible = widget.isVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      left: _isVisible ? 0 : -screenWidth * 0.6,
      width: screenWidth * 0.6,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              width: 2.0,
            ),
          ),
        ),
        child: Material(
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // X Close Button
              Container(
                padding: const EdgeInsets.all(16.0), // Optional padding
                child: Align(
                  alignment: Alignment.topRight, // Align to the top-right
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Background color
                      borderRadius:
                          BorderRadius.circular(8.0), // Rounded corners
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.black, // Icon color
                      onPressed: () {
                        widget.onClose();
                      },
                    ),
                  ),
                ),
              ),
              // Menu Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Home
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/')
                                .then((_) => widget.onClose());
                          },
                          child: Text(
                            "menu_home".tr(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // About
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/about')
                                .then((_) => widget.onClose());
                          },
                          child: Text(
                            "menu_about".tr(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Contact
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/contact')
                                .then((_) => widget.onClose());
                          },
                          child: Text(
                            "menu_contact".tr(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

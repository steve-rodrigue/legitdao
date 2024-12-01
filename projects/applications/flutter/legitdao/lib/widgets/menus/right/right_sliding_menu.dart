import 'package:flutter/material.dart';
import '../../networks/network_manager_interface.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../widgets/networks/reown/connection_dashboard.dart';
import '../../visuals/hover_link.dart';

class RightSlidingMenu extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final NetworkManager networkManager;
  final VoidCallback onDisconnected;

  const RightSlidingMenu({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.networkManager,
    required this.onDisconnected,
  });

  @override
  _RightSlidingMenuState createState() => _RightSlidingMenuState();
}

class _RightSlidingMenuState extends State<RightSlidingMenu> {
  double _displayedBalance = 0.0;
  late NetworkManager _networkManager;

  @override
  void didUpdateWidget(covariant RightSlidingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initialize();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    _networkManager = widget.networkManager;
  }

  Future<void> _initialize() async {
    try {
      _updateBalance();

      setState(() {});
    } catch (e) {
      print('Error initializing networks: $e');
    }
  }

  Future<void> _updateBalance() async {
    try {
      final balance = await widget.networkManager
          .fetchBalance(widget.networkManager.getConnectedWallet());
      setState(() {
        _displayedBalance = balance;
      });
    } catch (e) {
      print('Error fetching balance: $e');
      setState(() {
        _displayedBalance = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: widget.isVisible ? 0 : -MediaQuery.of(context).size.width * 0.6,
      width: MediaQuery.of(context).size.width * 0.5,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 2.0,
            ),
          ),
        ),
        child: Material(
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // X Close Button
              Container(
                padding: const EdgeInsets.all(16.0), // Optional padding
                child: Align(
                  alignment: Alignment.topLeft, // Align to the top-left
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

              // Menu Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Marketplaces
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: HoverLink(
                          text: "right_menu_marketplaces".tr(),
                          isInMenu: true,
                          onTap: () {
                            Navigator.pushNamed(context, '/marketplaces')
                                .then((_) => widget.onClose());
                          },
                        ),
                      ),

                      // Referrals
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: HoverLink(
                          text: "right_menu_referrals".tr(),
                          isInMenu: true,
                          onTap: () {
                            Navigator.pushNamed(context,
                                    '/referrals/${_networkManager.getConnectedWallet()}')
                                .then((_) => widget.onClose());
                          },
                        ),
                      ),

                      // Connection Board:
                      ConnectionDashboard(networkManager: _networkManager),

                      Text('Address: ${_networkManager.getConnectedWallet()}'),
                      Text('Balance: ${_displayedBalance}'),
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

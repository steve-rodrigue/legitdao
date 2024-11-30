import 'package:flutter/material.dart';
import '../../networks/network_manager_interface.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../widgets/networks/reown/network_manager_reown.dart';
import '../../../widgets/networks/reown/connection_dashboard.dart';

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
  String _selectedNetwork = '';
  double _displayedBalance = 0.0;
  List<String> _networks = [];
  late NetworkManager _networkManager;

  /*@override
  void didUpdateWidget(covariant RightSlidingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initialize();
  }*/

  @override
  void initState() {
    super.initState();
    _initialize();
    _networkManager = widget.networkManager;
  }

  Future<void> _initialize() async {
    try {
      final networks = await widget.networkManager.getAvailableNetworks();
      final currentNetwork = await widget.networkManager.getCurrentNetwork();
      _updateBalance();

      setState(() {
        _networks = networks;
        _selectedNetwork = currentNetwork;
      });
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

  Future<void> _switchNetwork(String networkName) async {
    try {
      await widget.networkManager.selectNetwork(networkName);
      setState(() {
        _selectedNetwork = networkName;
      });
      _updateBalance(); // Update the balance after switching networks
    } catch (e) {
      print('Error switching network: $e');
    }
  }

  Future<void> _disconnectWallet() async {
    try {
      await widget.networkManager.disconnectWallet();
      widget.onDisconnected();
      widget.onClose();
    } catch (e) {
      print('Error disconnecting wallet: $e');
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
      width: MediaQuery.of(context).size.width * 0.6,
      child: Material(
        color: Color.fromARGB(255, 207, 149, 33),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 80,
              color: Colors.blue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Menu",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            // Menu Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection Board:
                    ConnectionDashboard(networkManager: _networkManager),

                    // Marketplaces
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/marketplaces')
                              .then((_) => widget.onClose());
                        },
                        child: Text(
                          "right_menu_marketplaces".tr(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Referrals
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/referrals')
                              .then((_) => widget.onClose());
                        },
                        child: Text(
                          "right_menu_referrals".tr(),
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
    );
  }
}

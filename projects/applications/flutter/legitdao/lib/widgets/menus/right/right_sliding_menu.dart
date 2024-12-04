import 'package:flutter/material.dart';
import '../../networks/network_manager_interface.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../widgets/networks/reown/connection_dashboard.dart';
import '../../visuals/hover_link.dart';
import '../../visuals/piecharts/custom_piechart_with_network_selector.dart';
import '../../visuals/piecharts/cryptocurrency.dart';

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
    final width = MediaQuery.of(context).size.width * 0.5;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: widget.isVisible ? 0 : -MediaQuery.of(context).size.width * 0.6,
      width: width,
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

                      const SizedBox(height: 20),

                      // Pie chart with network selector:
                      Center(
                        child: CustomPieChartWithNetworkSelector(
                          width: width * 0.9,
                          cryptocurrencies: [
                            Cryptocurrency(
                                logoPath:
                                    'lib/assets/icons/svg/cryptocurrencies/color/bnb.svg',
                                symbol: 'BNB',
                                color: Colors.yellow,
                                amount: 500,
                                usdtValue: 320),
                            Cryptocurrency(
                                logoPath:
                                    'lib/assets/icons/svg/cryptocurrencies/color/eth.svg',
                                symbol: 'ETH',
                                color: Colors.purple,
                                amount: 300,
                                usdtValue: 2000),
                            Cryptocurrency(
                                logoPath:
                                    'lib/assets/icons/svg/cryptocurrencies/color/bab.svg',
                                symbol: 'WebX',
                                color: Colors.blue,
                                amount: 200,
                                usdtValue: 1000),
                            Cryptocurrency(
                                logoPath:
                                    'lib/assets/icons/svg/cryptocurrencies/color/grt.svg',
                                symbol: 'GRT',
                                color: Colors.deepPurple,
                                amount: 500,
                                usdtValue: 500),
                            Cryptocurrency(
                                logoPath:
                                    'lib/assets/icons/svg/cryptocurrencies/color/etp.svg',
                                symbol: 'CAKE',
                                color: Colors.brown,
                                amount: 4500,
                                usdtValue: 2000),
                          ],
                          networkManager: _networkManager,
                        ),
                      ),

                      const SizedBox(height: 20),

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

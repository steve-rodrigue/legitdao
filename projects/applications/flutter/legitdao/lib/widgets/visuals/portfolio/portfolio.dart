import 'package:flutter/material.dart';
import '../piecharts/custom_pie_chart.dart';
import '../piecharts/cryptocurrency.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../../networks/reown/network_manager_reown.dart';
import '../../networks/network_manager_interface.dart';
import '../buttons/connect_button.dart';
import '../containers/custom_title_container.dart';

class Portfolio extends StatefulWidget {
  final bool isDark;
  final List<Cryptocurrency> cryptocurrencies;
  final double width;
  final Function() onDisconnect;
  final NetworkManager networkManager;

  const Portfolio({
    Key? key,
    required this.isDark,
    required this.cryptocurrencies,
    required this.width,
    required this.onDisconnect,
    required this.networkManager,
  }) : super(key: key);

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  late NetworkManagerImpl castedAppKit;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    castedAppKit = widget.networkManager as NetworkManagerImpl;
  }

  void _onTouch(int _touchedIndex) {
    setState(() {
      touchedIndex = _touchedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Cryptocurrency> cryptocurrencies = widget.cryptocurrencies;
    final double width = widget.width;
    final networkManager = widget.networkManager;

    return CustomTitleContainer(isDark: widget.isDark, title: [
      Text(
        "Portfolio",
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Visibility(
        visible: castedAppKit.getAppKitModal().isConnected,
        child: AppKitModalAccountButton(
            appKitModal: castedAppKit.getAppKitModal()),
      ),
    ], body: [
      const SizedBox(height: 20),
      Center(
        child: CustomPieChart(
          cryptocurrencies: cryptocurrencies,
          width: width,
          touchedIndex: touchedIndex,
          onTouch: _onTouch,
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppKitModalNetworkSelectButton(appKit: castedAppKit.getAppKitModal()),
          ConnectButton(
              connectLabel: "Connect",
              disconnectLabel: "Disconnect",
              onDisconnect: widget.onDisconnect,
              networkManager: networkManager),
        ],
      ),
    ]);
  }
}

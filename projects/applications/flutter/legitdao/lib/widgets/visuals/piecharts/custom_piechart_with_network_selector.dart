import 'package:flutter/material.dart';
import 'custom_pie_chart.dart';
import 'cryptocurrency.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../../networks/reown/network_manager_reown.dart';
import '../../networks/network_manager_interface.dart';
import '../../networks/reown/connection_dashboard.dart';

class CustomPieChartWithNetworkSelector extends StatefulWidget {
  final List<Cryptocurrency> cryptocurrencies;
  final double width;
  final NetworkManager networkManager;

  const CustomPieChartWithNetworkSelector({
    Key? key,
    required this.cryptocurrencies,
    required this.width,
    required this.networkManager,
  }) : super(key: key);

  @override
  State<CustomPieChartWithNetworkSelector> createState() =>
      _CustomPieChartWithNetworkSelectorState();
}

class _CustomPieChartWithNetworkSelectorState
    extends State<CustomPieChartWithNetworkSelector> {
  late NetworkManagerImpl castedAppKit;

  @override
  void initState() {
    super.initState();
    castedAppKit = widget.networkManager as NetworkManagerImpl;
  }

  void _onTouch(int? touchIndex) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Cryptocurrency> cryptocurrencies = widget.cryptocurrencies;
    final double width = widget.width;
    final networkManager = widget.networkManager;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Portfolio",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Visibility(
                visible: castedAppKit.getAppKitModal().isConnected,
                child: AppKitModalAccountButton(
                    appKitModal: castedAppKit.getAppKitModal()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: CustomPieChart(
              cryptocurrencies: cryptocurrencies,
              width: width,
              onTouch: _onTouch,
            ),
          ),
          const SizedBox(height: 20),
          ConnectionDashboard(networkManager: networkManager),
        ],
      ),
    );
  }
}

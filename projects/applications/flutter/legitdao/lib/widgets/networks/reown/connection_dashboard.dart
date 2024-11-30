import 'package:flutter/material.dart';
import 'network_manager_reown.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../network_manager_interface.dart';

class ConnectionDashboard extends StatefulWidget {
  final NetworkManager networkManager; // Accept NetworkManagerImpl instance

  ConnectionDashboard({
    Key? key,
    required this.networkManager,
  }) : super(key: key);

  @override
  _ConnectionDashboardState createState() => _ConnectionDashboardState();
}

class _ConnectionDashboardState extends State<ConnectionDashboard> {
  late NetworkManagerImpl castedAppKit;

  @override
  void initState() {
    super.initState();
    castedAppKit = widget.networkManager as NetworkManagerImpl;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppKitModalNetworkSelectButton(appKit: castedAppKit.getAppKitModal()),
        AppKitModalConnectButton(appKit: castedAppKit.getAppKitModal()),
        Visibility(
          visible: castedAppKit.getAppKitModal().isConnected,
          child: AppKitModalAccountButton(
              appKitModal: castedAppKit.getAppKitModal()),
        ),
      ],
    );
  }
}

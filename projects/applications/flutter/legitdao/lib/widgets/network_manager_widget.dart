import 'package:flutter/material.dart';
import 'network_manager_interface.dart';
import 'network_manager_web.dart'
    if (dart.library.io) 'network_manager_reown.dart';

class NetworkManagerWidget extends StatefulWidget {
  final Widget Function(BuildContext context, NetworkManager networkManager)
      builder;

  const NetworkManagerWidget({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  _NetworkManagerWidgetState createState() => _NetworkManagerWidgetState();
}

class _NetworkManagerWidgetState extends State<NetworkManagerWidget> {
  late final NetworkManager _networkManager;

  @override
  void initState() {
    super.initState();
    _networkManager = _createNetworkManager(context); // Pass context here
  }

  NetworkManager _createNetworkManager(BuildContext context) {
    return NetworkManagerImpl(context); // Pass BuildContext to the constructor
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _networkManager);
  }
}

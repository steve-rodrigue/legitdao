import 'package:flutter/material.dart';
import '../../networks/network_manager_interface.dart';
import 'dart:async';

class ConnectButton extends StatefulWidget {
  final String connectLabel;
  final String disconnectLabel;
  final Function() onDisconnect;
  final NetworkManager networkManager; // Injected NetworkManager

  const ConnectButton({
    super.key,
    required this.connectLabel,
    required this.disconnectLabel,
    required this.onDisconnect,
    required this.networkManager,
  });

  @override
  _ConnectButtonState createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNetworkManager();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print('App moved to background');
    } else if (state == AppLifecycleState.resumed) {
      print('App resumed');
    }
  }

  // Initializes the NetworkManager and sets event listeners
  Future<void> _initializeNetworkManager() async {
    try {
      await widget.networkManager.ensureInitialized();

      // Check initial connection
      if (widget.networkManager.isWalletConnected()) {
        _updateWalletConnection();
      }

      // Set up event listeners
      widget.networkManager.addWalletConnectedListener((walletAddress) {
        _updateWalletConnection();
      });

      widget.networkManager.addWalletDisconnectedListener(() {
        _updateWalletConnection();
      });

      widget.networkManager.addNetworkChangedListener((networkName) {
        _handleNetworkChanged(networkName);
      });
    } catch (e) {
      print('Error initializing NetworkManager: $e');
    }
  }

  // Updates wallet connection state
  void _updateWalletConnection() {
    setState(() {});
  }

  // Handles network change
  void _handleNetworkChanged(String networkName) {
    print('Network changed to: $networkName');
    setState(() {});
  }

  Future<void> connectWallet(BuildContext context) async {
    try {
      // Trigger the wallet connection using the network manager
      await widget.networkManager.connectWallet(context);

      // After triggering the connection, retrieve the connected wallet address
      final walletAddress = widget.networkManager.getConnectedWallet();

      // Update the connection status and wallet address if connected
      if (walletAddress.isNotEmpty) {
        print('Wallet connected: $walletAddress');
        _updateWalletConnection();
      } else {
        print('Wallet connection failed.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Wallet connection failed. Please try again.')),
        );
      }
    } catch (e) {
      print('Error connecting wallet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting wallet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.networkManager.isWalletConnected();
    final screenWidth = MediaQuery.of(context).size.width;

    // Define a breakpoint for small vs. large screens
    const double breakpoint = 600;

    return screenWidth > breakpoint
        ? TextButton(
            onPressed: isConnected
                ? widget.onDisconnect // Disconnect when connected
                : () => connectWallet(context), // Connect when not connected
            child: Text(
              isConnected ? widget.disconnectLabel : widget.connectLabel,
            ),
          )
        : IconButton(
            onPressed: isConnected
                ? widget.onDisconnect // Disconnect when connected
                : () => connectWallet(context), // Connect when not connected
            icon: Icon(
              isConnected ? Icons.logout : Icons.login,
              color: Theme.of(context).colorScheme.primary, // Match theme color
            ),
            tooltip: isConnected ? widget.disconnectLabel : widget.connectLabel,
          );
  }
}

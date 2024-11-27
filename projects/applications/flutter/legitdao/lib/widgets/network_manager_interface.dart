import 'package:flutter/material.dart';

abstract class NetworkManager {
  // Selects a network by name.
  Future<void> selectNetwork(String networkName);

  // Fetches the balance for the connected wallet.
  Future<double> fetchBalance(String walletAddress);

  Future<void> connectWallet(BuildContext context);

  // Returns true if the network can be disconnected, false otherwise
  bool canBeDisconnected();

  // Disconnects the wallet.
  Future<void> disconnectWallet();

  // Returns true if the wallet is connected, false otherwise.
  bool isWalletConnected();

  // Returns the connected wallet, an empty string otherwise.
  String getConnectedWallet();

  // Ensures the network manager is initialized.
  Future<void> ensureInitialized();

  // Returns the current network's chain ID as a string.
  Future<String> getCurrentChainId();

  // Adds a listener for wallet connection events.
  void addWalletConnectedListener(Function(String walletAddress) callback);

  // Adds a listener for wallet disconnection events.
  void addWalletDisconnectedListener(Function() callback);

  // Adds a listener for network change events.
  void addNetworkChangedListener(Function(String chainId) callback);

  // Returns the available networks
  Future<List<String>> getAvailableNetworks();

  // Return the current network
  Future<String> getCurrentNetwork();
}

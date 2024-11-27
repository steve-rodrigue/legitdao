import 'dart:async';
import 'package:flutter_web3/flutter_web3.dart';
import 'network_manager_interface.dart';
import 'package:flutter/material.dart';

class NetworkManagerImpl implements NetworkManager {
  bool _isInitialized = false;
  String _walletAddress = '';
  int _currentChainId = 1; // Default to Ethereum Mainnet
  Function(String walletAddress)? onWalletConnected;
  Function()? onWalletDisconnected;
  Function(String chainId)? onNetworkChanged;

  final Map<int, NetworkInfo> networks = {
    1: NetworkInfo(
      name: 'Ethereum',
      chainId: 1,
      currency: 'ETH',
      rpcUrl: 'https://eth.llamarpc.com',
      explorerUrl: 'https://etherscan.io',
    ),
    56: NetworkInfo(
      name: 'Binance Smart Chain',
      chainId: 56,
      currency: 'BNB',
      rpcUrl: 'https://bsc-dataseed.binance.org/',
      explorerUrl: 'https://bscscan.com',
    ),
  };

  NetworkManagerImpl(BuildContext context);

  // Initializes Web3
  @override
  Future<void> ensureInitialized() async {
    if (_isInitialized || ethereum == null) return;

    print('Initializing Web3...');
    if (ethereum!.selectedAddress != null) {
      _walletAddress = ethereum!.selectedAddress!;
      _currentChainId = await ethereum!.getChainId();
    }

    _isInitialized = true;

    // Add listeners
    ethereum!.onAccountsChanged((accounts) {
      if (accounts.isEmpty) {
        print('Wallet disconnected');
        _walletAddress = '';
        onWalletDisconnected?.call();
      } else {
        print('Wallet connected: ${accounts.first}');
        _walletAddress = accounts.first;
        onWalletConnected?.call(_walletAddress);
      }
    });

    ethereum!.onChainChanged((chainId) {
      _currentChainId = chainId;
      onNetworkChanged?.call(chainId.toString());
      print('Chain changed: $_currentChainId');
    });

    print('Web3 initialized successfully.');
  }

  @override
  bool canBeDisconnected() {
    return false;
  }

  @override
  Future<void> disconnectWallet() async {}

  @override
  bool isWalletConnected() {
    return _walletAddress.isNotEmpty;
  }

  @override
  String getConnectedWallet() {
    return _walletAddress;
  }

  @override
  Future<void> selectNetwork(String networkName) async {
    final network = networks.values.firstWhere(
      (net) => net.name == networkName,
      orElse: () => throw Exception('Network not found: $networkName'),
    );

    if (_currentChainId == network.chainId) {
      print('Already connected to ${network.name}.');
      return;
    }

    try {
      await ethereum!.walletSwitchChain(network.chainId);
      _currentChainId = network.chainId;
      print('Switched to network: ${network.name}');
    } catch (e) {
      throw Exception('Failed to switch network: $e');
    }
  }

  Future<void> connectWallet(BuildContext context) async {
    try {
      if (ethereum == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MetaMask is not available')),
        );
        return;
      }

      // Request MetaMask to connect
      print('Requesting MetaMask connection...');
      final accounts = await ethereum!.requestAccount();

      if (accounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No accounts found. Please try again.')),
        );
        return;
      }

      // Use the first account returned by MetaMask
      final walletAddress = accounts.first;

      print('Wallet connected: $walletAddress');
    } catch (e) {
      print('Error connecting wallet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting wallet: $e')),
      );
    }
  }

  @override
  Future<double> fetchBalance(String walletAddress) async {
    if (!_isInitialized) {
      throw Exception('Web3 is not initialized.');
    }

    if (_walletAddress.isEmpty) {
      throw Exception('Wallet is not connected.');
    }

    try {
      final balanceBigInt = await provider!.getBalance(walletAddress);
      final balanceInEther = balanceBigInt.toDouble() / 1e18;
      print('Balance for $walletAddress: $balanceInEther ETH');
      return balanceInEther;
    } catch (e) {
      throw Exception('Error fetching balance: $e');
    }
  }

  @override
  Future<String> getCurrentChainId() async {
    if (!_isInitialized) {
      throw Exception('Web3 is not initialized.');
    }
    return _currentChainId.toString();
  }

  @override
  void addWalletConnectedListener(Function(String walletAddress) callback) {
    onWalletConnected = callback;
  }

  @override
  void addWalletDisconnectedListener(Function() callback) {
    onWalletDisconnected = callback;
  }

  @override
  void addNetworkChangedListener(Function(String chainId) callback) {
    onNetworkChanged = callback;
  }

  @override
  Future<List<String>> getAvailableNetworks() async {
    try {
      return networks.values.map((network) => network.name).toList();
    } catch (e) {
      throw Exception('Error fetching available networks: $e');
    }
  }

  @override
  Future<String> getCurrentNetwork() async {
    if (!_isInitialized) {
      throw Exception('Web3 is not initialized.');
    }
    final currentNetwork = networks[_currentChainId]?.name ?? 'Unknown Network';
    print('Current network: $currentNetwork');
    return currentNetwork;
  }
}

class NetworkInfo {
  final String
      name; // Name of the network (e.g., Ethereum, Binance Smart Chain)
  final int chainId; // Chain ID (e.g., 1 for Ethereum, 56 for BNB)
  final String currency; // Currency symbol (e.g., ETH, BNB)
  final String rpcUrl; // RPC URL for connecting to the network
  final String explorerUrl; // URL for the block explorer

  NetworkInfo({
    required this.name,
    required this.chainId,
    required this.currency,
    required this.rpcUrl,
    required this.explorerUrl,
  });
}

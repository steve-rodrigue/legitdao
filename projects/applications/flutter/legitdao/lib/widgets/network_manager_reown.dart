import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'network_manager_interface.dart';

class NetworkManagerImpl implements NetworkManager {
  late final ReownAppKitModal appKitModal;
  bool _isInitialized = false;
  String _walletAddress = '';
  int _currentChainId = 1; // Default to Ethereum Mainnet

  final Map<int, ReownAppKitModalNetworkInfo> networks = {
    0: ReownAppKitModalNetworkInfo(
      name: 'Ethereum',
      chainId: '1',
      currency: 'ETH',
      rpcUrl: 'https://eth.llamarpc.com',
      explorerUrl: 'https://etherscan.io',
    ),
    1: ReownAppKitModalNetworkInfo(
      name: 'Binance Smart Chain',
      chainId: '56',
      currency: 'BNB',
      rpcUrl: 'https://bsc-dataseed.binance.org/',
      explorerUrl: 'https://bscscan.com',
    ),
  };

  final List<VoidCallback> _networkChangedListeners = [];
  final List<VoidCallback> _walletConnectedListeners = [];
  final List<VoidCallback> _walletDisconnectedListeners = [];

  NetworkManagerImpl(BuildContext context) {
    appKitModal = _initializeAppKitModal(context);
  }

  ReownAppKitModal _initializeAppKitModal(BuildContext context) {
    return ReownAppKitModal(
      context: context,
      projectId: 'e809b3031729dba863aab7b6089f245f',
      metadata: const PairingMetadata(
        name: 'LegitDAO',
        description: 'This is the LegitDAO application',
        url: 'https://legitdao.com/',
        icons: [
          'https://legitdao.com/images/logo-darkmode_hu16244584204667911519.webp'
        ],
        redirect: Redirect(
          native: 'legitdao://',
          universal: 'https://legitdao.com/app',
        ),
      ),
    );
  }

  Future<void> _initializeModal() async {
    if (_isInitialized) return;
    try {
      print('Initializing ReownAppKitModal...');
      await Future.any([
        appKitModal.init(),
        Future.delayed(const Duration(seconds: 5), () {
          throw TimeoutException('Initialization timed out');
        }),
      ]);
      _isInitialized = true;
      print('ReownAppKitModal initialized successfully.');

      // Add listeners for network and wallet events
      appKitModal.addListener(() {
        if (appKitModal.isConnected) {
          _walletAddress = appKitModal.session?.address ?? '';
          _notifyWalletConnectedListeners();
        } else {
          _walletAddress = '';
          _notifyWalletDisconnectedListeners();
        }
      });
    } catch (e) {
      print('Failed to initialize ReownAppKitModal: $e');
      rethrow;
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeModal();
    }
  }

  @override
  bool canBeDisconnected() {
    return true;
  }

  @override
  String getConnectedWallet() {
    return _walletAddress;
  }

  @override
  Future<void> disconnectWallet() async {
    if (appKitModal.isConnected) {
      await appKitModal.disconnect();
      _walletAddress = '';
      _currentChainId = 1; // Reset to default network
      _notifyWalletDisconnectedListeners();
      print('Disconnected from wallet');
    }
  }

  @override
  bool isWalletConnected() {
    return appKitModal.isConnected;
  }

  @override
  Future<void> selectNetwork(String networkName) async {
    final network = networks.values.firstWhere(
      (net) => net.name == networkName,
      orElse: () => throw Exception('Network not found: $networkName'),
    );

    if (_currentChainId == int.parse(network.chainId)) {
      print('Already connected to ${network.name}.');
      return;
    }

    try {
      await appKitModal.selectChain(network);
      _currentChainId = int.parse(network.chainId);
      _notifyNetworkChangedListeners();
      print('Switched to network: ${network.name}');
    } catch (e) {
      throw Exception('Failed to switch network: $e');
    }
  }

  @override
  Future<double> fetchBalance(String walletAddress) async {
    await ensureInitialized();
    if (!appKitModal.isConnected) {
      throw Exception('Wallet is not connected.');
    }

    final session = appKitModal.session;
    if (session == null || session.address != walletAddress) {
      throw Exception('Session is invalid or wallet address mismatch.');
    }

    final network = networks.values.firstWhere(
      (net) => int.parse(net.chainId) == session.chainId,
      orElse: () => throw Exception(
          'No matching network for Chain ID: ${session.chainId}'),
    );

    final rpcUrl = network.rpcUrl;

    try {
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'eth_getBalance',
          'params': [
            walletAddress,
            'latest',
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balanceHex = data['result'];
        if (balanceHex == null) {
          throw Exception('No result in the RPC response.');
        }

        final balanceInWei = BigInt.parse(balanceHex.substring(2), radix: 16);
        final balanceInEther = balanceInWei / BigInt.from(1e18);

        print(
            'Balance for $walletAddress: $balanceInEther ${network.currency}');
        return balanceInEther.toDouble();
      } else {
        throw Exception(
            'Failed to fetch balance. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching balance: $e');
    }
  }

  @override
  Future<void> connectWallet(BuildContext context) async {
    await ensureInitialized(); // Ensure the appKitModal is initialized

    try {
      print('Triggering wallet connection...');
      await appKitModal.openModalView();

      final session = appKitModal.session;
      if (session == null) {
        print('No session returned. Wallet connection failed.');
        throw Exception('No session available after connection attempt.');
      }

      // Update the wallet address and notify listeners
      _walletAddress = session.address ?? '';
      _currentChainId = int.parse(session.chainId);
      _notifyWalletConnectedListeners();

      print('Wallet connected: $_walletAddress');
    } catch (e) {
      print('Error during wallet connection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting wallet: $e')),
      );
      rethrow; // Propagate the error if needed
    }
  }

  @override
  void addNetworkChangedListener(Function(String networkName) listener) {
    _networkChangedListeners.add(() {
      final networkName = networks[_currentChainId]?.name ?? 'Unknown Network';
      listener(networkName);
    });
  }

  @override
  void addWalletConnectedListener(Function(String walletAddress) listener) {
    _walletConnectedListeners.add(() {
      listener(_walletAddress);
    });
  }

  @override
  void addWalletDisconnectedListener(VoidCallback listener) {
    _walletDisconnectedListeners.add(listener);
  }

  void _notifyNetworkChangedListeners() {
    for (final listener in _networkChangedListeners) {
      listener();
    }
  }

  void _notifyWalletConnectedListeners() {
    for (final listener in _walletConnectedListeners) {
      listener();
    }
  }

  void _notifyWalletDisconnectedListeners() {
    for (final listener in _walletDisconnectedListeners) {
      listener();
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
  Future<List<String>> getAvailableNetworks() async {
    try {
      final networkNames =
          networks.values.map((network) => network.name).toList();
      return networkNames;
    } catch (e) {
      throw Exception('Error fetching available networks: $e');
    }
  }

  @override
  Future<String> getCurrentNetwork() async {
    await ensureInitialized();

    if (appKitModal.session == null) {
      throw Exception('No session active.');
    }

    final currentChainId = appKitModal.session?.chainId ?? '';
    final currentNetwork = networks.values
        .firstWhere((network) => network.chainId.toString() == currentChainId,
            orElse: () => ReownAppKitModalNetworkInfo(
                name: 'Unknown Network',
                chainId: '0',
                currency: '',
                rpcUrl: '',
                explorerUrl: ''))
        .name;

    print('Current network: $currentNetwork');
    return currentNetwork;
  }
}

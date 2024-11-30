import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import '../network_manager_interface.dart';

class NetworkManagerImpl implements NetworkManager {
  late final ReownAppKitModal appKitModal;
  bool _isInitialized = false;
  final String _namespace = "eip155";
  String _walletAddress = '';
  final int _defaultChainId = 1; // Default to Ethereum Mainnet
  int _currentChainId = 1; // Default to Ethereum Mainnet

  final Map<int, ReownAppKitModalNetworkInfo> networks = {
    1: ReownAppKitModalNetworkInfo(
      name: 'Ethereum',
      chainId: '1',
      currency: 'ETH',
      rpcUrl: 'https://eth.llamarpc.com',
      explorerUrl: 'https://etherscan.io',
    ),
    56: ReownAppKitModalNetworkInfo(
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

  ReownAppKitModal getAppKitModal() {
    return appKitModal;
  }

  ReownAppKitModal _initializeAppKitModal(BuildContext context) {
    return ReownAppKitModal(
      context: context,
      projectId: 'e809b3031729dba863aab7b6089f245f',
      enableAnalytics: true,
      getBalanceFallback: () {
        return 0.0 as Future<double>;
      },
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
      /*featuresConfig: FeaturesConfig(
        email: true,
        socials: [
          AppKitSocialOption.Farcaster,
          AppKitSocialOption.X,
          AppKitSocialOption.Apple,
          AppKitSocialOption.Discord,
        ],
        showMainWallets: false,
      ),*/
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
      appKitModal.onModalConnect.subscribe((ModalConnect? evt) {
        if (evt?.session == null) {
          print("Error: ModalConnect Session is null in the event.");
        }

        _walletAddress = evt!.session.getAddress(this._namespace) ?? '';
        _currentChainId = int.parse(evt.session.chainId);
        for (final listener in _walletConnectedListeners) {
          listener();
        }
      });

      appKitModal.onModalUpdate.subscribe((ModalConnect? evt) {
        if (evt?.session == null) {
          print("Error: ModalConnect Session is null in the event.");
        }

        _walletAddress = evt!.session.getAddress(this._namespace) ?? '';
        _currentChainId = int.parse(evt.session.chainId);
        for (final listener in _walletConnectedListeners) {
          listener();
        }
      });

      appKitModal.onModalNetworkChange.subscribe((ModalNetworkChange? evt) {
        if (evt?.chainId == null) {
          print("Error: ModalNetworkChange chainId is null in the event.");
        }

        _currentChainId = int.parse(evt!.chainId);
        for (final listener in _networkChangedListeners) {
          listener();
        }
      });

      appKitModal.onModalDisconnect.subscribe((ModalDisconnect? evt) {
        _walletAddress = "";
        for (final listener in _walletDisconnectedListeners) {
          listener();
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
      _currentChainId = _defaultChainId;
      for (final listener in _walletDisconnectedListeners) {
        listener();
      }

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
      for (final listener in _networkChangedListeners) {
        listener();
      }

      print('Switched to network: ${network.name}');
    } catch (e) {
      throw Exception('Failed to switch network: $e');
    }
  }

  @override
  Future<double> fetchBalance(String walletAddress) async {
    ensureInitialized();

    //await ensureInitialized();
    if (!appKitModal.isConnected) {
      throw Exception('Wallet is not connected.');
    }

    final session = appKitModal.session;
    if (session == null) {
      throw Exception('Session is invalid');
    }

    String? sessionAddress = session.getAddress(this._namespace);
    if (sessionAddress != walletAddress) {
      throw Exception('Session is invalid or wallet address mismatch.');
    }

    int chainId = int.parse(session.chainId);
    print('chain: ${chainId}, networks: ${networks[chainId]}');

    if (networks[chainId] == null) {
      throw Exception('No matching network for Chain ID: ${chainId}');
    }

    final network = networks[chainId]!;
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

        print('Balance for $walletAddress: $balanceInWei ${network.currency}');
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
    } catch (e) {
      print('Error during wallet connection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting wallet: $e')),
      );
      rethrow; // Propagate the error if needed
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
    return networks.values.map((network) => network.name).toList();
  }

  @override
  void addWalletConnectedListener(Function(String walletAddress) callback) {
    _walletConnectedListeners.add(callback as VoidCallback);
  }

  @override
  void addWalletDisconnectedListener(Function() callback) {
    _walletDisconnectedListeners.add(callback as VoidCallback);
  }

  @override
  void addNetworkChangedListener(Function(String chainId) callback) {
    _networkChangedListeners.add(callback as VoidCallback);
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

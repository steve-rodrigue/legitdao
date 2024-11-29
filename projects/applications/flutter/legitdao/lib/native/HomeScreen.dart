import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  _WalletConnectScreenState createState() => _WalletConnectScreenState();
}

class _WalletConnectScreenState extends State<HomeScreen> {
  late ReownAppKitModal _appKitModal;
  bool isInitialized = false;
  String walletAddress = '';
  int selectedNetwork = 0; // Default to the first network (index 0)
  bool isConnected = false;
  String bnbPrice = 'N/A'; // Store the fetched price

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

  @override
  void initState() {
    super.initState();
    initializeAppKitModal();
  }

  void initializeAppKitModal() async {
    _appKitModal = ReownAppKitModal(
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

    try {
      await _appKitModal.init();
      print('Modal initialized successfully.');

      _appKitModal.addListener(() {
        setState(() {
          isConnected = _appKitModal.isConnected;
          walletAddress = isConnected ? getWalletAddress() : '';
        });
      });

      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      print('Error initializing modal: $e');
    }
  }

  String getWalletAddress() {
    final session = _appKitModal.session;
    return session?.getAddress("web3") ?? 'No Wallet Connected';
  }

  Future<void> fetchBNBPrice() async {
    if (!_appKitModal.isConnected) {
      print('Wallet is not connected.');
      return;
    }

    // Current network configuration
    final network = networks[selectedNetwork];
    if (network == null) {
      print('No network selected.');
      return;
    }

    // PancakeSwap BNB/USDT pair contract address
    const pairAddress = '0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE';

    // ABI for the `getReserves` function
    const getReservesABI = '0x0902f1ac'; // Keccak-256 hash of "getReserves()"

    final rpcUrl = network.rpcUrl;

    try {
      // Prepare JSON-RPC request
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'eth_call',
          'params': [
            {
              'to': pairAddress,
              'data': getReservesABI,
            },
            'latest',
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Decode the response
        final reservesHex = data['result'];
        if (reservesHex == null) {
          throw Exception('No result in the RPC response.');
        }

        // Decode the reserve values (each reserve occupies 32 bytes)
        final reserveUSDT =
            BigInt.parse(reservesHex.substring(2, 66), radix: 16);
        final reserveBNB =
            BigInt.parse(reservesHex.substring(66, 130), radix: 16);

        // Ensure reserveBNB is non-zero to avoid division by zero
        if (reserveBNB == BigInt.zero) {
          throw Exception('Reserve for BNB is zero.');
        }

        // Calculate the price (USDT per BNB)
        final bnbPriceInUsdt = reserveUSDT / reserveBNB;

        setState(() {
          bnbPrice = bnbPriceInUsdt.toStringAsFixed(2);
        });

        print('BNB/USDT Price: $bnbPrice');
      } else {
        print('Failed to fetch reserves. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching BNB price: $e');
      setState(() {
        bnbPrice = 'Error fetching price';
      });
    }
  }

  Future<void> updateNetwork(int index) async {
    if (!isInitialized) {
      print('ReownAppKitModal is not initialized.');
      return;
    }

    final networkInfo = networks[index];
    if (networkInfo != null) {
      try {
        await _appKitModal.selectChain(networkInfo);
        print(
            'Switched to ${networkInfo.name} (Chain ID: ${networkInfo.chainId})');
        setState(() {
          selectedNetwork = index;
        });
      } catch (e) {
        print('Error switching network: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<int>(
              value: selectedNetwork,
              onChanged: (int? value) async {
                if (value != null) {
                  await updateNetwork(value);
                }
              },
              items: networks.keys.map((int index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(networks[index]!.name),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            AppKitModalConnectButton(appKit: _appKitModal),
            const SizedBox(height: 40),
            if (isConnected)
              Column(
                children: [
                  Text('Connected Wallet Address: $walletAddress'),
                  ElevatedButton(
                    onPressed: fetchBNBPrice,
                    child: const Text('Fetch BNB/USDT Price'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'BNB/USDT Price: $bnbPrice USDT',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _appKitModal.disconnect();
                      setState(() {
                        walletAddress = '';
                        isConnected = false;
                      });
                      print('Wallet disconnected.');
                    },
                    child: const Text('Disconnect Wallet'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

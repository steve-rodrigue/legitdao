import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  _WebHomeScreenState createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<HomeScreen> {
  String walletAddress = '';
  bool isConnected = false;
  String selectedNetwork = 'Ethereum'; // Default network

  // Network configuration
  final Map<String, dynamic> networks = {
    'Ethereum': {
      'chainId': '0x1',
      'chainName': 'Ethereum Mainnet',
      'currencyName': 'Ethereum',
      'currencySymbol': 'ETH',
      'currencyDecimals': 18,
      'rpcUrls': ['https://eth.llamarpc.com'],
      'blockExplorerUrls': ['https://etherscan.io'],
    },
    'BSC': {
      'chainId': '0x38',
      'chainName': 'Binance Smart Chain',
      'currencyName': 'Binance Coin',
      'currencySymbol': 'BNB',
      'currencyDecimals': 18,
      'rpcUrls': ['https://binance.llamarpc.com'],
      'blockExplorerUrls': ['https://bscscan.com'],
    },
  };

  Future<void> connectWallet() async {
    if (ethereum != null) {
      try {
        final accounts = await ethereum!.requestAccount();
        setState(() {
          walletAddress = accounts.first;
          isConnected = true;
        });
      } catch (e) {
        print('User rejected the connection');
      }
    } else {
      print('MetaMask not available');
    }
  }

  Future<void> switchNetwork(String networkName) async {
    if (ethereum == null) {
      print('MetaMask not available');
      return;
    }

    final networkConfig = networks[networkName];
    if (networkConfig == null) {
      print('Network configuration not found for $networkName');
      return;
    }

    try {
      // Attempt to switch network
      await ethereum!.walletSwitchChain(networkConfig['chainId']);
      print('Switched to $networkName');
      setState(() {
        selectedNetwork = networkName;
      });
    } catch (e) {
      print('Error switching network: $e');
      // If the network is not added, add it
      try {
        await ethereum!.walletAddChain(
          chainId: networkConfig['chainId'],
          chainName: networkConfig['chainName'],
          nativeCurrency: CurrencyParams(
            name: networkConfig['currencyName'],
            symbol: networkConfig['currencySymbol'],
            decimals: networkConfig['currencyDecimals'],
          ),
          rpcUrls: networkConfig['rpcUrls'],
          blockExplorerUrls: networkConfig['blockExplorerUrls'],
        );
        print('Added and switched to $networkName');
        setState(() {
          selectedNetwork = networkName;
        });
      } catch (addError) {
        print('Error adding network: $addError');
      }
    }
  }

  void disconnectWallet() {
    setState(() {
      walletAddress = '';
      isConnected = false;
    });
    print('Wallet disconnected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isConnected
                ? 'Connected: $walletAddress'
                : 'Not Connected'),
            const SizedBox(height: 20),
            if (!isConnected)
              ElevatedButton(
                onPressed: connectWallet,
                child: const Text('Connect MetaMask'),
              )
            else
              Column(
                children: [
                  DropdownButton<String>(
                    value: selectedNetwork,
                    onChanged: (String? value) {
                      if (value != null) {
                        switchNetwork(value);
                      }
                    },
                    items: networks.keys.map((String network) {
                      return DropdownMenuItem<String>(
                        value: network,
                        child: Text(network),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: disconnectWallet,
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
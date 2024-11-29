import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'marketplace_info_board.dart';
import 'dart:math';

class MarketplacesPage extends StatelessWidget {
  MarketplacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "marketplaces_title",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ).tr(),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Marketplace(pair: 'USDT/BNB'),
        ),
      ),
    );
  }
}

class Marketplace extends StatefulWidget {
  final String pair;

  const Marketplace({super.key, required this.pair});

  @override
  _MarketplaceState createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  late List<FlSpot> priceData;

  String _selectedPair = 'USDT/BNB';
  List<String> _pairs = [];
  final List<PairInfo> _allPairsInfo = [
    PairInfo(name: 'USDT/BNB'),
    PairInfo(name: 'WEBX/USDT')
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    priceData = generateMockPriceData(widget.pair);

    final pairs = await getAvailablePairs();
    final selectedPair = await getCurrentPair();

    setState(() {
      _pairs = pairs;
      _selectedPair = selectedPair;
    });
  }

  Future<String> getCurrentPair() async {
    return 'USDT/BNB';
  }

  Future<List<String>> getAvailablePairs() async {
    try {
      return _allPairsInfo.map((onePair) => onePair.name).toList();
    } catch (e) {
      throw Exception('Error fetching available pairs: $e');
    }
  }

  Future<void> selectPair(String networkName) async {}

  Future<void> _switchPair(String newPair) async {
    try {
      await selectPair(newPair);
      setState(() {
        _selectedPair = newPair;
      });
    } catch (e) {
      print('Error switching pair: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty) {
      return const Center(
        child: Text('No pairs available', style: TextStyle(fontSize: 16)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 300, // Ensure the chart has a fixed height
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: priceData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                          show: true, color: Colors.blue.withOpacity(0.1)),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot touchedSpot) =>
                          Colors.blueAccent,
                    ),
                    touchCallback: (event, response) {
                      if (response == null || response.lineBarSpots == null)
                        return;
                      for (final spot in response.lineBarSpots!) {
                        debugPrint('Touched spot: ${spot.x}, ${spot.y}');
                      }
                    },
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Pair switcher
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedPair,
              items: _pairs.map((String pair) {
                return DropdownMenuItem<String>(
                  value: pair,
                  child: Text(pair),
                );
              }).toList(),
              onChanged: (String? newPair) {
                setState(() {
                  if (newPair != null) {
                    _switchPair(newPair);
                  }
                });
              },
              isExpanded: true,
              hint: const Text("Select Pair"),
            ),
          ),

          // Balance info board
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Builder(builder: (context) {
              return MarketplaceInfoBoard();
            }),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Function to generate mock price data
  List<FlSpot> generateMockPriceData(String pair) {
    final Random random = Random();
    final List<FlSpot> mockData = [];
    double startPrice = 300; // Initial mock price for BNB
    for (int i = 0; i < 50; i++) {
      final priceChange = random.nextDouble() * 10 - 5; // Random change [-5, 5]
      startPrice += priceChange;
      startPrice = startPrice.clamp(280, 320); // Keep prices within range
      mockData.add(FlSpot(i.toDouble(), startPrice));
    }
    return mockData;
  }
}

class PairInfo {
  final String name; // Name of the pair

  PairInfo({
    required this.name,
  });
}

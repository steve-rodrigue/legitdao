import 'dart:math';
import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting.

class CustomCandleStickChart extends StatefulWidget {
  final List<double> data;
  final double width;

  const CustomCandleStickChart({
    Key? key,
    required this.data,
    required this.width,
  }) : super(key: key);

  @override
  _CustomCandleStickChartState createState() => _CustomCandleStickChartState();
}

class _CustomCandleStickChartState extends State<CustomCandleStickChart> {
  String selectedRange = '1d';
  List<CandleData> displayedData = [];
  CandleData? hoveredCandle; // To store the candle data for the tooltip
  final Random _random = Random();
  final double aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    _updateData(selectedRange);
  }

  List<CandleData> _generateCandlestickData(List<double> data) {
    if (data.isEmpty) return [];

    List<CandleData> candlesticks = [];
    double previousClose = data.first; // Initialize with the first value

    for (int i = 0; i < data.length; i++) {
      double open = previousClose;
      double close =
          open + (_random.nextDouble() * 4 - 2); // Random fluctuation
      double high = max(open, close) + _random.nextDouble() * 2;
      double low = min(open, close) - _random.nextDouble() * 2;
      double volume = _random.nextDouble() * 1000; // Random volume

      candlesticks.add(CandleData(
        open: open,
        close: close,
        high: high,
        low: low,
        volume: volume,
        timestamp: DateTime.now()
            .subtract(Duration(minutes: i * 5))
            .millisecondsSinceEpoch, // Convert DateTime to UNIX timestamp
      ));

      previousClose = close; // Update previous close for the next candle
    }

    return candlesticks;
  }

  void _updateData(String range) {
    setState(() {
      selectedRange = range;
      List<double> rawData;

      switch (range) {
        case '1d':
          rawData = _generateTodayData();
          break;
        case '5d':
          rawData = widget.data.sublist(
              max(0, widget.data.length - 240)); // More candles for 5 days
          break;
        case '1m':
          rawData = widget.data.sublist(
              max(0, widget.data.length - 180)); // More candles for 1 month
          break;
        case '6m':
          rawData = widget.data.sublist(
              max(0, widget.data.length - 720)); // More candles for 6 months
          break;
        case '1a':
          rawData = widget.data.sublist(
              max(0, widget.data.length - 1440)); // More candles for 1 year
          break;
        case '5a':
          rawData = widget.data.sublist(
              max(0, widget.data.length - 7200)); // More candles for 5 years
          break;
        case 'Max':
        default:
          rawData = widget.data;
      }

      displayedData = _generateCandlestickData(rawData);
    });
  }

  List<double> _generateTodayData() {
    return List.generate(16, (hour) {
      return 100 + _random.nextDouble() * 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.width / aspectRatio;

    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children:
                  ['1d', '5d', '1m', '6m', '1a', '5a', 'Max'].map((range) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRange == range
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: selectedRange == range
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => _updateData(range),
                  child: Text(range),
                );
              }).toList(),
            ),
          ),
          if (hoveredCandle != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Date: ${DateTime.fromMillisecondsSinceEpoch(hoveredCandle!.timestamp).toLocal()}\n'
                  'Open: ${hoveredCandle!.open?.toStringAsFixed(2) ?? 'N/A'}\n'
                  'Close: ${hoveredCandle!.close?.toStringAsFixed(2) ?? 'N/A'}\n'
                  'High: ${hoveredCandle!.high?.toStringAsFixed(2) ?? 'N/A'}\n'
                  'Low: ${hoveredCandle!.low?.toStringAsFixed(2) ?? 'N/A'}\n'
                  'Volume: ${hoveredCandle!.volume?.toStringAsFixed(2) ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: height,
              width: widget.width,
              color: Theme.of(context).colorScheme.background,
              child: InteractiveChart(
                candles: displayedData,
                style: ChartStyle(
                  priceGainColor: Colors.green,
                  priceLossColor: Colors.red,
                  volumeColor: Colors.grey,
                ),
                overlayInfo: (CandleData candle) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(candle.timestamp);
                  return {
                    "Date": DateFormat.yMMMd().format(date),
                    "Open": candle.open?.toStringAsFixed(2) ?? "-",
                    "Close": candle.close?.toStringAsFixed(2) ?? "-",
                    "High": candle.high?.toStringAsFixed(2) ?? "-",
                    "Low": candle.low?.toStringAsFixed(2) ?? "-",
                    "Volume": candle.volume?.toStringAsFixed(0) ?? "-",
                  };
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

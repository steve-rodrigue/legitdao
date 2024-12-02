import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CustomLineChart extends StatefulWidget {
  final List<double> data;
  final double width;

  const CustomLineChart({Key? key, required this.data, required this.width})
      : super(key: key);

  @override
  _CustomLineChartState createState() => _CustomLineChartState();
}

class _CustomLineChartState extends State<CustomLineChart> {
  String selectedRange = '1d'; // Default to '1d'
  List<double> displayedData = [];
  final Random _random = Random();
  List<String> displayedTimes = [];
  double? topPrice;
  double? bottomPrice;
  List<double> priceLabels = [];
  double maxY = 0;
  double minY = 0;

  final double aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    _updateData(selectedRange); // Load the '1d' data by default
  }

  void _updateData(String range) {
    setState(() {
      selectedRange = range;
      int dataCount = widget.data.length;
      List<double> rawData;

      switch (range) {
        case '1d':
          rawData = _generateTodayData();
          break;
        case '5d':
          rawData = widget.data
              .sublist((dataCount - 5 * 24).clamp(0, dataCount), dataCount);
          break;
        case '1m':
          rawData = widget.data
              .sublist((dataCount - 30).clamp(0, dataCount), dataCount);
          break;
        case '6m':
          rawData = widget.data
              .sublist((dataCount - 180).clamp(0, dataCount), dataCount);
          break;
        case '1a':
          rawData = widget.data
              .sublist((dataCount - 365).clamp(0, dataCount), dataCount);
          break;
        case '5a':
          rawData = widget.data
              .sublist((dataCount - 1825).clamp(0, dataCount), dataCount);
          break;
        case 'Max':
        default:
          rawData = widget.data;
      }

      rawData = _downsampleData(rawData, 30);
      displayedData = _generateFluctuations(rawData);
      displayedTimes = _generateTimes(rawData.length, range);

      if (displayedData.isNotEmpty) {
        maxY = displayedData.reduce(max);
        minY = displayedData.reduce(min);

        topPrice = maxY;
        bottomPrice = minY;

        priceLabels = [
          bottomPrice!,
          bottomPrice! + (topPrice! - bottomPrice!) * 0.25,
          bottomPrice! + (topPrice! - bottomPrice!) * 0.5,
          bottomPrice! + (topPrice! - bottomPrice!) * 0.75,
          topPrice!,
        ];
      }
    });
  }

  List<double> _generateTodayData() {
    List<double> todayData = [];
    for (int hour = 0; hour <= 15; hour++) {
      double baseValue =
          100 + _random.nextDouble() * 10; // Simulated base value
      todayData.add(
          baseValue + _random.nextDouble() * 5 * (_random.nextBool() ? 1 : -1));
    }
    return todayData;
  }

  List<double> _generateFluctuations(List<double> data) {
    return data.map((value) {
      double fluctuation =
          _random.nextDouble() * 0.1 * value; // ±10% fluctuation
      return value + (fluctuation * (_random.nextBool() ? 1 : -1));
    }).toList();
  }

  List<String> _generateTimes(int dataLength, String range) {
    DateTime now = DateTime.now();
    List<DateTime> timestamps = [];

    if (range == '1d') {
      for (int i = 0; i < dataLength; i++) {
        timestamps.add(now.subtract(Duration(hours: dataLength - i - 1)));
      }
    } else if (range == '5d') {
      for (int i = 0; i < dataLength; i++) {
        timestamps
            .add(now.subtract(Duration(hours: (dataLength - i - 1) * 10)));
      }
    } else if (range == '1m') {
      for (int i = 0; i < dataLength; i++) {
        timestamps.add(now.subtract(Duration(days: dataLength - i - 1)));
      }
    } else if (range == '6m' || range == '1a') {
      for (int i = 0; i < dataLength; i++) {
        timestamps
            .add(DateTime(now.year, now.month - (dataLength - i - 1), now.day));
      }
    } else if (range == '5a' || range == 'Max') {
      for (int i = 0; i < dataLength; i++) {
        timestamps
            .add(DateTime(now.year - (dataLength - i - 1), now.month, now.day));
      }
    }

    return timestamps.map((timestamp) {
      if (range == '1d') {
        return DateFormat.Hm().format(timestamp);
      } else if (range == '5d' || range == '1m') {
        return DateFormat.Md().format(timestamp);
      } else if (range == '6m' || range == '1a') {
        return DateFormat.MMM().format(timestamp);
      } else {
        return DateFormat.yMMM().format(timestamp);
      }
    }).toList();
  }

  List<double> _downsampleData(List<double> data, int maxPoints) {
    if (data.length <= maxPoints) {
      return data;
    }
    double step = data.length / maxPoints;
    return List.generate(maxPoints, (index) => data[(index * step).round()]);
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: height,
              width: widget.width,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: (maxY - minY) / 5,
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (displayedTimes.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < displayedTimes.length) {
                            return Text(displayedTimes[index]);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: displayedData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      color: Color.fromARGB(255, 207, 149, 33),
                      barWidth: 2,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

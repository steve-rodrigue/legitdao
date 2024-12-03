import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CustomBarChart extends StatefulWidget {
  final List<int> newReferrals;
  final List<int> soldReferrals;
  final double width;

  const CustomBarChart({
    Key? key,
    required this.newReferrals,
    required this.soldReferrals,
    required this.width,
  }) : super(key: key);

  @override
  _CustomBarChartState createState() => _CustomBarChartState();
}

class _CustomBarChartState extends State<CustomBarChart> {
  String selectedRange = '1d'; // Default to '1d'
  List<int> displayedNewReferrals = [];
  List<int> displayedSoldReferrals = [];
  List<String> displayedTimes = [];
  int maxY = 0;
  final double aspectRatio = 16 / 9;

  String? hoveredTime;
  int? hoveredNewReferrals;
  int? hoveredSoldReferrals;

  @override
  void initState() {
    super.initState();
    _updateData(selectedRange);
  }

  void _updateData(String range) {
    setState(() {
      selectedRange = range;
      int dataCount = widget.newReferrals.length;
      List<int> newReferralsRaw;
      List<int> soldReferralsRaw;

      switch (range) {
        case '1d':
          newReferralsRaw = _generateTodayData(widget.newReferrals);
          soldReferralsRaw = _generateTodayData(widget.soldReferrals);
          break;
        case '5d':
          newReferralsRaw = widget.newReferrals
              .sublist((dataCount - 5 * 24).clamp(0, dataCount), dataCount);
          soldReferralsRaw = widget.soldReferrals
              .sublist((dataCount - 5 * 24).clamp(0, dataCount), dataCount);
          break;
        case '1m':
          newReferralsRaw = widget.newReferrals
              .sublist((dataCount - 30).clamp(0, dataCount), dataCount);
          soldReferralsRaw = widget.soldReferrals
              .sublist((dataCount - 30).clamp(0, dataCount), dataCount);
          break;
        case '6m':
          newReferralsRaw = widget.newReferrals
              .sublist((dataCount - 180).clamp(0, dataCount), dataCount);
          soldReferralsRaw = widget.soldReferrals
              .sublist((dataCount - 180).clamp(0, dataCount), dataCount);
          break;
        case '1a':
          newReferralsRaw = widget.newReferrals
              .sublist((dataCount - 365).clamp(0, dataCount), dataCount);
          soldReferralsRaw = widget.soldReferrals
              .sublist((dataCount - 365).clamp(0, dataCount), dataCount);
          break;
        case '5a':
          newReferralsRaw = widget.newReferrals
              .sublist((dataCount - 1825).clamp(0, dataCount), dataCount);
          soldReferralsRaw = widget.soldReferrals
              .sublist((dataCount - 1825).clamp(0, dataCount), dataCount);
          break;
        case 'Max':
        default:
          newReferralsRaw = widget.newReferrals;
          soldReferralsRaw = widget.soldReferrals;
      }

      displayedNewReferrals = _downsampleData(newReferralsRaw, 30);
      displayedSoldReferrals = _downsampleData(soldReferralsRaw, 30);
      displayedTimes = _generateTimes(displayedNewReferrals.length, range);

      if (displayedNewReferrals.isNotEmpty ||
          displayedSoldReferrals.isNotEmpty) {
        maxY = ([
          ...displayedNewReferrals,
          ...displayedSoldReferrals,
        ]..sort())
            .last;
      }
    });
  }

  List<int> _generateTodayData(List<int> data) {
    int dataCount = min(24, data.length); // Simulate data for 24 hours
    return data.sublist(0, dataCount);
  }

  List<String> _generateTimes(int dataLength, String range) {
    DateTime now = DateTime.now();
    List<DateTime> timestamps = [];
    int interval = 1;

    if (range == '1d') {
      interval = 1; // 1 hour interval
      for (int i = 0; i < dataLength; i++) {
        timestamps.add(now.subtract(Duration(hours: dataLength - i - 1)));
      }
    } else if (range == '5d') {
      interval = 10; // 10 hours interval
      for (int i = 0; i < dataLength; i++) {
        timestamps.add(
            now.subtract(Duration(hours: (dataLength - i - 1) * interval)));
      }
    } else if (range == '1m') {
      interval = 1; // 1 day interval
      for (int i = 0; i < dataLength; i++) {
        timestamps.add(now.subtract(Duration(days: dataLength - i - 1)));
      }
    } else if (range == '6m' || range == '1a') {
      interval = 1; // 1 month interval
      for (int i = 0; i < dataLength; i++) {
        timestamps
            .add(DateTime(now.year, now.month - (dataLength - i - 1), now.day));
      }
    } else if (range == '5a' || range == 'Max') {
      interval = 1; // 1 year interval
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

  List<int> _downsampleData(List<int> data, int maxPoints) {
    if (data.length <= maxPoints) {
      return data;
    }
    double step = data.length / maxPoints;
    return List.generate(
      maxPoints,
      (index) => data[(index * step).floor()],
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.width / aspectRatio;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            children: ['1d', '5d', '1m', '6m', '1a', '5a', 'Max'].map((range) {
              return ElevatedButton(
                onPressed: () => _updateData(range),
                child: Text(range),
              );
            }).toList(),
          ),
        ),
        SizedBox(
          height: height,
          width: widget.width,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(
                displayedNewReferrals.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: displayedNewReferrals[index].toDouble(),
                      color: const Color.fromARGB(255, 207, 149, 33),
                    ),
                    BarChartRodData(
                      toY: displayedSoldReferrals[index].toDouble(),
                      color: Colors.pink,
                    ),
                  ],
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxY / 6).clamp(1, double.infinity), // 7 labels
                    getTitlesWidget: (value, meta) {
                      return Text(value.toStringAsFixed(0));
                    },
                  ),
                ),
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
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String time = displayedTimes[group.x.toInt()];
                    int newReferrals = displayedNewReferrals[groupIndex];
                    int soldReferrals = displayedSoldReferrals[groupIndex];
                    return BarTooltipItem(
                      '$time\nNew: $newReferrals\nSold: $soldReferrals',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

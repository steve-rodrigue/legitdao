import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'cryptocurrency.dart';
import 'custom_badge.dart';

class CustomPieChart extends StatefulWidget {
  final List<Cryptocurrency> cryptocurrencies;
  final double width;
  final Function(int touchedIndex) onTouch;

  const CustomPieChart({
    Key? key,
    required this.cryptocurrencies,
    required this.width,
    required this.onTouch,
  }) : super(key: key);

  @override
  State<CustomPieChart> createState() => _CustomPieChartState();
}

class _CustomPieChartState extends State<CustomPieChart> {
  int? touchedIndex;
  late double totalValue;

  @override
  void initState() {
    super.initState();
    totalValue = widget.cryptocurrencies
        .fold(0.0, (sum, crypto) => sum + crypto.usdtValue);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width / 16 * 9; // Maintain a 16:9 aspect ratio
    final onTouchFn = widget.onTouch;

    return Column(
      children: [
        SizedBox(
          width: width,
          height: height,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      onTouchFn(touchedIndex!);
                      return;
                    }

                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    onTouchFn(touchedIndex!);
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 50,
              sections: _buildSections(),
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.cryptocurrencies.asMap().entries.map((entry) {
      final index = entry.key;
      final crypto = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 160.0 : 140.0;
      final widgetSize = isTouched ? 110.0 : 80.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      // Calculate percentage value for the pie chart section
      final percentageValue = (crypto.usdtValue / totalValue) * 100;

      return PieChartSectionData(
        color: crypto.color,
        value: percentageValue,
        title: '${percentageValue.toStringAsFixed(0)}%',
        radius: radius,
        badgeWidget: crypto.usdtValue > totalValue * 0.05
            ? CustomBadge(
                crypto.logoPath,
                size: widgetSize,
                borderColor: Colors.black,
              )
            : null,
        badgePositionPercentageOffset: .98,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      );
    }).toList();
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'cryptocurrency.dart';
import 'custom_badge.dart';

class CustomPieChart extends StatefulWidget {
  final List<Cryptocurrency> cryptocurrencies;
  final double width;
  final int touchedIndex;
  final Function(int touchedIndex) onTouch;

  const CustomPieChart({
    Key? key,
    required this.cryptocurrencies,
    required this.width,
    required this.touchedIndex,
    required this.onTouch,
  }) : super(key: key);

  @override
  State<CustomPieChart> createState() => _CustomPieChartState();
}

class _CustomPieChartState extends State<CustomPieChart> {
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
    final height = width;

    return LayoutBuilder(
      builder: (context, constraints) {
        int touchedIndex = widget.touchedIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
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
                            widget.onTouch(-1);
                            return;
                          }

                          widget.onTouch(pieTouchResponse
                              .touchedSection!.touchedSectionIndex);
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0,
                    centerSpaceRadius:
                        0, // Center space radius is 6.625% of width
                    sections: _buildSections(width, touchedIndex),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(double width, int touchedIndex) {
    return widget.cryptocurrencies.asMap().entries.map((entry) {
      final index = entry.key;
      final crypto = entry.value;
      final isTouched = index == touchedIndex;

      // Calculate the font size:
      final fontNormalSize = (width * 0.05);
      final fontHoversize = (width * 0.075);
      final fontSize = isTouched ? fontHoversize : fontNormalSize;

      // Calculate radius:
      final radiusNormalSize = (width * 0.4275);
      final radiusHoverSize = (width * 0.5);
      final radius = isTouched ? radiusHoverSize : radiusNormalSize;

      // Calculate widget size:
      final widgetNormalSize = (width * 0.1850);
      final widgetHoverSize = (width * 0.2150);
      final widgetSize = isTouched ? widgetHoverSize : widgetNormalSize;

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

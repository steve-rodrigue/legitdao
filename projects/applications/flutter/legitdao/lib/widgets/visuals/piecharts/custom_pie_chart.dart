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
              centerSpaceRadius:
                  width * 0.0625, // Center space radius is 6.625% of width
              sections: _buildSections(width),
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(double width) {
    return widget.cryptocurrencies.asMap().entries.map((entry) {
      final index = entry.key;
      final crypto = entry.value;
      final isTouched = index == touchedIndex;

      // Calculate the font size:
      final fontNormalSize = (width * 0.02);
      final fontHoversize = (width * 0.025);
      final fontSize = isTouched ? fontHoversize : fontNormalSize;

      // Calculate radius:
      final radiusNormalSize = (width * 0.175);
      final radiusHoverSize = (width * 0.2);
      final radius = isTouched ? radiusHoverSize : radiusNormalSize;

      // Calculate widget size:
      final widgetNormalSize = (width * 0.1);
      final widgetHoverSize = (width * 0.1375);
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

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomBarChart extends StatefulWidget {
  final List<int> referrals; // Data representing referrals over time
  final double width;

  const CustomBarChart({
    Key? key,
    required this.referrals,
    required this.width,
  }) : super(key: key);

  @override
  _CustomBarChartState createState() => _CustomBarChartState();
}

class _CustomBarChartState extends State<CustomBarChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = 16 / 9;
    final double height = widget.width / aspectRatio;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: widget.width,
        height: height,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.center, // Align bars with no spacing
            gridData: FlGridData(show: false), // Remove grid lines
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 0,
                getTooltipItem: (_, __, ___, ____) => null,
              ),
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    touchedIndex = null;
                    return;
                  }
                  touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                });
              },
            ),
            barGroups: widget.referrals.asMap().entries.map((entry) {
              final int index = entry.key;
              final int value = entry.value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value.toDouble(),
                    color: touchedIndex == index
                        ? Colors.pink // Highlighted color
                        : const Color.fromARGB(
                            255, 207, 149, 33), // Default color
                    width: 10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
                barsSpace: 0,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

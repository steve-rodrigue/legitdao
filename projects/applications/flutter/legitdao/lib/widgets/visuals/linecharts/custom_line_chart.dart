import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomLineChart extends StatefulWidget {
  final List<double> data;
  final double width;

  const CustomLineChart({Key? key, required this.data, required this.width})
      : super(key: key);

  @override
  _CustomLineChartState createState() => _CustomLineChartState();
}

class _CustomLineChartState extends State<CustomLineChart> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = 16 / 9;
    final width = widget.width;
    double height = widget.width / aspectRatio;
    List<double> data = widget.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: SizedBox(
            width: width,
            height: height,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: false, // Disable all grid lines
                ),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: false,
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: false,
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    dotData: FlDotData(
                      show: false,
                    ),
                    color: Color.fromARGB(255, 207, 149, 33),
                    barWidth: 1,
                    belowBarData: BarAreaData(
                      show: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomPieChart extends StatefulWidget {
  final List<Cryptocurrency> cryptocurrencies;
  final double width;

  const CustomPieChart({
    Key? key,
    required this.cryptocurrencies,
    required this.width,
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
    final theme = Theme.of(context);
    final width = widget.width;
    final height = width / 16 * 9; // Maintain a 16:9 aspect ratio

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Total Portfolio Value: ${totalValue.toStringAsFixed(2)} USDT',
            style: theme.textTheme.headlineLarge,
          ),
        ),
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
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
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
        const SizedBox(height: 16),
        DataTable(
          columns: const [
            DataColumn(label: Text('Symbol')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Value (USDT)')),
            DataColumn(label: Text('% of Portfolio')),
          ],
          rows: widget.cryptocurrencies.asMap().entries.map((entry) {
            final index = entry.key;
            final crypto = entry.value;
            final isHighlighted = index == touchedIndex;
            final percentage = (crypto.usdtValue / totalValue) * 100;

            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (isHighlighted) {
                    return theme.colorScheme.secondary.withOpacity(0.2);
                  }
                  return null;
                },
              ),
              cells: [
                DataCell(Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: crypto.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      crypto.symbol,
                      style: TextStyle(
                        fontWeight:
                            isHighlighted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                )),
                DataCell(Text(
                  crypto.amount.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.normal,
                  ),
                )),
                DataCell(Text(
                  crypto.usdtValue.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.normal,
                  ),
                )),
                DataCell(Text(
                  '${percentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.normal,
                  ),
                )),
              ],
            );
          }).toList(),
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
            ? _Badge(
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

class _Badge extends StatelessWidget {
  const _Badge(
    this.svgAsset, {
    required this.size,
    required this.borderColor,
  });
  final String svgAsset;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: SvgPicture.asset(
          svgAsset,
          width: size - 5.0,
          height: size - 5.0,
        ),
      ),
    );
  }
}

class Cryptocurrency {
  final String logoPath;
  final String symbol;
  final Color color;
  final double amount;
  final double usdtValue;

  Cryptocurrency({
    required this.logoPath,
    required this.symbol,
    required this.color,
    required this.amount,
    required this.usdtValue,
  });
}

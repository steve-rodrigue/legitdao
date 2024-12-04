import 'package:flutter/material.dart';
import 'custom_pie_chart.dart';
import 'cryptocurrency.dart';

class CustomPieChartWithTable extends StatefulWidget {
  final List<Cryptocurrency> cryptocurrencies;
  final double width;

  const CustomPieChartWithTable({
    Key? key,
    required this.cryptocurrencies,
    required this.width,
  }) : super(key: key);

  @override
  State<CustomPieChartWithTable> createState() =>
      _CustomPieChartWithTableState();
}

class _CustomPieChartWithTableState extends State<CustomPieChartWithTable> {
  int? touchedIndex;
  late double totalValue;

  @override
  void initState() {
    super.initState();
    totalValue = widget.cryptocurrencies
        .fold(0.0, (sum, crypto) => sum + crypto.usdtValue);
  }

  void _onTouch(int? touchIndex) {
    setState(() {
      if (touchIndex != null) {
        touchedIndex = touchIndex;
        return;
      }

      touchedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = widget.width;
    List<Cryptocurrency> cryptocurrencies = widget.cryptocurrencies;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Total Portfolio Value: ${totalValue.toStringAsFixed(2)} USDT',
            style: theme.textTheme.headlineLarge,
          ),
        ),
        CustomPieChart(
          cryptocurrencies: cryptocurrencies,
          width: width,
          onTouch: _onTouch,
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
}

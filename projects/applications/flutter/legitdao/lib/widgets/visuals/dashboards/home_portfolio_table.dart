import 'package:flutter/material.dart';
import '../piecharts/cryptocurrency.dart';
import '../containers/custom_container.dart';

class HomePortfolioTable extends StatefulWidget {
  final bool isDark;
  final int touchedIndex;
  final List<Cryptocurrency> cryptocurrencies;
  final Function(int touchedIndex) onTouch;

  const HomePortfolioTable({
    Key? key,
    required this.isDark,
    required this.touchedIndex,
    required this.cryptocurrencies,
    required this.onTouch,
  }) : super(key: key);

  @override
  State<HomePortfolioTable> createState() => _HomePortfolioTableState();
}

class _HomePortfolioTableState extends State<HomePortfolioTable> {
  late double totalValue;
  @override
  void initState() {
    super.initState();
    totalValue = widget.cryptocurrencies.fold(
      0.0,
      (sum, crypto) => sum + crypto.usdtValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int touchedIndex = widget.touchedIndex;
        return CustomContainer(
          isDark: widget.isDark,
          children: [
            DataTable(
              columns: const [
                DataColumn(label: Center(child: Text('Symbol'))),
                DataColumn(label: Center(child: Text('Amount'))),
                DataColumn(label: Center(child: Text('Value'))),
                DataColumn(label: Center(child: Text('Value %'))),
              ],
              rows: widget.cryptocurrencies.asMap().entries.map((entry) {
                final index = entry.key;
                final crypto = entry.value;
                final isHighlighted = index == touchedIndex;
                final percentage = (crypto.usdtValue / totalValue) * 100;

                return DataRow(
                  cells: [
                    DataCell(
                      MouseRegion(
                        onEnter: (_) => widget.onTouch(index),
                        onExit: (_) => widget.onTouch(-1),
                        child: Row(
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
                                fontWeight: isHighlighted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      MouseRegion(
                        onEnter: (_) => widget.onTouch(index),
                        onExit: (_) => widget.onTouch(-1),
                        child: Text(
                          crypto.amount.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      MouseRegion(
                        onEnter: (_) => widget.onTouch(index),
                        onExit: (_) => widget.onTouch(-1),
                        child: Text(
                          '${crypto.usdtValue.toStringAsFixed(2)}\$ USDT',
                          style: TextStyle(
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      MouseRegion(
                        onEnter: (_) => widget.onTouch(index),
                        onExit: (_) => widget.onTouch(-1),
                        child: Text(
                          '${percentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            )
          ],
        );
      },
    );
  }
}
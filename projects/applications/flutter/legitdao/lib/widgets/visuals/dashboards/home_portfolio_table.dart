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
  int? _selectedRowIndex; // Track the selected row index

  @override
  void initState() {
    super.initState();
    totalValue = widget.cryptocurrencies.fold(
      0.0,
      (sum, crypto) => sum + crypto.usdtValue,
    );
  }

  void _selectRow(int index) {
    setState(() {
      _selectedRowIndex = index; // Set the selected row index
    });
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
                final isSelected = _selectedRowIndex == index;
                final percentage = (crypto.usdtValue / totalValue) * 100;

                return DataRow(
                  onSelectChanged: (_) {
                    widget.onTouch(index);
                    _selectRow(index);
                  },
                  selected: isSelected,
                  cells: [
                    DataCell(
                      Row(
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
                    DataCell(
                      Text(
                        crypto.amount.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${crypto.usdtValue.toStringAsFixed(2)}\$ USDT',
                        style: TextStyle(
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${percentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
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

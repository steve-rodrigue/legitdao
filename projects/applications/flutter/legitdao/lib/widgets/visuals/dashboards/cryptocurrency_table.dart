import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../linecharts/custom_line_chart.dart';
import '../containers/custom_container.dart';

class Cryptocurrency {
  final String name;
  final String slug;
  final String logoPath;
  final double price;
  final double change1h;
  final double change24h;
  final double change7d;
  final double volume24h;
  final double marketCap;
  final List<double> data;

  Cryptocurrency({
    required this.name,
    required this.slug,
    required this.logoPath,
    required this.price,
    required this.change1h,
    required this.change24h,
    required this.change7d,
    required this.volume24h,
    required this.marketCap,
    required this.data,
  });
}

class CryptocurrencyTable extends StatefulWidget {
  final bool isDark;
  final List<Cryptocurrency> cryptocurrencies;

  const CryptocurrencyTable(
      {Key? key, required this.isDark, required this.cryptocurrencies})
      : super(key: key);

  @override
  State<CryptocurrencyTable> createState() => _CryptocurrencyTableState();
}

class _CryptocurrencyTableState extends State<CryptocurrencyTable> {
  int? selectedRowIndex;

  void _onRowSelected(int index) {
    setState(() {
      selectedRowIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      isDark: widget.isDark,
      children: [
        DataTable(
          columns: const [
            DataColumn(label: Text('Cryptocurrency')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('1h %')),
            DataColumn(label: Text('24h %')),
            DataColumn(label: Text('7d %')),
            DataColumn(label: Text('24h Volume')),
            DataColumn(label: Text('Market Cap')),
            DataColumn(label: Text('Last 7 Days')),
          ],
          rows: widget.cryptocurrencies.asMap().entries.map((entry) {
            final index = entry.key;
            final crypto = entry.value;
            final isSelected = index == selectedRowIndex;

            return DataRow(
              selected: isSelected,
              cells: [
                // Cryptocurrency Logo and Name
                DataCell(
                  Row(
                    children: [
                      SvgPicture.asset(
                        crypto.logoPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(crypto.name),
                    ],
                  ),
                  onTap: () {
                    _onRowSelected(index);
                    Navigator.pushNamed(
                        context, '/marketplaces/${crypto.slug}');
                  },
                ),
                // Price
                DataCell(Text('\$${crypto.price.toStringAsFixed(2)}')),
                // 1h % Change
                _buildPercentageCell(context, crypto.change1h),
                // 24h % Change
                _buildPercentageCell(context, crypto.change24h),
                // 7d % Change
                _buildPercentageCell(context, crypto.change7d),
                // 24h Volume
                DataCell(Text('\$${_formatLargeNumber(crypto.volume24h)}')),
                // Market Cap
                DataCell(Text('\$${_formatLargeNumber(crypto.marketCap)}')),

                // Line Graph
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 150.0,
                        height: 150.0 * (16 / 9),
                        child: CustomLineChart(
                          width: 150.0,
                          data: crypto.data,
                        ),
                      )
                    ],
                  ),
                  onTap: () {
                    _onRowSelected(index);
                    Navigator.pushNamed(
                        context, '/marketplaces/${crypto.slug}');
                  },
                ),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  DataCell _buildPercentageCell(BuildContext context, double change) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    return DataCell(
      Row(
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${change.toStringAsFixed(2)}%',
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(double number) {
    if (number >= 1e12) return '${(number / 1e12).toStringAsFixed(1)}T';
    if (number >= 1e9) return '${(number / 1e9).toStringAsFixed(1)}B';
    if (number >= 1e6) return '${(number / 1e6).toStringAsFixed(1)}M';
    if (number >= 1e3) return '${(number / 1e3).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }
}

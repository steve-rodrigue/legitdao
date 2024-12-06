import 'package:flutter/material.dart';

class TokensList extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const TokensList({Key? key, required this.data}) : super(key: key);

  @override
  _TokensListState createState() => _TokensListState();
}

class _TokensListState extends State<TokensList> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16.0,
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('1h')),
            DataColumn(label: Text('7h')),
            DataColumn(label: Text('24h')),
            DataColumn(label: Text('7d')),
            DataColumn(label: Text('24h Volume')),
            DataColumn(label: Text('Market Cap')),
            DataColumn(label: Text('Last 7 days')),
          ],
          rows: widget.data
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row['name'] ?? '')),
                    DataCell(Text(row['category'] ?? '')),
                    DataCell(Text(row['1h']?.toString() ?? '')),
                    DataCell(Text(row['7h']?.toString() ?? '')),
                    DataCell(Text(row['24h']?.toString() ?? '')),
                    DataCell(Text(row['7d']?.toString() ?? '')),
                    DataCell(Text(row['24h_volume']?.toString() ?? '')),
                    DataCell(Text(row['market_cap']?.toString() ?? '')),
                    DataCell(Text(row['last_7_days'] ?? '')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

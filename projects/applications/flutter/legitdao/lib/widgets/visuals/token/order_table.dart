import 'package:flutter/material.dart';
import '../containers/custom_container.dart';
import 'package:legitdao/widgets/visuals/header.dart';

class OrderTable extends StatefulWidget {
  final bool isDark;
  final String title;
  final List<TokenRowData> tokenData;

  const OrderTable(
      {Key? key,
      required this.isDark,
      required this.title,
      required this.tokenData})
      : super(key: key);

  @override
  _OrderTableState createState() => _OrderTableState();
}

class _OrderTableState extends State<OrderTable> {
  @override
  Widget build(BuildContext context) {
    return CustomContainer(isDark: widget.isDark, children: [
      Header(value: widget.title, isSmall: true),
      DataTable(
        columns: const [
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Unit Price')),
          DataColumn(label: Text('Total Price')),
        ],
        rows: widget.tokenData.map((data) {
          return DataRow(
            cells: [
              DataCell(Text(data.tokenAmount.toString())),
              DataCell(Text(data.pricePerToken.toStringAsFixed(2))),
              DataCell(Text(data.totalPrice.toStringAsFixed(2))),
            ],
          );
        }).toList(),
      ),
    ]);
  }
}

class TokenRowData {
  final int tokenAmount;
  final double pricePerToken;
  final double totalPrice;

  TokenRowData({
    required this.tokenAmount,
    required this.pricePerToken,
    required this.totalPrice,
  });
}

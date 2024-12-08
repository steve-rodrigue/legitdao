import 'package:flutter/material.dart';
import 'package:legitdao/widgets/visuals/header.dart';
import '../containers/custom_title_container.dart';
import 'order_table.dart';

class OrderBook extends StatefulWidget {
  final bool isDark;
  final List<TokenRowData> initialBuyOrders;
  final List<TokenRowData> initialSellOrders;

  const OrderBook({
    Key? key,
    required this.isDark,
    required this.initialBuyOrders,
    required this.initialSellOrders,
  }) : super(key: key);

  @override
  _OrderBookState createState() => _OrderBookState();
}

class _OrderBookState extends State<OrderBook> {
  late List<TokenRowData> buyOrders;
  late List<TokenRowData> sellOrders;

  @override
  void initState() {
    super.initState();
    buyOrders = widget.initialBuyOrders;
    sellOrders = widget.initialSellOrders;
  }

  void addBuyOrder(TokenRowData newOrder) {
    setState(() {
      buyOrders.add(newOrder);
    });
  }

  void addSellOrder(TokenRowData newOrder) {
    setState(() {
      sellOrders.add(newOrder);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomTitleContainer(
      isDark: widget.isDark,
      title: [
        Text(
          "Orders Book",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
      body: [
        Container(
          padding: const EdgeInsets.all(10.0),
          alignment: AlignmentDirectional.center,
          child: Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: [
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                alignment: WrapAlignment.start,
                children: [
                  Container(
                      width: 300.0,
                      child: OrderTable(
                          isDark: widget.isDark,
                          title: "Buy",
                          tokenData: buyOrders)),
                  Container(
                    width: 300.0,
                    child: OrderTable(
                        isDark: widget.isDark,
                        title: "Sell",
                        tokenData: buyOrders),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

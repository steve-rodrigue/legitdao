import 'package:flutter/material.dart';
import 'package:legitdao/widgets/visuals/header.dart';
import '../containers/custom_title_container.dart';
import '../containers/custom_container.dart';
import 'order_table.dart';
import 'token_buy.dart';
import 'token_sell.dart';

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
        Header(
          value: "Orders Book",
          isMedium: true,
        )
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
                      child: Column(
                        children: [
                          CustomContainer(isDark: widget.isDark, children: [
                            OrderTable(
                                isDark: widget.isDark,
                                title: "Buy Orders",
                                tokenData: buyOrders),
                            TokenBuy(
                                isDark: widget.isDark,
                                executeTrade: (amount, price) {
                                  print(
                                      "Executing buy: Amount = $amount, Price = $price");
                                }),
                          ]),
                        ],
                      )),
                  Container(
                    width: 300.0,
                    child: CustomContainer(isDark: widget.isDark, children: [
                      OrderTable(
                          isDark: widget.isDark,
                          title: "Sell Orders",
                          tokenData: sellOrders),
                      TokenSell(
                          isDark: widget.isDark,
                          executeTrade: (amount, price) {
                            print(
                                "Executing sell: Amount = $amount, Price = $price");
                          }),
                    ]),
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

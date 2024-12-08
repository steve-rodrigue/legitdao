import 'package:flutter/material.dart';

class TokenSell extends StatefulWidget {
  final bool isDark;
  final Function(double amount, double price) executeTrade;

  const TokenSell({
    Key? key,
    required this.isDark,
    required this.executeTrade,
  }) : super(key: key);

  @override
  State<TokenSell> createState() => _TokenSellState();
}

class _TokenSellState extends State<TokenSell> {
  TextEditingController tokenAmountController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  double bnbExpectation = 0.0;
  double taxesExpectation = 0.0;
  String selectedOrderType = "Limit Order";

  void _updateBNBExpectation() {
    final double? amount = double.tryParse(tokenAmountController.text);
    final double? price = double.tryParse(priceController.text);

    if (amount != null && price != null) {
      setState(() {
        bnbExpectation = amount * (price / 736);
      });
    } else {
      setState(() {
        bnbExpectation = 0.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    tokenAmountController.addListener(_updateBNBExpectation);
    priceController.addListener(_updateBNBExpectation);
  }

  @override
  void dispose() {
    tokenAmountController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount of Tokens
          TextField(
            controller: tokenAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Amount of Tokens",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16.0),

          // Order Type Selector
          DropdownButton<String>(
            value: selectedOrderType,
            onChanged: (String? value) {
              setState(() {
                selectedOrderType = value!;
              });
            },
            items: [
              DropdownMenuItem(
                value: "Limit Order",
                child: Text("Limit Order"),
              ),
              DropdownMenuItem(
                value: "Market Price",
                child: Text("Market Price"),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Conditional TextField
          if (selectedOrderType == "Limit Order")
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Limit Unit Price (USD\$)",
                border: OutlineInputBorder(),
              ),
            )
          else if (selectedOrderType == "Market Price")
            TextField(
              controller: TextEditingController(
                text: "50.00", // Example static value
              ),
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Market Unit Order (USD\$)",
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16.0),

          // BNB Expectation (Read-Only)
          TextField(
            controller: TextEditingController(
              text: bnbExpectation.toStringAsFixed(2),
            ),
            readOnly: true,
            decoration: InputDecoration(
              labelText: "BNB You Receive",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16.0),

          // Execute Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                final double? amount =
                    double.tryParse(tokenAmountController.text);
                final double? price = double.tryParse(priceController.text);

                if (amount != null && price != null) {
                  widget.executeTrade(amount, price);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Invalid input. Please check your values."),
                    ),
                  );
                }
              },
              child: const Text("Execute"),
            ),
          ),
        ],
      ),
    );
  }
}

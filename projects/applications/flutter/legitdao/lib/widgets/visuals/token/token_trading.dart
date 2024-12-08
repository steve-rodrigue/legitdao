import 'package:flutter/material.dart';
import '../containers/custom_container.dart';
import '../header.dart';

class TokenTrading extends StatefulWidget {
  final bool isDark;

  const TokenTrading({
    Key? key,
    required this.isDark,
  }) : super(key: key);

  @override
  _TokenTradingState createState() => _TokenTradingState();
}

class _TokenTradingState extends State<TokenTrading> {
  double bnbBalance = 1.5; // Example balance
  double usdtBalance = 300.0; // Example balance
  String selectedFromCurrency = 'BNB';
  String selectedToCurrency = 'ETH';
  TextEditingController bnbController = TextEditingController();
  TextEditingController ethController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomContainer(isDark: widget.isDark, children: [
      Header(value: "Place a Trade", isSmall: true),
      Container(
        padding: const EdgeInsets.all(10.0),
        alignment: AlignmentDirectional.center,
        child: Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          alignment: WrapAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balances
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "BNB Balance: $bnbBalance",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "USDT Balance: $usdtBalance",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Conversion form
                      Row(
                        children: [
                          // Input for BNB amount
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: bnbController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Amount (BNB)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          // Currency switcher
                          DropdownButton<String>(
                            value: selectedFromCurrency,
                            items: ['BNB', 'USDT'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedFromCurrency = newValue!;
                              });
                            },
                          ),
                          SizedBox(width: 10),
                          // "To" label
                          Text("To", style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          // Input for ETH amount
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: ethController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Amount (ETH)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          // Currency selector for target
                          DropdownButton<String>(
                            value: selectedToCurrency,
                            items: ['BNB', 'ETH'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedToCurrency = newValue!;
                              });
                            },
                          ),
                          SizedBox(width: 10),
                          // Submit button
                          IconButton(
                            onPressed: () {
                              // Handle submission
                              print("Submitting conversion...");
                            },
                            icon: Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }
}

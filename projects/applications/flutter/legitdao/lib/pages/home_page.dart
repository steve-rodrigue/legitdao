import 'package:flutter/material.dart';
import '../widgets/visuals/header.dart';
import '../widgets/visuals/paragraph.dart';
import '../widgets/visuals/custom_line_chart.dart';
import '../widgets/visuals/custom_candlestick_chart.dart';
import '../widgets/visuals/custom_pie_chart.dart';
import '../widgets/visuals/custom_bar_chart.dart';
import 'dart:math';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        thumbVisibility: true, // Ensure the scrollbar thumb is visible
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Header(
                value: 'home_title',
                isLarge: true,
              ),
              CustomBarChart(
                width: MediaQuery.of(context).size.width,
                newReferrals:
                    List.generate(2000, (index) => Random().nextInt(100)),
                soldReferrals:
                    List.generate(2000, (index) => Random().nextInt(100)),
              ),
              CustomPieChart(width: 800.0, cryptocurrencies: [
                Cryptocurrency(
                    logoPath:
                        'lib/assets/icons/svg/cryptocurrencies/color/bnb.svg',
                    symbol: 'BNB',
                    color: Colors.yellow,
                    amount: 500,
                    usdtValue: 320),
                Cryptocurrency(
                    logoPath:
                        'lib/assets/icons/svg/cryptocurrencies/color/eth.svg',
                    symbol: 'ETH',
                    color: Colors.purple,
                    amount: 300,
                    usdtValue: 2000),
                Cryptocurrency(
                    logoPath:
                        'lib/assets/icons/svg/cryptocurrencies/color/bab.svg',
                    symbol: 'WebX',
                    color: Colors.blue,
                    amount: 200,
                    usdtValue: 1000),
                Cryptocurrency(
                    logoPath:
                        'lib/assets/icons/svg/cryptocurrencies/color/grt.svg',
                    symbol: 'GRT',
                    color: Colors.deepPurple,
                    amount: 500,
                    usdtValue: 500),
                Cryptocurrency(
                    logoPath:
                        'lib/assets/icons/svg/cryptocurrencies/color/etp.svg',
                    symbol: 'CAKE',
                    color: Colors.brown,
                    amount: 4500,
                    usdtValue: 2000),
              ]),
              CustomLineChart(
                width: 900.0,
                data: List.generate(2000, (index) => (index + 1) * 2.5),
              ),
              CustomCandleStickChart(
                width: 900.0,
                data: List.generate(2000, (index) => (index + 1) * 2.5),
              ),
              Paragraph(value: 'home_first_paragraph', isLarge: true),
              Paragraph(value: 'home_second_paragraph', isLarge: true),
            ],
          ),
        ),
      ),
    );
  }
}

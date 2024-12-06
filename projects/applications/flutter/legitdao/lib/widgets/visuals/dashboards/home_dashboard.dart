import 'package:flutter/material.dart';
import '../piecharts/cryptocurrency.dart';
import 'home_portfolio.dart';

class HomeDashboard extends StatefulWidget {
  final bool isDark;

  const HomeDashboard({
    Key? key,
    required this.isDark,
  }) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  List<Cryptocurrency> cryptocurrencies = [];

  @override
  void initState() {
    super.initState();
    cryptocurrencies = [
      Cryptocurrency(
          logoPath: 'lib/assets/icons/svg/cryptocurrencies/color/bnb.svg',
          symbol: 'BNB',
          color: Colors.yellow,
          amount: 500,
          usdtValue: 320),
      Cryptocurrency(
          logoPath: 'lib/assets/icons/svg/cryptocurrencies/color/eth.svg',
          symbol: 'ETH',
          color: Colors.purple,
          amount: 300,
          usdtValue: 2000),
      Cryptocurrency(
          logoPath: 'lib/assets/icons/svg/cryptocurrencies/color/bab.svg',
          symbol: 'WebX',
          color: Colors.blue,
          amount: 200,
          usdtValue: 1000),
      Cryptocurrency(
          logoPath: 'lib/assets/icons/svg/cryptocurrencies/color/grt.svg',
          symbol: 'GRT',
          color: Colors.deepPurple,
          amount: 500,
          usdtValue: 500),
      Cryptocurrency(
          logoPath: 'lib/assets/icons/svg/cryptocurrencies/color/etp.svg',
          symbol: 'CAKE',
          color: Colors.brown,
          amount: 4500,
          usdtValue: 2000),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: [
              HomePortfolio(
                  isDark: widget.isDark,
                  cryptocurrencies: cryptocurrencies,
                  width: width * 0.4),
              HomePortfolio(
                  isDark: widget.isDark,
                  cryptocurrencies: cryptocurrencies,
                  width: width * 0.4),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../piecharts/cryptocurrency.dart';
import 'home_portfolio_table.dart';
import '../containers/custom_title_container.dart';
import '../piecharts/custom_pie_chart.dart';

class HomePortfolio extends StatefulWidget {
  final bool isDark;
  final List<Cryptocurrency> cryptocurrencies;
  final double width;

  const HomePortfolio({
    Key? key,
    required this.isDark,
    required this.cryptocurrencies,
    required this.width,
  }) : super(key: key);

  @override
  State<HomePortfolio> createState() => _HomePortfolioState();
}

class _HomePortfolioState extends State<HomePortfolio> {
  int touchedIndex = -1;
  late double totalValue;

  @override
  void initState() {
    super.initState();
    totalValue = widget.cryptocurrencies
        .fold(0.0, (sum, crypto) => sum + crypto.usdtValue);
  }

  void _onTouch(int _touchedIndex) {
    setState(() {
      touchedIndex = _touchedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    double pieChartWidth = widget.width / 2;
    if (pieChartWidth > 300.0) {
      pieChartWidth = 300.0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomTitleContainer(
          isDark: widget.isDark,
          width: widget.width,
          title: [
            Text(
              "Portfolio",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
          body: [
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              alignment: WrapAlignment.center,
              children: [
                CustomPieChart(
                  width: pieChartWidth,
                  touchedIndex: touchedIndex,
                  cryptocurrencies: widget.cryptocurrencies,
                  onTouch: _onTouch,
                ),
                HomePortfolioTable(
                  isDark: widget.isDark,
                  touchedIndex: touchedIndex,
                  cryptocurrencies: widget.cryptocurrencies,
                  onTouch: _onTouch,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

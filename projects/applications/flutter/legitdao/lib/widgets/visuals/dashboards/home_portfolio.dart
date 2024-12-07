import 'package:flutter/material.dart';
import '../piecharts/cryptocurrency.dart';
import 'home_portfolio_table.dart';
import '../containers/custom_title_container.dart';
import '../piecharts/custom_pie_chart.dart';

class HomePortfolio extends StatefulWidget {
  final bool isDark;
  final List<Cryptocurrency> cryptocurrencies;

  const HomePortfolio({
    Key? key,
    required this.isDark,
    required this.cryptocurrencies,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomTitleContainer(
          isDark: widget.isDark,
          title: [
            Text(
              "Portfolio",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
          body: [
            Container(
              alignment: AlignmentDirectional.center,
              child: Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                alignment: WrapAlignment.center,
                children: [
                  CustomPieChart(
                    width: 300.0,
                    touchedIndex: touchedIndex,
                    cryptocurrencies: widget.cryptocurrencies,
                    onTouch: _onTouch,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: HomePortfolioTable(
                      isDark: widget.isDark,
                      touchedIndex: touchedIndex,
                      cryptocurrencies: widget.cryptocurrencies,
                      onTouch: _onTouch,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

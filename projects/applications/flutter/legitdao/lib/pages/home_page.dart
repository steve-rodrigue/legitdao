import 'package:flutter/material.dart';
import '../widgets/visuals/header.dart';
import '../widgets/visuals/paragraph.dart';
import '../widgets/visuals/custom_line_chart.dart';
import '../widgets/visuals/custom_candlestick_chart.dart';
import '../widgets/visuals/custom_bar_chart.dart';
import '../widgets/visuals/dashboards/home_dashboard.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  final bool isDark;
  const HomePage({super.key, required this.isDark});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Header(
          value: 'home_title',
          isLarge: true,
        ),
        Paragraph(value: 'home_first_paragraph'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HomeDashboard(
              isDark: widget.isDark,
            ),
            /*CustomBarChart(
          width: MediaQuery.of(context).size.width,
          newReferrals: List.generate(2000, (index) => Random().nextInt(100)),
          soldReferrals: List.generate(2000, (index) => Random().nextInt(100)),
        ),
        CustomLineChart(
          width: 900.0,
          data: List.generate(2000, (index) => (index + 1) * 2.5),
        ),
        CustomCandleStickChart(
          width: 900.0,
          data: List.generate(2000, (index) => (index + 1) * 2.5),
        ),*/
          ],
        ),
      ],
    );
  }
}

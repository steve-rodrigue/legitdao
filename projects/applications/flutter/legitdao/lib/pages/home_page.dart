import 'package:flutter/material.dart';
import '../widgets/visuals/header.dart';
import '../widgets/visuals/paragraph.dart';
import '../widgets/visuals/custom_line_chart.dart';
import '../widgets/visuals/custom_candlestick_chart.dart';

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

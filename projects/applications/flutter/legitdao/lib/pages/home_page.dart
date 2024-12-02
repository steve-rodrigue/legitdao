import 'package:flutter/material.dart';
import '../widgets/visuals/header.dart';
import '../widgets/visuals/paragraph.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Header(
            value: 'home_title',
            isLarge: true,
          ),
          Paragraph(value: 'home_first_paragraph', isLarge: true),
          Paragraph(value: 'home_second_paragraph', isLarge: true),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/visuals/header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Header(
      value: 'about_title',
      isLarge: true,
    );
  }
}

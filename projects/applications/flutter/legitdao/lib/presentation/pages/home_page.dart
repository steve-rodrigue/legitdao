import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text(
          "home_title",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ).tr(),
      ),
    );
  }
}

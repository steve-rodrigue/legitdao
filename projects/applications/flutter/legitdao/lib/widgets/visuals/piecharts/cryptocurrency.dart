import 'package:flutter/material.dart';

class Cryptocurrency {
  final String logoPath;
  final String symbol;
  final Color color;
  final double amount;
  final double usdtValue;

  Cryptocurrency({
    required this.logoPath,
    required this.symbol,
    required this.color,
    required this.amount,
    required this.usdtValue,
  });
}

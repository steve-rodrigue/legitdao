import 'package:flutter/material.dart';

class ResponsiveLogo extends StatelessWidget {
  final String logoPath;

  const ResponsiveLogo({
    super.key,
    required this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the logo size based on screen width
    double logoWidth = screenWidth * 0.4; // 40% of screen width
    if (logoWidth > 200) {
      logoWidth = 200; // Cap at original size for larger screens
    }

    // Maintain aspect ratio of 4:1 (320x80)
    final logoHeight = logoWidth / 4;

    return Image.asset(
      logoPath,
      width: logoWidth,
      height: logoHeight,
      fit: BoxFit.contain,
    );
  }
}

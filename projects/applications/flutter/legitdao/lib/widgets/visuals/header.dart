import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class Header extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;
  final bool isSmall;
  final String value;

  const Header({
    super.key,
    required this.value,
    this.isLarge = false,
    this.isMedium = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    TextStyle textStyle = const TextStyle(fontWeight: FontWeight.bold);

    if (isLarge && theme.textTheme.headlineLarge != null) {
      textStyle = textStyle.merge(theme.textTheme.headlineLarge);
    }

    if (isMedium && theme.textTheme.headlineMedium != null) {
      textStyle = textStyle.merge(theme.textTheme.headlineMedium);
    }

    if (isSmall && theme.textTheme.headlineSmall != null) {
      textStyle = textStyle.merge(theme.textTheme.headlineSmall);
    }

    return Text(
      value.tr(),
      style: textStyle,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class Paragraph extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;
  final bool isSmall;
  final String value;

  const Paragraph({
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

    if (isLarge && theme.textTheme.bodyLarge != null) {
      textStyle = textStyle.merge(theme.textTheme.bodyLarge);
    }

    if (isMedium && theme.textTheme.bodyMedium != null) {
      textStyle = textStyle.merge(theme.textTheme.bodyMedium);
    }

    if (isSmall && theme.textTheme.bodySmall != null) {
      textStyle = textStyle.merge(theme.textTheme.bodySmall);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Text(
        value.tr(),
        style: textStyle,
      ),
    );
  }
}

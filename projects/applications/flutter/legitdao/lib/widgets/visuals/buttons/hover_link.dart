import 'package:flutter/material.dart';

class HoverLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isInMenu;

  const HoverLink({
    Key? key,
    required this.text,
    required this.onTap,
    required this.isInMenu,
  }) : super(key: key);

  @override
  _HoverLinkState createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  late Color _currentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use the current theme's color scheme
    _currentColor = theme.colorScheme.primary;

    // If we are in a menu, fetch the bodyMedium, ortherwise, the bodySmall:
    TextStyle textStyle = theme.textTheme.bodySmall?.copyWith(
      color: _currentColor,
      decoration: TextDecoration.underline, // Underline to look like a link
    ) as TextStyle;

    if (widget.isInMenu) {
      textStyle = theme.textTheme.bodyLarge?.copyWith(
        color: _currentColor,
        decoration: TextDecoration.underline, // Underline to look like a link
      ) as TextStyle;
    }

    return InkWell(
      onTap: widget.onTap,
      onHover: (isHovering) {
        setState(() {
          _currentColor = isHovering
              ? theme.colorScheme.secondary // Hover color
              : theme.colorScheme.primary; // Default link color
        });
      },
      child: Text(
        widget.text,
        style: textStyle?.copyWith(color: _currentColor),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CustomContainer extends StatefulWidget {
  final bool isDark;
  final List<Widget> title;
  final List<Widget> body;

  const CustomContainer({
    Key? key,
    required this.isDark,
    required this.title,
    required this.body,
  }) : super(key: key);

  @override
  State<CustomContainer> createState() => _CustomContainerState();
}

class _CustomContainerState extends State<CustomContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Color.fromARGB(255, 58, 58, 58) // dark
            : Color.fromARGB(255, 208, 208, 208), // light
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1.0, // Set the border width
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
                vertical: 8.0), // Optional: Add padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.title,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.body,
          )
        ],
      ),
    );
  }
}

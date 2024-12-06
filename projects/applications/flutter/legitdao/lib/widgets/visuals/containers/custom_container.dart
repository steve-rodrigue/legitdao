import 'package:flutter/material.dart';

class CustomContainer extends StatefulWidget {
  final bool isDark;
  final List<Widget> children;

  const CustomContainer({
    Key? key,
    required this.isDark,
    required this.children,
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
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Color.fromARGB(255, 28, 28, 28) // dark
            : Color.fromARGB(255, 255, 255, 255), // light
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
        children: widget.children,
      ),
    );
  }
}

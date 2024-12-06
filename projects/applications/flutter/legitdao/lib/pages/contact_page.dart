import 'package:flutter/material.dart';
import '../widgets/visuals/header.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Header(
      value: 'contact_title',
      isLarge: true,
    );
  }
}

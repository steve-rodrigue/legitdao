import 'package:flutter/material.dart';
import 'package:legitdao/widgets/visuals/lists/tokens_list.dart';

class TokensPage extends StatefulWidget {
  final bool isDark;
  const TokensPage({super.key, required this.isDark});

  @override
  _TokensPageState createState() => _TokensPageState();
}

class _TokensPageState extends State<TokensPage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TokensList(
        isDark: widget.isDark,
      ),
    ]);
  }
}

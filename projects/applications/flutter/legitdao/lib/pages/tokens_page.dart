import 'package:flutter/material.dart';
import 'package:legitdao/widgets/visuals/lists/tokens_list.dart';
import '../widgets/visuals/containers/custom_title_container.dart';

class TokensPage extends StatelessWidget {
  const TokensPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Container:
        CustomTitleContainer(isDark: true, width: 800.0, title: [
          Text(
            "Tokens",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ], body: [
          TokensList(data: [
            {
              'name': 'Bitcoin',
              'category': 'Cryptocurrency',
              '1h': '0.5%',
              '7h': '2.1%',
              '24h': '3.2%',
              '7d': '-1.3%',
              '24h_volume': '\$50B',
              'market_cap': '\$1T',
              'last_7_days': 'Uptrend',
            },
            {
              'name': 'Ethereum',
              'category': 'Cryptocurrency',
              '1h': '0.3%',
              '7h': '1.8%',
              '24h': '2.4%',
              '7d': '-0.9%',
              '24h_volume': '\$30B',
              'market_cap': '\$500B',
              'last_7_days': 'Downtrend',
            },
          ])
        ])
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/referrals/referrals.dart';
import '../widgets/visuals/header.dart';

class ReferralsPage extends StatefulWidget {
  final String walletAddress;

  ReferralsPage({
    super.key,
    required this.walletAddress,
  });

  @override
  _ReferralsState createState() => _ReferralsState();
}

class _ReferralsState extends State<ReferralsPage>
    with TickerProviderStateMixin {
  String walletAddress = "";
  @override
  void initState() {
    super.initState();
    walletAddress = widget.walletAddress;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          value: 'referrals_title',
          isLarge: true,
        ),
        Container(
          child: Center(
            child: Referrals(walletAddress: walletAddress),
          ),
        )
      ],
    );
  }
}

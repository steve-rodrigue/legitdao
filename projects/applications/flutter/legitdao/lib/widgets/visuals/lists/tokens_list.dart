import 'package:flutter/material.dart';
import '../containers/custom_title_container.dart';
import 'cryptocurrency_table.dart';

class TokensList extends StatefulWidget {
  final bool isDark;

  const TokensList({
    Key? key,
    required this.isDark,
  }) : super(key: key);

  @override
  State<TokensList> createState() => _TokensListState();
}

class _TokensListState extends State<TokensList> {
  late double totalValue;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomTitleContainer(
          isDark: widget.isDark,
          title: [
            Text(
              "Tokens List",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
          body: [
            Container(
              alignment: AlignmentDirectional.center,
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child:
                  CryptocurrencyTable(isDark: widget.isDark, cryptocurrencies: [
                Cryptocurrency(
                  name: 'WebX',
                  slug: 'webx',
                  logoPath:
                      'lib/assets/icons/svg/cryptocurrencies/color/eth.svg',
                  price: 50250.34,
                  change1h: 0.45,
                  change24h: -1.23,
                  change7d: 5.67,
                  volume24h: 3500000000,
                  marketCap: 950000000000,
                  data: [
                    10.0,
                    15.0,
                    18.0,
                    20.0,
                    28.35719821195647,
                    22.94856458640831,
                    27.300652144300834,
                    25.542210669641825,
                    28.618587572679687,
                    24.01239716427079,
                    28.648757285260906,
                    27.240244463771322,
                    27.744663175979763,
                    26.52603500339095,
                    29.802047997748886,
                    20.698563520754153,
                    27.56871820985005,
                    21.236825773419323,
                    29.662287169975635,
                    21.00788694488555,
                    20.173765195843348,
                    25.28816622683866,
                    24.01109766739085,
                    23.99644126954308,
                    23.596396571194237,
                    29.70121489158752,
                    28.310708874212317,
                    22.033253158160754,
                    27.827089660930262,
                    22.43154034213831,
                    25.638177364162498,
                    35.0,
                    40.0,
                    50.0,
                    59.58816719972447,
                    54.2663898839295,
                    41.24995953829125,
                    40.98278729570632,
                    42.51842577578454,
                    55.57006096068373,
                    52.18064514747323,
                    43.52427482115903,
                    56.53744187474935,
                    58.25844979108638,
                    41.23863360722041,
                    51.78559016699918,
                    48.50734642202598,
                    59.949212609372466,
                    52.86417045459305,
                    42.51117197466254,
                    52.387436068441836,
                    45.54687899452756,
                    56.9382875111982,
                    52.689222981755705,
                    52.68740301686769,
                    48.840895014490066,
                    50.98559576952683,
                    50.85628312808154,
                    48.33520607769428,
                    55.4052503322643,
                    49.57642978598943,
                    40.28689397128206,
                    57.094600316239095,
                    54.17261218017299,
                    58.50229021331334,
                    42.44205681090292,
                    53.71155983279585,
                    42.16842587121833,
                    43.53732838354192,
                    58.48942988530358,
                    43.92625912202494,
                    59.76197664592774,
                    45.16505637627591,
                    51.50487098315015,
                    58.89255236345187,
                    56.19698622201208,
                    46.88922413737163,
                    51.71041039503713,
                    59.25199986834945,
                    55.261025350081056,
                    45.307838592752596,
                    55.69801736222112,
                    53.38662916142599,
                    48.57106816079562
                  ],
                ),
                Cryptocurrency(
                  name: 'LegitDAO',
                  slug: 'legitdao',
                  logoPath:
                      'lib/assets/icons/svg/cryptocurrencies/color/bnb.svg',
                  price: 3400.67,
                  change1h: 1.12,
                  change24h: -0.98,
                  change7d: 2.34,
                  volume24h: 2200000000,
                  marketCap: 450000000000,
                  data: [
                    10.0,
                    15.0,
                    18.0,
                    20.0,
                    28.35719821195647,
                    22.94856458640831,
                    27.300652144300834,
                    25.542210669641825,
                    28.618587572679687,
                    24.01239716427079,
                    28.648757285260906,
                    27.240244463771322,
                    27.744663175979763,
                    26.52603500339095,
                    29.802047997748886,
                    20.698563520754153,
                    27.56871820985005,
                    21.236825773419323,
                    29.662287169975635,
                    21.00788694488555,
                    20.173765195843348,
                    25.28816622683866,
                    24.01109766739085,
                    23.99644126954308,
                    23.596396571194237,
                    29.70121489158752,
                    28.310708874212317,
                    22.033253158160754,
                    27.827089660930262,
                    22.43154034213831,
                    25.638177364162498,
                    35.0,
                    40.0,
                    50.0,
                    59.58816719972447,
                    54.2663898839295,
                    41.24995953829125,
                    40.98278729570632,
                    42.51842577578454,
                    55.57006096068373,
                    52.18064514747323,
                    43.52427482115903,
                    56.53744187474935,
                    58.25844979108638,
                    41.23863360722041,
                    51.78559016699918,
                    48.50734642202598,
                    59.949212609372466,
                    52.86417045459305,
                    42.51117197466254,
                    52.387436068441836,
                    45.54687899452756,
                    56.9382875111982,
                    52.689222981755705,
                    52.68740301686769,
                    48.840895014490066,
                    50.98559576952683,
                    50.85628312808154,
                    48.33520607769428,
                    55.4052503322643,
                    49.57642978598943,
                    40.28689397128206,
                    57.094600316239095,
                    54.17261218017299,
                    58.50229021331334,
                    42.44205681090292,
                    53.71155983279585,
                    42.16842587121833,
                    43.53732838354192,
                    58.48942988530358,
                    43.92625912202494,
                    59.76197664592774,
                    45.16505637627591,
                    51.50487098315015,
                    58.89255236345187,
                    56.19698622201208,
                    46.88922413737163,
                    51.71041039503713,
                    59.25199986834945,
                    55.261025350081056,
                    45.307838592752596,
                    55.69801736222112,
                    53.38662916142599,
                    48.57106816079562
                  ],
                ),
                Cryptocurrency(
                  name: 'Legit Founder',
                  slug: 'legitfounder',
                  logoPath:
                      'lib/assets/icons/svg/cryptocurrencies/color/grt.svg',
                  price: 3400.67,
                  change1h: 1.12,
                  change24h: -0.98,
                  change7d: 2.34,
                  volume24h: 2200000000,
                  marketCap: 450000000000,
                  data: [
                    10.0,
                    15.0,
                    18.0,
                    20.0,
                    28.35719821195647,
                    22.94856458640831,
                    27.300652144300834,
                    25.542210669641825,
                    28.618587572679687,
                    24.01239716427079,
                    28.648757285260906,
                    27.240244463771322,
                    27.744663175979763,
                    26.52603500339095,
                    29.802047997748886,
                    20.698563520754153,
                    27.56871820985005,
                    21.236825773419323,
                    29.662287169975635,
                    21.00788694488555,
                    20.173765195843348,
                    25.28816622683866,
                    24.01109766739085,
                    23.99644126954308,
                    23.596396571194237,
                    29.70121489158752,
                    28.310708874212317,
                    22.033253158160754,
                    27.827089660930262,
                    22.43154034213831,
                    25.638177364162498,
                    35.0,
                    40.0,
                    50.0,
                    59.58816719972447,
                    54.2663898839295,
                    41.24995953829125,
                    40.98278729570632,
                    42.51842577578454,
                    55.57006096068373,
                    52.18064514747323,
                    43.52427482115903,
                    56.53744187474935,
                    58.25844979108638,
                    41.23863360722041,
                    51.78559016699918,
                    48.50734642202598,
                    59.949212609372466,
                    52.86417045459305,
                    42.51117197466254,
                    52.387436068441836,
                    45.54687899452756,
                    56.9382875111982,
                    52.689222981755705,
                    52.68740301686769,
                    48.840895014490066,
                    50.98559576952683,
                    50.85628312808154,
                    48.33520607769428,
                    55.4052503322643,
                    49.57642978598943,
                    40.28689397128206,
                    57.094600316239095,
                    54.17261218017299,
                    58.50229021331334,
                    42.44205681090292,
                    53.71155983279585,
                    42.16842587121833,
                    43.53732838354192,
                    58.48942988530358,
                    43.92625912202494,
                    59.76197664592774,
                    45.16505637627591,
                    51.50487098315015,
                    58.89255236345187,
                    56.19698622201208,
                    46.88922413737163,
                    51.71041039503713,
                    59.25199986834945,
                    55.261025350081056,
                    45.307838592752596,
                    55.69801736222112,
                    53.38662916142599,
                    48.57106816079562
                  ],
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}

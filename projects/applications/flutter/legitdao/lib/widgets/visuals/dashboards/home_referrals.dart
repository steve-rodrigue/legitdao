import 'package:flutter/material.dart';
import '../containers/custom_title_container.dart';
import 'referrals_table.dart';
import '../barcharts/custom_bar_chart.dart';

class HomeReferrals extends StatefulWidget {
  final bool isDark;
  final double width;

  const HomeReferrals({
    Key? key,
    required this.isDark,
    required this.width,
  }) : super(key: key);

  @override
  State<HomeReferrals> createState() => _HomeReferralsState();
}

class _HomeReferralsState extends State<HomeReferrals> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return CustomTitleContainer(
        isDark: widget.isDark,
        title: [
          Text(
            "New Referrals",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
        body: [
          Container(
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              children: [
                Center(
                  child: CustomBarChart(referrals: [
                    2,
                    5,
                    7,
                    3,
                    8,
                    1,
                    4,
                    6,
                    9,
                    0,
                    10,
                    3,
                    5,
                    7,
                    2,
                    8,
                    6,
                    4,
                    9,
                    1,
                    5,
                    7,
                    2,
                    4,
                    8,
                    10,
                    3,
                    6,
                    9,
                    1
                  ], width: widget.width),
                ),
                ReferralsTable(
                  isDark: widget.isDark,
                  referrals: [
                    Referral(
                      name: "0xA1b2C3d4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0",
                      parent: "0xB1a2D3c4E5F6H7G8I9J0K1L2M3N4O5P6Q7R8S9T1",
                      levelFromMe: 1,
                      creationDate: DateTime.now(),
                    ),
                    Referral(
                      name: "0xC1a2B3d4F5E6G7H8I9J0K1L2M3N4O5P6Q7R8S9T2",
                      parent: "0xA1b2C3d4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0",
                      levelFromMe: 2,
                      creationDate: DateTime.now().subtract(Duration(days: 1)),
                    ),
                    Referral(
                      name: "0xD1a2C3b4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T3",
                      parent: "0xC1a2B3d4F5E6G7H8I9J0K1L2M3N4O5P6Q7R8S9T2",
                      levelFromMe: 3,
                      creationDate: DateTime.now().subtract(Duration(days: 2)),
                    ),
                    Referral(
                      name: "0xE1b2A3c4D5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T4",
                      parent: "0xD1a2C3b4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T3",
                      levelFromMe: 4,
                      creationDate: DateTime.now().subtract(Duration(days: 3)),
                    ),
                    Referral(
                      name: "0xF1a2B3d4C5E6G7H8I9J0K1L2M3N4O5P6Q7R8S9T5",
                      parent: "0xE1b2A3c4D5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T4",
                      levelFromMe: 5,
                      creationDate: DateTime.now().subtract(Duration(days: 4)),
                    ),
                    Referral(
                      name: "0xG1a2B3C4D5E6F7H8I9J0K1L2M3N4O5P6Q7R8S9T6",
                      parent: "0xF1a2B3d4C5E6G7H8I9J0K1L2M3N4O5P6Q7R8S9T5",
                      levelFromMe: 6,
                      creationDate: DateTime.now().subtract(Duration(days: 5)),
                    ),
                    Referral(
                      name: "0xH1a2B3C4D5E6F7G8I9J0K1L2M3N4O5P6Q7R8S9T7",
                      parent: "0xG1a2B3C4D5E6F7H8I9J0K1L2M3N4O5P6Q7R8S9T6",
                      levelFromMe: 1,
                      creationDate: DateTime.now().subtract(Duration(days: 6)),
                    ),
                    Referral(
                      name: "0xI1a2B3C4D5F6G7H8E9J0K1L2M3N4O5P6Q7R8S9T8",
                      parent: "0xH1a2B3C4D5E6F7G8I9J0K1L2M3N4O5P6Q7R8S9T7",
                      levelFromMe: 2,
                      creationDate: DateTime.now().subtract(Duration(days: 7)),
                    ),
                    Referral(
                      name: "0xJ1a2B3C4D5E6F7G8H9I0K1L2M3N4O5P6Q7R8S9T9",
                      parent: "0xI1a2B3C4D5F6G7H8E9J0K1L2M3N4O5P6Q7R8S9T8",
                      levelFromMe: 3,
                      creationDate: DateTime.now().subtract(Duration(hours: 5)),
                    ),
                    Referral(
                      name: "0xK1a2B3C4D5F6E7G8H9I0J1L2M3N4O5P6Q7R8S9T0",
                      parent: "0xJ1a2B3C4D5E6F7G8H9I0K1L2M3N4O5P6Q7R8S9T9",
                      levelFromMe: 4,
                      creationDate:
                          DateTime.now().subtract(Duration(days: 3, hours: 6)),
                    ),
                    Referral(
                      name: "0xL1a2B3C4D5E6F7G8H9I0J1K2M3N4O5P6Q7R8S9T1",
                      parent: "0xK1a2B3C4D5F6E7G8H9I0J1L2M3N4O5P6Q7R8S9T0",
                      levelFromMe: 5,
                      creationDate:
                          DateTime.now().subtract(Duration(days: 2, hours: 4)),
                    ),
                    Referral(
                      name: "0xM1a2B3C4D5E6F7G8H9I0J1K2L3N4O5P6Q7R8S9T2",
                      parent: "0xL1a2B3C4D5E6F7G8H9I0J1K2M3N4O5P6Q7R8S9T1",
                      levelFromMe: 6,
                      creationDate:
                          DateTime.now().subtract(Duration(days: 6, hours: 8)),
                    ),
                    Referral(
                      name: "0xN1a2B3C4D5E6F7G8H9I0J1K2L3M4O5P6Q7R8S9T3",
                      parent: "0xM1a2B3C4D5E6F7G8H9I0J1K2L3N4O5P6Q7R8S9T2",
                      levelFromMe: 1,
                      creationDate:
                          DateTime.now().subtract(Duration(hours: 12)),
                    ),
                    Referral(
                      name: "0xO1a2B3C4D5E6F7G8H9I0J1K2L3M4N5P6Q7R8S9T4",
                      parent: "0xN1a2B3C4D5E6F7G8H9I0J1K2L3M4O5P6Q7R8S9T3",
                      levelFromMe: 2,
                      creationDate:
                          DateTime.now().subtract(Duration(days: 1, hours: 3)),
                    ),
                    Referral(
                      name: "0xP1a2B3C4D5E6F7G8H9I0J1K2L3M4N5O6Q7R8S9T5",
                      parent: "0xO1a2B3C4D5E6F7G8H9I0J1K2L3M4N5P6Q7R8S9T4",
                      levelFromMe: 3,
                      creationDate:
                          DateTime.now().subtract(Duration(days: 4, hours: 1)),
                    ),
                    Referral(
                      name: "0xQ1a2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7R8S9T6",
                      parent: "0xP1a2B3C4D5E6F7G8H9I0J1K2L3M4N5O6Q7R8S9T5",
                      levelFromMe: 4,
                      creationDate:
                          DateTime.now().subtract(Duration(days: 5, hours: 6)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      );
    });
  }
}

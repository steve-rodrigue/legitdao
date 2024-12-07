import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../containers/custom_container.dart';

class Referral {
  final String name;
  final String parent;
  final int levelFromMe;
  final DateTime creationDate;

  Referral({
    required this.name,
    required this.parent,
    required this.levelFromMe,
    required this.creationDate,
  });
}

class ReferralsTable extends StatefulWidget {
  final bool isDark;
  final List<Referral> referrals;

  const ReferralsTable({
    Key? key,
    required this.isDark,
    required this.referrals,
  }) : super(key: key);

  @override
  State<ReferralsTable> createState() => _ReferralsTableState();
}

class _ReferralsTableState extends State<ReferralsTable> {
  int? selectedRowIndex;

  void _onRowSelected(int index) {
    setState(() {
      selectedRowIndex = index;
    });
  }

  String formatAddress(String address) {
    if (address.length <= 6) return address; // Short address fallback
    return '${address.substring(0, 4)}...${address.substring(address.length - 3)}';
  }

  String formatTimestamp(DateTime timestamp) {
    final formatter = DateFormat('MM-dd-yyyy hh:mm');
    return formatter.format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomContainer(
          isDark: widget.isDark,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: widget.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(label: Center(child: Text('Name'))),
                    DataColumn(label: Center(child: Text('Parent'))),
                    DataColumn(label: Center(child: Text('Level'))),
                    DataColumn(label: Center(child: Text('Created At'))),
                  ],
                  rows: widget.referrals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final referral = entry.value;
                    final isSelected = index == selectedRowIndex;

                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (isSelected) {
                        _onRowSelected(index);
                        Navigator.pushNamed(
                          context,
                          '/referrals/${referral.name}',
                        );
                      },
                      cells: [
                        DataCell(
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/referrals/${referral.name}',
                                );
                              },
                              child: Text(
                                formatAddress(referral.name),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/referrals/${referral.parent}',
                                );
                              },
                              child: Text(formatAddress(referral.parent)),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(referral.levelFromMe.toString()),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(formatTimestamp(referral.creationDate)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

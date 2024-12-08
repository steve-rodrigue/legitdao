import 'package:flutter/material.dart';
import '../containers/custom_title_container.dart';

class TokenInformation extends StatefulWidget {
  final bool isDark;
  final Map<String, String> data;

  const TokenInformation({
    Key? key,
    required this.isDark,
    required this.data,
  }) : super(key: key);

  @override
  _TokenInformationState createState() => _TokenInformationState();
}

class _TokenInformationState extends State<TokenInformation> {
  late Map<String, String> tableData;

  @override
  void initState() {
    super.initState();
    tableData = widget.data; // Initialize tableData with the provided data
  }

  @override
  Widget build(BuildContext context) {
    return CustomTitleContainer(
      isDark: widget.isDark,
      title: [
        Text(
          "Information",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
      body: [
        Container(
          padding: const EdgeInsets.all(10.0),
          alignment: AlignmentDirectional.center,
          child: Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2), // Label column width
                  1: FlexColumnWidth(1), // Value column width
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: tableData.entries.map((entry) {
                  return TableRow(
                    children: [
                      // Label cell
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          entry.key,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      // Value cell
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

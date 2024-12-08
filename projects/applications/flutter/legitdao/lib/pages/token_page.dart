import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/visuals/header.dart';
import '../widgets/visuals/token/order_book.dart';
import '../widgets/visuals/token/order_table.dart';
import '../widgets/visuals/paragraph.dart';
import '../widgets/visuals/containers/custom_title_container.dart';
import '../widgets/visuals/token/token_information.dart';

class TokenPage extends StatefulWidget {
  final bool isDark;
  final String tokenSlug;

  const TokenPage({
    super.key,
    required this.isDark,
    required this.tokenSlug,
  });

  @override
  _TokenState createState() => _TokenState();
}

class _TokenState extends State<TokenPage> with TickerProviderStateMixin {
  late String tokenSlug;

  @override
  void initState() {
    super.initState();
    tokenSlug = widget.tokenSlug;
  }

  void _onTokenSelected(String? slug) {
    if (slug != null && slug != tokenSlug) {
      setState(() {
        tokenSlug = slug;
      });
      Navigator.pushNamed(context, '/tokens/$slug');
    }
  }

  Widget _buildDropdown() {
    return DropdownButton<String>(
      value: tokenSlug,
      icon: const Icon(Icons.arrow_drop_down),
      underline: Container(
        height: 2,
        color: Theme.of(context).primaryColor,
      ),
      items: [
        DropdownMenuItem(
          value: 'webx',
          child: Text('WebX'),
        ),
        DropdownMenuItem(
          value: 'legitdao',
          child: Text('LegitDAO'),
        ),
        DropdownMenuItem(
          value: 'legitfounder',
          child: Text('Legit Founder'),
        ),
      ],
      onChanged: _onTokenSelected,
    );
  }

  Widget _buildOneHeader(String title, String paragraph) {
    return CustomTitleContainer(
      isDark: widget.isDark,
      title: [
        Header(
          value: title,
          isLarge: true,
        ),

        // Dropdown Menu
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildDropdown(),
          ),
        ),
      ],
      body: [
        Container(
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Paragraph(value: paragraph),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    switch (widget.tokenSlug) {
      case 'webx':
        return _buildOneHeader(
            "token_header_title_webx".tr(), "token_header_paragraph_webx".tr());
      case 'legitdao':
        return _buildOneHeader("token_header_title_legit".tr(),
            "token_header_paragraph_legit".tr());
      case 'legitfounder':
        return _buildOneHeader("token_header_title_legit_founder".tr(),
            "token_header_paragraph_legit_founder".tr());
      default:
        // Redirect to the 404 page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/404');
        });

        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildHeader(),

        // Token Information
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Center(
            child: TokenInformation(isDark: widget.isDark, data: {
              "Market Cap": "\$1,200,000,000",
              "Fully Diluted Valuation": "\$2,500,000,000",
              "Circulating Supply": "12,500,000",
              "Total Supply": "25,000,000",
              "Max Supply": "50,000,000",
              "Current Price": "\$120.00",
            }),
          ),
        ),

        // Order book
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Center(
            child: OrderBook(
              isDark: widget.isDark,
              initialBuyOrders: [
                TokenRowData(
                    tokenAmount: 100, pricePerToken: 1.5, totalPrice: 150.0),
                TokenRowData(
                    tokenAmount: 50, pricePerToken: 1.8, totalPrice: 90.0),
              ],
              initialSellOrders: [
                TokenRowData(
                    tokenAmount: 200, pricePerToken: 2.0, totalPrice: 400.0),
                TokenRowData(
                    tokenAmount: 75, pricePerToken: 1.9, totalPrice: 142.5),
              ],
            ),
          ),
        )
      ],
    );
  }
}

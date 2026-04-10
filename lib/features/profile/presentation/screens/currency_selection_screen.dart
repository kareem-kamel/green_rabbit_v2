import 'package:flutter/material.dart';

class CurrencyModel {
  final String code;
  final String name;
  final String flag;

  CurrencyModel({required this.code, required this.name, required this.flag});
}

class CurrencySelectionScreen extends StatefulWidget {
  final String currentCurrency;
  const CurrencySelectionScreen({super.key, required this.currentCurrency});

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  late String _selectedCurrency;
  String _searchQuery = '';

  final List<CurrencyModel> _currencies = [
    CurrencyModel(code: 'USD', name: 'US Dollar', flag: '🇺🇸'),
    CurrencyModel(code: 'EUR', name: 'Euro', flag: '🇪🇺'),
    CurrencyModel(code: 'GBP', name: 'British Pound', flag: '🇬🇧'),
    CurrencyModel(code: 'CHF', name: 'Swiss Franc', flag: '🇨🇭'),
    CurrencyModel(code: 'AED', name: 'UAE Dirham', flag: '🇦🇪'),
    CurrencyModel(code: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦'),
    CurrencyModel(code: 'EGP', name: 'Egyptian Pound', flag: '🇪🇬'),
    CurrencyModel(code: 'KWD', name: 'Kuwaiti Dinar', flag: '🇰🇼'),
    CurrencyModel(code: 'BHD', name: 'Bahraini Dinar', flag: '🇧🇭'),
    CurrencyModel(code: 'QAR', name: 'Qatari Riyal', flag: '🇶🇦'),
    CurrencyModel(code: 'OMR', name: 'Omani Rial', flag: '🇴🇲'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = _currencies.where((c) {
      return c.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Currency',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search here...',
                hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF11141B) : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4C3BC9)),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredCurrencies.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(height: 1, color: Theme.of(context).dividerColor),
                ),
                itemBuilder: (context, index) {
                  final currency = filteredCurrencies[index];
                  final isSelected = _selectedCurrency == currency.code;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 28,
                      alignment: Alignment.center,
                      child: Text(currency.flag, style: const TextStyle(fontSize: 24)),
                    ),
                    title: Text(
                      currency.code,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    trailing: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4C3BC9) : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
                          width: 2,
                        ),
                      ),
                      child: isSelected 
                          ? Center(
                              child: Icon(
                                Icons.check,
                                color: const Color(0xFF4C3BC9),
                                size: 14,
                              ),
                            )
                          : null,
                    ),
                    onTap: () {
                      setState(() => _selectedCurrency = currency.code);
                      Navigator.pop(context, currency.code);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

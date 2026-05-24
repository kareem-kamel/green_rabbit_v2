import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CalendarCountrySelectScreen extends StatefulWidget {
  final List<String> initialSelectedCountries;

  const CalendarCountrySelectScreen({super.key, required this.initialSelectedCountries});

  @override
  State<CalendarCountrySelectScreen> createState() => _CalendarCountrySelectScreenState();
}

class _CalendarCountrySelectScreenState extends State<CalendarCountrySelectScreen> {
  late List<String> _selectedCountries;
  String _searchQuery = '';

  final List<String> _allCountries = [
    'Albania', 'Angola', 'Egypt', 'United States', 'United Kingdom', 'Germany', 'France', 'Japan', 'China', 'India', 'Canada', 'Australia', 'Brazil', 'Mexico'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountries = List.from(widget.initialSelectedCountries);
  }

  @override
  Widget build(BuildContext context) {
    final filteredCountries = _allCountries
        .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search here...",
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF161922),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filteredCountries.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey[800], height: 1),
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                final isSelected = _selectedCountries.contains(country);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(country, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCountries.remove(country);
                      } else {
                        _selectedCountries.add(country);
                      }
                    });
                  },
                  trailing: Icon(
                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedCountries);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';

class CountrySelectionScreen extends StatefulWidget {
  final List<CountryModel> countries;
  final String currentCountryName;

  const CountrySelectionScreen({
    super.key,
    required this.countries,
    required this.currentCountryName,
  });

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  late String _selectedName;
  late String _selectedFlag;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.currentCountryName;
    
    final match = widget.countries.firstWhere(
      (c) => c.name == _selectedName,
      orElse: () => widget.countries.first,
    );
    _selectedFlag = match.flag;
    if (_selectedName == 'Select Country') {
      _selectedName = match.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Top strip handle from design
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose your country',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Country',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Selectable field container matching image
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF11141B) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CountryModel>(
                    value: widget.countries.firstWhere(
                      (c) => c.name == _selectedName,
                      orElse: () => widget.countries.first,
                    ),
                    isExpanded: true,
                    dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF11141B) : Colors.white,
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                        size: 20,
                      ),
                    ),
                    items: widget.countries.map((country) {
                      return DropdownMenuItem<CountryModel>(
                        value: country,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            children: [
                              Text(country.flag, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(
                                country.name,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (CountryModel? newVal) {
                      if (newVal != null) {
                        setState(() {
                          _selectedName = newVal.name;
                          _selectedFlag = newVal.flag;
                        });
                      }
                    },
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Save Changes / Action Button (Conditional Style)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: (_selectedName != widget.currentCountryName)
                        ? const LinearGradient(
                            colors: [Color(0xFF4C3BC9), Color(0xFF1B1E2B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: (_selectedName == widget.currentCountryName)
                        ? const Color(0xFF1F2937).withOpacity(0.8)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: (_selectedName != widget.currentCountryName)
                        ? () {
                            Navigator.pop(context, {
                              'name': _selectedName,
                              'code': widget.countries.firstWhere((c) => c.name == _selectedName).code,
                              'flag': _selectedFlag,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent, // Maintain container's color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: (_selectedName != widget.currentCountryName)
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

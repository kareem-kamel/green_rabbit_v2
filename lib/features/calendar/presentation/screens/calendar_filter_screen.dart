import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import 'calendar_country_select_screen.dart';

class CalendarFilterSettings {
  String countrySelection; // 'default', 'all', 'custom'
  List<String> selectedCountries;
  List<int> selectedImportance; // [1, 2, 3]

  CalendarFilterSettings({
    this.countrySelection = 'all',
    List<String>? selectedCountries,
    List<int>? selectedImportance,
  }) : selectedCountries = selectedCountries ?? [],
       selectedImportance = selectedImportance ?? [1, 2, 3];

  CalendarFilterSettings copyWith({
    String? countrySelection,
    List<String>? selectedCountries,
    List<int>? selectedImportance,
  }) {
    return CalendarFilterSettings(
      countrySelection: countrySelection ?? this.countrySelection,
      selectedCountries: selectedCountries ?? this.selectedCountries,
      selectedImportance: selectedImportance ?? this.selectedImportance,
    );
  }
}

class CalendarFilterScreen extends StatefulWidget {
  final CalendarFilterSettings initialSettings;
  final String category;

  const CalendarFilterScreen({super.key, required this.initialSettings, required this.category});

  @override
  State<CalendarFilterScreen> createState() => _CalendarFilterScreenState();
}

class _CalendarFilterScreenState extends State<CalendarFilterScreen> {
  late CalendarFilterSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Calendar Filter",
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () {
              setState(() {
                _settings = CalendarFilterSettings();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Counties",
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              "Default",
              _settings.countrySelection == 'default',
              () {
                setState(() => _settings.countrySelection = 'default');
              },
            ),
            _buildOptionCard("All", _settings.countrySelection == 'all', () {
              setState(() => _settings.countrySelection = 'all');
            }),
            _buildOptionCard(
              "Custom",
              _settings.countrySelection == 'custom',
              () async {
                setState(() => _settings.countrySelection = 'custom');
                final result = await Navigator.push<List<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarCountrySelectScreen(
                      initialSelectedCountries: _settings.selectedCountries,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _settings.selectedCountries = result);
                }
              },
              subtitle: _settings.countrySelection == 'custom'
                  ? (_settings.selectedCountries.isEmpty
                        ? "Select countries..."
                        : _settings.selectedCountries.join(', '))
                  : null,
            ),
            if (widget.category != 'ipo') ...[
              const SizedBox(height: 32),
              Text(
                "Set Importance",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              _buildImportanceCard("Low", 1),
              _buildImportanceCard("Medium", 2),
              _buildImportanceCard("High", 3),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _settings);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Apply Filter",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    String title,
    bool isSelected,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161922) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_outline : Icons.circle_outlined,
              color: isSelected 
                  ? (isDark ? Colors.white : AppColors.primary) 
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportanceCard(String title, int importance) {
    final isSelected = _settings.selectedImportance.contains(importance);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _settings.selectedImportance.remove(importance);
          } else {
            _settings.selectedImportance.add(importance);
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161922) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Row(
              children: List.generate(3, (index) {
                final isHighlighted = importance > index;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Image.asset(
                    isHighlighted
                        ? 'assets/green_rabbit.png'
                        : 'assets/rabbit_dark.png',
                    width: 14,
                    height: 14,
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: isSelected 
                  ? (isDark ? Colors.white : AppColors.primary) 
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

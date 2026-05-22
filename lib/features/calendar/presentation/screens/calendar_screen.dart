import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/calendar_cubit.dart';
import '../../data/models/calendar_event.dart';
import '../widgets/calendar_event_card.dart';
import 'calendar_filter_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _selectedCategory = 'earnings'; // Changed to earnings as economic is not supported
  String _selectedTab = 'this_week'; // Track selected tab
  final Set<String> _expandedDates = {}; // Track expanded sections
  CalendarFilterSettings _filterSettings = CalendarFilterSettings();

  List<String> get _tabs {
    if (_selectedCategory == 'ipo') {
      return ['recent', 'upcoming'];
    }
    return ['yesterday', 'today', 'tomorrow', 'this_week', 'next_week'];
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  static const Map<String, String> _countryIsoMap = {
    'Albania': 'AL',
    'Angola': 'AO',
    'Egypt': 'EG',
    'United States': 'US',
    'United Kingdom': 'GB',
    'Germany': 'DE',
    'France': 'FR',
    'Japan': 'JP',
    'China': 'CN',
    'India': 'IN',
    'Canada': 'CA',
    'Australia': 'AU',
    'Brazil': 'BR',
    'Mexico': 'MX',
  };

  void _fetchData() {
    String? countryParam;
    if (_filterSettings.countrySelection == 'custom' && _filterSettings.selectedCountries.isNotEmpty) {
      countryParam = _filterSettings.selectedCountries
          .map((c) => _countryIsoMap[c] ?? c)
          .join(',');
    } else if (_filterSettings.countrySelection == 'all') {
      countryParam = 'all';
    }

    // Ensure the current tab is valid for the category
    if (!_tabs.contains(_selectedTab)) {
      _selectedTab = _tabs.contains('this_week') ? 'this_week' : 'recent';
    }

    context.read<CalendarCubit>().fetchCalendar(
      category: _selectedCategory,
      tab: _selectedTab,
      country: countryParam,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 24),
          const Text(
            "No Events To Show",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try a different time frame or update your filter settings",
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                "${_selectedCategory[0].toUpperCase()}${_selectedCategory.substring(1)} Calendar",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
          ],
        ),
        actions: [
          _buildCircularIconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: _isFilterActive ? const Color(0xFFFFD700) : Colors.white,
              size: 20,
            ),
            onPressed: () async {
              final result = await Navigator.push<CalendarFilterSettings>(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarFilterScreen(initialSettings: _filterSettings),
                ),
              );
              if (result != null) {
                setState(() {
                  _filterSettings = result;
                  _expandedDates.clear();
                });
                _fetchData();
              }
            },
          ),
          _buildCircularIconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          _buildCircularIconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 20),
            onPressed: () => _showCategoryDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _tabs.map((tab) {
                    final isActive = _selectedTab == tab;
                    final activeColor = _selectedCategory == 'ipo' ? const Color(0xFF5E5CE6) : AppColors.secondaryBlue;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = tab;
                            _expandedDates.clear(); // Clear expansions on tab change
                          });
                          _fetchData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.transparent : const Color(0xFF161922),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive ? const Color(0xFF2D5CFF) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            tab[0].toUpperCase() + tab.substring(1).replaceAll('_', ' '),
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<CalendarCubit, CalendarState>(
                  builder: (context, state) {
                    if (state is CalendarLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is CalendarLoaded) {
                      final List<CalendarDay> displayDays = (state.days ?? [
                        CalendarDay(
                          date: state.date ?? '',
                          dayName: _getDayName(state.date),
                          eventCount: state.totalEvents,
                          events: state.events ?? [],
                        )
                      ]).map((day) {
                        // Filter events by importance locally
                        final filteredEvents = day.events.where((e) {
                          return _filterSettings.selectedImportance.contains(e.impact ?? 1);
                        }).toList();
                        return CalendarDay(
                          date: day.date,
                          dayName: day.dayName,
                          eventCount: filteredEvents.length,
                          events: filteredEvents,
                        );
                      }).toList();
                      
                      if (displayDays.every((d) => d.events.isEmpty)) {
                        return _buildEmptyState();
                      }

                      // Auto-expand first day with events if nothing expanded
                      if (_expandedDates.isEmpty && displayDays.any((d) => d.events.isNotEmpty)) {
                        _expandedDates.add(displayDays.firstWhere((d) => d.events.isNotEmpty).date);
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Header title (e.g., "This Week")
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Text(
                              state.tab.replaceAll('_', ' ').split(' ').map((s) => s[0].toUpperCase() + s.substring(1)).join(' '),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...displayDays.where((d) => d.events.isNotEmpty).map((day) => _buildDaySection(day)),
                          const SizedBox(height: 100), // Bottom padding
                        ],
                      );
                    } else if (state is CalendarError) {
                      // Hide error from user and show "No Events" instead
                      return _buildEmptyState();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isFilterActive {
    return _filterSettings.countrySelection != 'all' || _filterSettings.selectedImportance.length != 3;
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Select Calendar", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryItem("Earnings Calendar", 'earnings', Icons.monetization_on_outlined),
            _buildCategoryItem("Dividend Calendar", 'dividends', Icons.money_outlined),
            _buildCategoryItem("Splits Calendar", 'splits', Icons.call_split_outlined),
            _buildCategoryItem("IPO Calendar", 'ipo', Icons.calendar_today_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _expandedDates.clear();
        });
        _fetchData();
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE').format(date);
    } catch (e) {
      return '';
    }
  }

  Widget _buildCircularIconButton({required Widget icon, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF1C2128),
            shape: BoxShape.circle,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }

  Widget _buildDaySection(CalendarDay day) {
    final isExpanded = _expandedDates.contains(day.date);
    String formattedDate = '';
    try {
      final date = DateTime.parse(day.date);
      formattedDate = "${DateFormat('EEEE').format(date)}, ${DateFormat('MMMM d').format(date)}";
    } catch (e) {
      formattedDate = day.dayName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedDates.remove(day.date);
              } else {
                _expandedDates.add(day.date);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...day.events.map((e) => CalendarEventCard(event: e, category: _selectedCategory)),
        const SizedBox(height: 16),
      ],
    );
  }
}

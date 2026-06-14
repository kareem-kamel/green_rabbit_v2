import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../cubit/calendar_cubit.dart';
import '../../data/models/calendar_event.dart';
import '../widgets/calendar_event_card.dart';
import 'calendar_filter_screen.dart';
import '../widgets/calendar_skeleton_loader.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _selectedCategory = 'economic'; // Supported now
  String _selectedTab = 'this_week'; // Track selected tab
  final Set<String> _expandedDates = {}; // Track expanded sections
  CalendarFilterSettings _filterSettings = CalendarFilterSettings();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _lastLoadedStateKey;

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      context.read<CalendarCubit>().searchCalendar(
        category: _selectedCategory,
        query: query,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  static const Map<String, String> _categoryDisplayNames = {
    'economic': 'Economic Calendar',
    'earnings': 'Earnings Calendar',
    'dividends': 'Dividend Calendar',
    'splits': 'Splits Calendar',
    'ipo': 'IPO Calendar',
  };

  void _fetchData() {
    String? countryParam;
    if (_filterSettings.countrySelection == 'custom' && _filterSettings.selectedCountries.isNotEmpty) {
      if (_selectedCategory == 'economic' || _filterSettings.selectedCountries.length > 1) {
        // Fetch all events from backend since the backend country filter is buggy for economic category,
        // and doesn't support multiple comma-separated values for other categories. We filter locally.
        countryParam = 'all';
      } else {
        // Only one country selected, and not economic category -> use backend filtering
        countryParam = _countryIsoMap[_filterSettings.selectedCountries.first] ?? _filterSettings.selectedCountries.first;
      }
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

  bool _matchesCountryFilter(CalendarEvent e) {
    if (_filterSettings.countrySelection != 'custom' || _filterSettings.selectedCountries.isEmpty) {
      return true;
    }

    final eventCountryLower = e.country?.trim().toLowerCase() ?? '';
    final eventIsoLower = e.isoCountryCode?.trim().toLowerCase() ?? '';

    return _filterSettings.selectedCountries.any((selected) {
      final selectedLower = selected.trim().toLowerCase();
      final selectedIsoLower = _countryIsoMap[selected]?.trim().toLowerCase() ?? selectedLower;

      return eventCountryLower == selectedLower ||
             eventIsoLower == selectedIsoLower ||
             eventCountryLower == selectedIsoLower;
    });
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 24),
          Text(
            "No Events To Show",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Load Failed',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message.contains('Connection') || message.contains('SocketException')
                  ? 'Please check your internet connection and try again.'
                  : message,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5CFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161922) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.primary.withOpacity(0.5) : Colors.black26, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search event or symbol...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    final trimmed = val.trim();
                    if (trimmed.length >= 2) {
                      _triggerSearch();
                    } else if (trimmed.isEmpty) {
                      _fetchData();
                    }
                  },
                  onSubmitted: (value) {
                    _triggerSearch();
                  },
                ),
              )
            : InkWell(
                onTap: () => _showCategoryDialog(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        _categoryDisplayNames[_selectedCategory] ?? "Calendar",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: textPrimary, size: 24),
                  ],
                ),
              ),
        actions: [
          if (_isSearching)
            _buildCircularIconButton(
              icon: Icon(Icons.close, color: textPrimary, size: 20),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _expandedDates.clear();
                });
                _fetchData();
              },
              isDark: isDark,
            )
          else ...[
            _buildCircularIconButton(
              icon: Icon(
                Icons.filter_alt_outlined,
                color: _isFilterActive ? const Color(0xFFFFD700) : textPrimary,
                size: 20,
              ),
              onPressed: () async {
                final result = await Navigator.push<CalendarFilterSettings>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarFilterScreen(
                      initialSettings: _filterSettings,
                      category: _selectedCategory,
                    ),
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
              isDark: isDark,
            ),
            _buildCircularIconButton(
              icon: Icon(Icons.search, color: textPrimary, size: 20),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              isDark: isDark,
            ),
          ],
          _buildCircularIconButton(
            icon: Icon(Icons.menu, color: textPrimary, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              if (!_isSearching) ...[
                const SizedBox(height: 16),
                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _tabs.map((tab) {
                      final isActive = _selectedTab == tab;
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
                              color: isActive 
                                  ? Colors.transparent 
                                  : (isDark ? const Color(0xFF161922) : Colors.black.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive 
                                    ? const Color(0xFF2D5CFF) 
                                    : (isDark ? Colors.transparent : Colors.black12),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              tab.isEmpty ? '' : tab[0].toUpperCase() + tab.substring(1).replaceAll('_', ' '),
                              style: TextStyle(
                                color: isActive 
                                    ? textPrimary 
                                    : textSecondary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<CalendarCubit, CalendarState>(
                  builder: (context, state) {
                    if (state is CalendarLoading) {
                      return const CalendarSkeletonLoader();
                    } else if (state is CalendarLoaded) {
                      final List<CalendarDay> displayDays;
                      if (state.tab == 'search') {
                        final Map<String, List<CalendarEvent>> grouped = {};
                        for (final event in (state.events ?? <CalendarEvent>[])) {
                          final dateStr = event.reportDate ?? event.paymentDate ?? '';
                          grouped.putIfAbsent(dateStr, () => []).add(event);
                        }
                        displayDays = grouped.entries.map((entry) {
                          final dateStr = entry.key;
                          final dateEvents = entry.value;
                          final filteredEvents = dateEvents.where((e) {
                            return _filterSettings.selectedImportance.contains(e.importance ?? e.impact ?? 1) &&
                                   _matchesCountryFilter(e);
                          }).toList();
                          return CalendarDay(
                             date: dateStr,
                            dayName: _getDayName(dateStr),
                            eventCount: filteredEvents.length,
                            events: filteredEvents,
                          );
                        }).toList();
                        displayDays.sort((a, b) => a.date.compareTo(b.date));
                      } else {
                        displayDays = (state.days ?? [
                          CalendarDay(
                            date: state.date ?? '',
                            dayName: _getDayName(state.date),
                            eventCount: state.totalEvents,
                            events: state.events ?? [],
                          )
                        ]).map((day) {
                          // Filter events locally by importance and country
                          final filteredEvents = day.events.where((e) {
                            return _filterSettings.selectedImportance.contains(e.importance ?? e.impact ?? 1) &&
                                   _matchesCountryFilter(e);
                          }).toList();
                          return CalendarDay(
                            date: day.date,
                            dayName: day.dayName,
                            eventCount: filteredEvents.length,
                            events: filteredEvents,
                          );
                        }).toList();
                      }
                      
                      if (displayDays.every((d) => d.events.isEmpty)) {
                        return _buildEmptyState(isDark);
                      }
 
                      // Auto-expand first day with events on initial load of this dataset
                      final stateKey = "${state.category}|${state.tab}|${_searchController.text}";
                      if (_lastLoadedStateKey != stateKey) {
                        _lastLoadedStateKey = stateKey;
                        _expandedDates.clear();
                        if (displayDays.any((d) => d.events.isNotEmpty)) {
                          _expandedDates.add(displayDays.firstWhere((d) => d.events.isNotEmpty).date);
                        }
                      }
 
                      // Flatten the structure for ListView.builder to allow lazy loading and prevent slowness/lag
                      final List<_CalendarListItem> listItems = [];
                      
                      // 1. Title item
                      final titleText = _formatTabTitle(state.tab);
                      if (titleText.isNotEmpty) {
                        listItems.add(_CalendarListTitleItem(titleText));
                      }
                      
                      // 2. Day sections and events
                      for (final day in displayDays) {
                        if (day.events.isEmpty) continue;
                        
                        final isExpanded = _expandedDates.contains(day.date);
                        String formattedDate = '';
                        try {
                          final date = DateTime.parse(day.date);
                          formattedDate = "${DateFormat('EEEE').format(date)}, ${DateFormat('MMMM d').format(date)}";
                        } catch (e) {
                          formattedDate = day.dayName;
                        }
                        
                        listItems.add(_CalendarListHeaderItem(
                          day: day,
                          formattedDate: formattedDate,
                          isExpanded: isExpanded,
                        ));
                        
                        if (isExpanded) {
                          for (final event in day.events) {
                            listItems.add(_CalendarListEventItem(event));
                          }
                        }
                        
                        listItems.add(const _CalendarListSpacingItem());
                      }
                      
                      listItems.add(const _CalendarListBottomPaddingItem());
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: listItems.length,
                        itemBuilder: (context, index) {
                          final item = listItems[index];
                          if (item is _CalendarListTitleItem) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                item.title,
                                style: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            );
                          } else if (item is _CalendarListHeaderItem) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (item.isExpanded) {
                                    _expandedDates.remove(item.day.date);
                                  } else {
                                    _expandedDates.add(item.day.date);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.formattedDate,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      item.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (item is _CalendarListEventItem) {
                            return CalendarEventCard(
                              event: item.event,
                              category: _selectedCategory,
                            );
                          } else if (item is _CalendarListSpacingItem) {
                            return const SizedBox(height: 16);
                          } else if (item is _CalendarListBottomPaddingItem) {
                            return const SizedBox(height: 100);
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    } else if (state is CalendarError) {
                      return _buildErrorState(state.message, isDark);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161922) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Select Calendar", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryItem("Economic Calendar", 'economic', Icons.analytics_outlined, isDark),
            _buildCategoryItem("Earnings Calendar", 'earnings', Icons.monetization_on_outlined, isDark),
            _buildCategoryItem("Dividend Calendar", 'dividends', Icons.money_outlined, isDark),
            _buildCategoryItem("Splits Calendar", 'splits', Icons.call_split_outlined, isDark),
            _buildCategoryItem("IPO Calendar", 'ipo', Icons.calendar_today_outlined, isDark),
          ],
        ),
      ),
    );
  }
 
  Widget _buildCategoryItem(String title, String category, IconData icon, bool isDark) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _expandedDates.clear();
        });
        if (_isSearching && _searchController.text.trim().isNotEmpty) {
          _triggerSearch();
        } else {
          _fetchData();
        }
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16)),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? (isDark ? Colors.white : AppColors.primary) : Colors.grey,
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
 
  Widget _buildCircularIconButton({required Widget icon, required VoidCallback onPressed, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2128) : Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
 
  Widget _buildDaySection(CalendarDay day, bool isDark, Color textPrimary, Color textSecondary) {
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
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: textSecondary,
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

  String _formatTabTitle(String tab) {
    if (tab == 'search') {
      return 'Search Results for "${_searchController.text}"';
    }
    if (tab.isEmpty) return '';
    return tab
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }
}

abstract class _CalendarListItem {
  const _CalendarListItem();
}

class _CalendarListTitleItem extends _CalendarListItem {
  final String title;
  const _CalendarListTitleItem(this.title);
}

class _CalendarListHeaderItem extends _CalendarListItem {
  final CalendarDay day;
  final String formattedDate;
  final bool isExpanded;
  const _CalendarListHeaderItem({
    required this.day,
    required this.formattedDate,
    required this.isExpanded,
  });
}

class _CalendarListEventItem extends _CalendarListItem {
  final CalendarEvent event;
  const _CalendarListEventItem(this.event);
}

class _CalendarListSpacingItem extends _CalendarListItem {
  const _CalendarListSpacingItem();
}

class _CalendarListBottomPaddingItem extends _CalendarListItem {
  const _CalendarListBottomPaddingItem();
}

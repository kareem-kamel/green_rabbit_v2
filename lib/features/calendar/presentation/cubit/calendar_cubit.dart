import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/calendar_event.dart';
import '../../data/repositories/calendar_repository_impl.dart';

abstract class CalendarState {}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final String category;
  final String tab;
  final List<CalendarDay>? days; // For week tabs
  final List<CalendarEvent>? events; // For day tabs
  final String? startDate;
  final String? endDate;
  final String? date;
  final int totalEvents;

  CalendarLoaded({
    required this.category,
    required this.tab,
    this.days,
    this.events,
    this.startDate,
    this.endDate,
    this.date,
    required this.totalEvents,
  });
}

class CalendarError extends CalendarState {
  final String message;
  CalendarError(this.message);
}

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarRepository repository;

  CalendarCubit({required this.repository}) : super(CalendarInitial());

  Future<void> fetchCalendar({
    required String category,
    String? tab,
    bool? watchlist,
    String? symbol,
    String? country,
  }) async {
    emit(CalendarLoading());
    try {
      final response = await repository.getCalendarEvents(
        category: category,
        tab: tab,
        watchlist: watchlist,
        symbol: symbol,
        country: country,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final currentTab = data['tab'] ?? tab;

        // Debug prints: print up to three items for this calendar
        final List<dynamic> allRawEvents = [];
        if (data.containsKey('days')) {
          for (var day in data['days']) {
            if (day['events'] != null) {
              allRawEvents.addAll(day['events']);
            }
          }
        } else if (data.containsKey('events')) {
          allRawEvents.addAll(data['events'] ?? []);
        }

        print("---------------- CALENDAR DATA DEBUG PRINT ----------------");
        print("Category: $category | Tab: $currentTab | Total items: ${allRawEvents.length}");
        final itemsToPrint = allRawEvents.take(3).toList();
        for (int i = 0; i < itemsToPrint.length; i++) {
          print("Item ${i + 1}: ${itemsToPrint[i]}");
        }
        print("-----------------------------------------------------------");
        
        if (data.containsKey('days')) {
          // Week based
          final days = (data['days'] as List).map((e) => CalendarDay.fromJson(e)).toList();
          emit(CalendarLoaded(
            category: category,
            tab: currentTab,
            days: days,
            startDate: data['startDate'],
            endDate: data['endDate'],
            totalEvents: data['totalEvents'] ?? 0,
          ));
        } else {
          // Day based
          final events = (data['events'] as List).map((e) => CalendarEvent.fromJson(e)).toList();
          emit(CalendarLoaded(
            category: category,
            tab: currentTab,
            events: events,
            date: data['date'],
            totalEvents: data['totalEvents'] ?? 0,
          ));
        }
      } else {
        emit(CalendarError(response['error']?['message'] ?? 'Failed to load calendar'));
      }
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }

  Future<void> searchCalendar({
    required String category,
    required String query,
    int? page,
    int? limit,
  }) async {
    emit(CalendarLoading());
    try {
      final response = await repository.searchCalendarEvents(
        category: category,
        query: query,
        page: page,
        limit: limit,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final events = (data['events'] as List).map((e) => CalendarEvent.fromJson(e)).toList();

        emit(CalendarLoaded(
          category: category,
          tab: 'search',
          events: events,
          totalEvents: events.length,
        ));
      } else {
        emit(CalendarError(response['error']?['message'] ?? 'Failed to load search results'));
      }
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }
}

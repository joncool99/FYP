import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timetable_entry.dart';

class ViewTimetable extends StatefulWidget {
  @override
  _ViewTimetableState createState() => _ViewTimetableState();
}

class _ViewTimetableState extends State<ViewTimetable> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<TimetableEntry>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Timetable').get();
      Map<DateTime, List<TimetableEntry>> tempEvents = {};
      for (var doc in snapshot.docs) {
        print('Document data: ${doc.data()}'); // Debug: Print document data
        DateTime date = (doc['date'] as Timestamp).toDate();
        String location = doc['location'];
        print('Location: $location'); // Debug: Print location field

        TimetableEntry entry = TimetableEntry(
          courseName: doc['courseName'],
          startTime: doc['startTime'],
          endTime: doc['endTime'],
          location: doc['location'],
        );
        DateTime dateOnly =
            DateTime(date.year, date.month, date.day); // Remove time part
        if (!tempEvents.containsKey(dateOnly)) {
          tempEvents[dateOnly] = [];
        }
        tempEvents[dateOnly]!.add(entry);
      }
      setState(() {
        _events = tempEvents;
      });
      print('Loaded events: $_events'); // Debug: Print loaded events
    } catch (error) {
      print("Error loading events: $error"); // Debug: Print any errors
    }
  }

  List<TimetableEntry> _getEventsForDay(DateTime day) {
    DateTime dayOnly = DateTime(day.year, day.month, day.day);
    List<TimetableEntry> events = _events[dayOnly] ?? [];
    print(
        'Events for $dayOnly: $events'); // Debug: Print events for the selected day
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Timetable'),
      ),
      body: Column(
        children: [
          TableCalendar<TimetableEntry>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              print('Selected day: $_selectedDay'); // Debug: Print selected day
            },
            eventLoader: _getEventsForDay,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView(
              children:
                  _getEventsForDay(_selectedDay ?? _focusedDay).map((event) {
                print(
                    'Displaying event: ${event.courseName}'); // Debug: Print event details
                return ListTile(
                  title: Text(event.courseName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start: ${event.startTime}'),
                      Text('End: ${event.endTime}'),
                      Text(
                          'Location: ${event.location ?? 'No location provided'}'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}

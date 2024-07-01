import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class ViewTimetableScreen extends StatefulWidget {
  @override
  _ViewTimetableScreenState createState() => _ViewTimetableScreenState();
}

class _ViewTimetableScreenState extends State<ViewTimetableScreen> {
  late Map<DateTime, List<dynamic>> _events;
  List<dynamic> _selectedEvents = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _events = {};
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Timetable').get();
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime date;

        // Handling the date field
        if (data['date'] is Timestamp) {
          date = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is DateTime) {
          date = data['date'];
        } else if (data['date'] is String) {
          // Handle string format, assuming ISO 8601 date format in Firestore
          date = DateTime.parse(data['date']);
        } else {
          throw Exception('Invalid date format');
        }

        return {
          'courseName': data['courseName'],
          'courseId': data['courseId'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
          'location': data['location'],
          'date': date,
        };
      }).toList();

      setState(() {
        _events = {};
        for (var event in events) {
          final date = event['date'] as DateTime;
          final formattedDate = DateTime(date.year, date.month,
              date.day); // Ensure format matches TableCalendar's date keys
          if (_events[formattedDate] == null) _events[formattedDate] = [];
          _events[formattedDate]!.add(event);
        }

        // Update selected events based on _selectedDay
        _selectedEvents = _events[_selectedDay] ?? [];
      });
    } catch (e) {
      print('Error loading timetable: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Timetable'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2101),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) => _events[day] ?? [],
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _events[selectedDay] ?? [];
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return ListTile(
                  title: Text(event['courseName']),
                  subtitle: Text(
                      '${event['startTime']} - ${event['endTime']} @ ${event['location']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

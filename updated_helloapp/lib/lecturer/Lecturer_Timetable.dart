import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../timetable/timetable_entry.dart';

class LecturerTimetable extends StatefulWidget {
  @override
  _LecturerTimetableState createState() => _LecturerTimetableState();
}

class _LecturerTimetableState extends State<LecturerTimetable> {
  CalendarView _calendarView = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _lecturerEmail;

  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadLecturerEmail();
  }

  Future<void> _loadLecturerEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _lecturerEmail = user.email;
      });
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    if (_lecturerEmail == null) return;

    try {
      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .where('lecturers', arrayContains: _lecturerEmail)
          .get();

      List<Appointment> tempEvents = [];

      for (var courseDoc in coursesSnapshot.docs) {
        QuerySnapshot lessonsSnapshot =
            await courseDoc.reference.collection('Lessons').get();

        for (var lessonDoc in lessonsSnapshot.docs) {
          DateTime date = (lessonDoc['date'] as Timestamp).toDate();
          DateTime startTime = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(lessonDoc['startTime'].split(':')[0]),
            int.parse(lessonDoc['startTime'].split(':')[1]),
          );
          DateTime endTime = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(lessonDoc['endTime'].split(':')[0]),
            int.parse(lessonDoc['endTime'].split(':')[1]),
          );

          tempEvents.add(Appointment(
            startTime: startTime,
            endTime: endTime,
            subject: '${courseDoc['courseName']} - ${lessonDoc['lessonName']}',
            location: lessonDoc['location'],
            color: Colors.blue,
          ));
        }
      }

      setState(() {
        _appointments = tempEvents;
      });
    } catch (error) {
      print("Error loading events: $error");
    }
  }

  void _onViewChanged(CalendarView view) {
    setState(() {
      _calendarView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable',
            style: TextStyle(
              color: Colors.black,
            )),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.blue[800],
            height: 3.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SfCalendar(
              view: _calendarView,
              dataSource: MeetingDataSource(_appointments),
              initialSelectedDate: DateTime.now(),
              onViewChanged: (ViewChangedDetails details) {
                _focusedDay = details.visibleDates[0];
              },
              monthViewSettings: MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                showAgenda: true,
              ),
              timeSlotViewSettings: TimeSlotViewSettings(
                startHour: 7,
                endHour: 18,
                timeInterval: Duration(minutes: 60),
                timeFormat: 'h:mm a',
              ),
              onTap: (CalendarTapDetails details) {
                if (details.targetElement == CalendarElement.appointment) {
                  // Handle event tap here
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
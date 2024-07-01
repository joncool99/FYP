import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateTimetableScreen extends StatefulWidget {
  final String timetableId;

  const UpdateTimetableScreen({Key? key, required this.timetableId})
      : super(key: key);

  @override
  _UpdateTimetableScreenState createState() => _UpdateTimetableScreenState();
}

class _UpdateTimetableScreenState extends State<UpdateTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  String courseName = '';
  String courseId = '';
  DateTime date = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String location = '';

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Timetable')
          .doc(widget.timetableId)
          .collection('Events')
          .doc(widget.timetableId)
          .get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          courseName = data['courseName'];
          courseId = data['courseId'];
          date = (data['date'] as Timestamp).toDate();
          startTime = TimeOfDay(
            hour: int.parse(data['startTime'].split(':')[0]),
            minute: int.parse(data['startTime'].split(':')[1]),
          );
          endTime = TimeOfDay(
            hour: int.parse(data['endTime'].split(':')[0]),
            minute: int.parse(data['endTime'].split(':')[1]),
          );
          location = data['location'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timetable not found')),
        );
      }
    } catch (e) {
      print('Error loading timetable: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load timetable')),
      );
    }
  }

  Future<void> _updateTimetable() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance
            .collection('Timetable')
            .doc(widget.timetableId)
            .collection('Events')
            .doc(widget.timetableId)
            .update({
          'courseName': courseName,
          'courseId': courseId,
          'date': Timestamp.fromDate(date),
          'startTime': '${startTime.hour}:${startTime.minute}',
          'endTime': '${endTime.hour}:${endTime.minute}',
          'location': location,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timetable updated')),
        );
      } catch (e) {
        print('Error updating timetable: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update timetable')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Timetable'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: courseName,
                decoration: InputDecoration(labelText: 'Course Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter course name';
                  }
                  return null;
                },
                onSaved: (value) {
                  courseName = value!;
                },
              ),
              TextFormField(
                initialValue: courseId,
                decoration: InputDecoration(labelText: 'Course ID'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter course ID';
                  }
                  return null;
                },
                onSaved: (value) {
                  courseId = value!;
                },
              ),
              TextFormField(
                initialValue: location,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
                onSaved: (value) {
                  location = value!;
                },
              ),
              SizedBox(height: 20),
              Text('Date: ${date.toLocal()}'.split(' ')[0]),
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != date)
                    setState(() {
                      date = pickedDate;
                    });
                },
                child: Text('Select Date'),
              ),
              Text('Start Time: ${startTime.format(context)}'),
              ElevatedButton(
                onPressed: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (pickedTime != null && pickedTime != startTime)
                    setState(() {
                      startTime = pickedTime;
                    });
                },
                child: Text('Select Start Time'),
              ),
              Text('End Time: ${endTime.format(context)}'),
              ElevatedButton(
                onPressed: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (pickedTime != null && pickedTime != endTime)
                    setState(() {
                      endTime = pickedTime;
                    });
                },
                child: Text('Select End Time'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateTimetable,
                child: Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

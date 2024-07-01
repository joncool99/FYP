import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  String courseName = '';
  String courseId = '';
  DateTime date = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String location = '';

  Future<void> _submitTimetable() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await FirebaseFirestore.instance
          .collection('Timetable')
          .doc(courseName)
          .set({
        'courseName': courseName,
        'courseId': courseId,
        'date': Timestamp.fromDate(date),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'endTime': '${endTime.hour}:${endTime.minute}',
        'location': location,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Course'),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Course Name'),
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
                decoration: const InputDecoration(labelText: 'Course ID'),
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
              Row(
                children: [
                  const Text('Date:'),
                  const SizedBox(width: 10),
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
                    child: Text(
                      '${date.day}-${date.month}-${date.year}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Start Time:'),
                  const SizedBox(width: 10),
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
                    child: Text('${startTime.format(context)}'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('End Time:'),
                  const SizedBox(width: 10),
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
                    child: Text('${endTime.format(context)}'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitTimetable,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

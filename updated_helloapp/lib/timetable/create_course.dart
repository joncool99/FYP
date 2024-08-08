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
  String lecturerEmail = '';
  List<Lesson> lessons = [];
  List<String> studentEmails = [];
  final _emailController = TextEditingController();

  Future<void> _submitTimetable() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create a course document with lessons as sub-collection
      await FirebaseFirestore.instance.collection('Courses').doc(courseId).set({
        'courseName': courseName,
        'courseId': courseId,
        'lecturers': [lecturerEmail],
        'students': studentEmails,
      });

      for (var lesson in lessons) {
        await FirebaseFirestore.instance
            .collection('Courses')
            .doc(courseId)
            .collection('Lessons')
            .doc(lesson.lessonName)
            .set({
          'lessonName': lesson.lessonName,
          'date': Timestamp.fromDate(lesson.date),
          'startTime': '${lesson.startTime.hour}:${lesson.startTime.minute}',
          'endTime': '${lesson.endTime.hour}:${lesson.endTime.minute}',
          'location': lesson.location,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course and lessons added')),
      );
      _formKey.currentState!.reset();
      setState(() {
        lessons = [];
        studentEmails = [];
      });
    }
  }

  void _addLesson() {
    setState(() {
      lessons.add(Lesson());
    });
  }

  void _addStudentEmail() {
    if (_emailController.text.isNotEmpty) {
      setState(() {
        studentEmails.add(_emailController.text);
        _emailController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Course'),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: SingleChildScrollView(
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
                decoration: const InputDecoration(labelText: 'Lecturer Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter lecturer email';
                  }
                  return null;
                },
                onSaved: (value) {
                  lecturerEmail = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addLesson,
                child: const Text('Add Lesson'),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  return LessonWidget(
                    lesson: lessons[index],
                    onDelete: () {
                      setState(() {
                        lessons.removeAt(index);
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Student Email',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addStudentEmail,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _addStudentEmail,
                child: const Text('Add Student'),
              ),
              const SizedBox(height: 20),
              Text('Added Students:'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: studentEmails.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(studentEmails[index]),
                  );
                },
              ),
              ElevatedButton(
                onPressed: _submitTimetable,
                child: const Text('Submit Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Lesson {
  String lessonName = '';
  DateTime date = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String location = '';

  Lesson({
    this.lessonName = '',
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    this.location = '',
  })  : this.date = date ?? DateTime.now(),
        this.startTime = startTime ?? TimeOfDay.now(),
        this.endTime = endTime ?? TimeOfDay.now();
}

class LessonWidget extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onDelete;

  LessonWidget({required this.lesson, required this.onDelete});

  @override
  _LessonWidgetState createState() => _LessonWidgetState();
}

class _LessonWidgetState extends State<LessonWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Lesson Name',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter lesson name';
                  }
                  return null;
                },
                onChanged: (value) {
                  widget.lesson.lessonName = value;
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Date:'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: widget.lesson.date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != widget.lesson.date)
                      setState(() {
                        widget.lesson.date = pickedDate;
                      });
                  },
                  child: Text(
                    '${widget.lesson.date.day}-${widget.lesson.date.month}-${widget.lesson.date.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Start Time:'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: widget.lesson.startTime,
                    );
                    if (pickedTime != null &&
                        pickedTime != widget.lesson.startTime)
                      setState(() {
                        widget.lesson.startTime = pickedTime;
                      });
                  },
                  child: Text('${widget.lesson.startTime.format(context)}'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('End Time:'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: widget.lesson.endTime,
                    );
                    if (pickedTime != null &&
                        pickedTime != widget.lesson.endTime)
                      setState(() {
                        widget.lesson.endTime = pickedTime;
                      });
                  },
                  child: Text('${widget.lesson.endTime.format(context)}'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
              onChanged: (value) {
                widget.lesson.location = value;
              },
            ),
            const SizedBox(height: 2),
            ElevatedButton(
              onPressed: widget.onDelete,
              child: const Text('Delete Lesson'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

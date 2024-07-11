import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCourseTimetable extends StatefulWidget {
  final String courseId;

  EditCourseTimetable({required this.courseId});

  @override
  _EditCourseTimetableState createState() => _EditCourseTimetableState();
}

class _EditCourseTimetableState extends State<EditCourseTimetable> {
  final _formKey = GlobalKey<FormState>();
  String courseName = '';
  List<Lesson> lessons = [];
  List<String> studentEmails = [];
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    DocumentSnapshot courseDoc = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .get();

    setState(() {
      courseName = courseDoc['courseName'];
      studentEmails = List<String>.from(courseDoc['students']);

      _fetchLessons();
    });
  }

  Future<void> _fetchLessons() async {
    QuerySnapshot lessonsSnapshot = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection('Lessons')
        .get();

    setState(() {
      lessons =
          lessonsSnapshot.docs.map((doc) => Lesson.fromFirestore(doc)).toList();
    });
  }

  Future<void> _submitTimetable() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Update course document
      await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .update({
        'courseName': courseName,
        'students': studentEmails,
      });

      // Update lessons
      for (var lesson in lessons) {
        await FirebaseFirestore.instance
            .collection('Courses')
            .doc(widget.courseId)
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
        SnackBar(content: Text('Course and lessons updated')),
      );
    }
  }

  Future<void> _deleteCourse() async {
    await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Course deleted successfully')),
    );
    Navigator.pop(context);
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

  void _removeStudentEmail(String email) {
    setState(() {
      studentEmails.remove(email);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Course'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmationDialog(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: courseName,
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addLesson,
                child: const Text('Add Lesson'),
              ),
              Expanded(
                child: ListView.builder(
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
              const SizedBox(height: 10),
              Text('Added Students:'),
              Expanded(
                child: ListView.builder(
                  itemCount: studentEmails.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(studentEmails[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle),
                        onPressed: () {
                          _removeStudentEmail(studentEmails[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _submitTimetable,
                child: const Text('Update Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this course?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteCourse(); // Proceed with deletion
              },
            ),
          ],
        );
      },
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

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lesson(
      lessonName: data['lessonName'],
      date: (data['date'] as Timestamp).toDate(),
      startTime: _parseTime(data['startTime']),
      endTime: _parseTime(data['endTime']),
      location: data['location'],
    );
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
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
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: widget.lesson.lessonName,
              decoration: const InputDecoration(labelText: 'Lesson Name'),
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
              initialValue: widget.lesson.location,
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

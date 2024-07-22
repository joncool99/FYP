import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RecordDetailsPage.dart';

class SelectLessonPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const SelectLessonPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<SelectLessonPage> createState() => _SelectLessonPageState();
}

class _SelectLessonPageState extends State<SelectLessonPage> {
  List<Map<String, String>> lessons = [];
  String? selectedLessonId;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      QuerySnapshot lessonsSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .collection('Lessons')
          .get();

      List<Map<String, String>> fetchedLessons = lessonsSnapshot.docs.map((doc) {
        return {
          'lessonId': doc.id,
          'lessonName': doc.id, // Assuming the lesson name is stored as the document ID
        };
      }).toList();

      setState(() {
        lessons = fetchedLessons;
      });
    } catch (e) {
      print('Failed to load lessons: $e');
    }
  }

  void _navigateToRecordDetail(BuildContext context, String courseId, String courseName, String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordsDetail(courseId: courseId, courseName: courseName, lessonId: lessonId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Select Lesson for ${widget.courseName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(9.0),
          child: Container(
            color: const Color.fromRGBO(22, 22, 151, 100),
            height: 5.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(50, 70, 50, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Lessons',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  String lessonId = lessons[index]['lessonId']!;
                  return ListTile(
                    title: Text(lessonId,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    leading: Radio<String>(
                      value: lessonId,
                      groupValue: selectedLessonId,
                      onChanged: (String? value) {
                        setState(() {
                          selectedLessonId = value!;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    onPressed: () {
                      if (selectedLessonId != null) {
                        _navigateToRecordDetail(
                            context, widget.courseId, widget.courseName, selectedLessonId!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(22, 22, 151, 100)),
                    child: const Text('Enter',
                        style: TextStyle(fontSize: 20, color: Colors.white))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

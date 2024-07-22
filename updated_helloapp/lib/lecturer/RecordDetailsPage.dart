import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordsDetail extends StatefulWidget {
  final String courseId;
  final String courseName;
  final String lessonId;

  const RecordsDetail({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.lessonId,
  });

  @override
  State<RecordsDetail> createState() => _RecordsDetailState();
}

class _RecordsDetailState extends State<RecordsDetail> {
  List<AttendanceDetail> details = [];
  double attendancePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .collection('Lessons')
          .doc(widget.lessonId)
          .collection('Attendance')
          .get();

      List<AttendanceDetail> fetchedDetails = [];
      int presentCount = 0;

      for (var doc in querySnapshot.docs) {
        bool isPresent = doc['status'] == 'present';
        if (isPresent) presentCount++;
        fetchedDetails.add(
          AttendanceDetail(
            index: fetchedDetails.length + 1,
            name: doc.id,
            attendance: isPresent,
          ),
        );
      }

      double percentage = 0.0;
      if (fetchedDetails.isNotEmpty) {
        percentage = (presentCount / fetchedDetails.length) * 100;
      }

      setState(() {
        details = fetchedDetails;
        attendancePercentage = percentage;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: const Text('Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(9.0),
                child: Container(
                  color: const Color.fromRGBO(22, 22, 151, 100),
                  height: 5.0,
                ))),
        body: Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 0),
            child: Column(children: <Widget>[
              const Text('Attendance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 20),
              Text(
                'Overall Attendance: ${attendancePercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 500,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                      children: details.map((detail) {
                    return SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: Card(
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: detail.attendance
                                      ? Colors.greenAccent
                                      : Colors.redAccent),
                              child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(children: <Widget>[
                                    Text(detail.index.toString()),
                                    const SizedBox(width: 30),
                                    SizedBox(
                                        width: 200, child: Text(detail.name)),
                                    const Expanded(child: SizedBox()),
                                    Text(detail.attendance ? 'P' : 'Abs'),
                                  ])))),
                    );
                  }).toList()),
                ),
              )
            ])));
  }
}

class AttendanceDetail {
  final int index;
  final String name;
  final bool attendance;

  AttendanceDetail(
      {required this.index, required this.name, required this.attendance});
}
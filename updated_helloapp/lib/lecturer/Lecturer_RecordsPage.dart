import 'package:flutter/material.dart';
import 'RecordGraphPage.dart';

class Lecturer_RecordsPage extends StatefulWidget {
  const Lecturer_RecordsPage({super.key});

  @override
  State<Lecturer_RecordsPage> createState() => _Lecturer_RecordsPageState();
}

class _Lecturer_RecordsPageState extends State<Lecturer_RecordsPage> {
  List<AttendanceDetail> details = [];

  @override
  void initState() {
    super.initState();

    details = [
      AttendanceDetail(index: 1, name: 'Afham', attendance: true),
      AttendanceDetail(index: 2, name: 'Athira Ramesh', attendance: true),
      AttendanceDetail(index: 3, name: 'Athira Sunil', attendance: true),
      AttendanceDetail(index: 4, name: 'Aswin', attendance: false),
      AttendanceDetail(index: 5, name: 'Alibaba', attendance: true),
      AttendanceDetail(index: 6, name: 'Zach Strawberry', attendance: true),
    ];
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
              Row(children: <Widget>[
                const Text('Attendance',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const Expanded(child: SizedBox()),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RecordGraphPage()),
                );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(22, 22, 151, 100),
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0)),
                    child: const Text('View Graph',
                        style: TextStyle(fontSize: 18, color: Colors.white))),
              ]),
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

  AttendanceDetail({required this.index, required this.name, required this.attendance});
}
import 'package:flutter/material.dart';
import '../lecturer.dart';
import 'Lecturer_AttendancePage.dart';

class Lecturer_HomePage extends StatefulWidget {
  const Lecturer_HomePage({super.key});

  @override
  State<Lecturer_HomePage> createState() => _Lecturer_HomePageState();
}

class _Lecturer_HomePageState extends State<Lecturer_HomePage> {
  var name = 'John';
  List<ClassDetail> classDetails = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            centerTitle: false,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
              child: Image.asset('assets/homeIcon.png'),
            ),
            title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Hi, $name',
                      style: const TextStyle(
                          color: Color.fromRGBO(22, 22, 151, 100),
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const Text('Welcome!',
                      style: TextStyle(
                          color: Color.fromRGBO(22, 22, 151, 100),
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ]),
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(9.0),
                child: Container(
                  color: const Color.fromRGBO(22, 22, 151, 100),
                  height: 5.0,
                ))),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          child: Column(children: <Widget>[
            const Text("Today's Agenda",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20.0),
            Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: classDetails.map((classDetail) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Lecturer_AttendancePage(classDetail: classDetail),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Card(
                          elevation: 5,
                          shadowColor: Colors.black,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              gradient: const LinearGradient(
                                  stops: [0.6, 1],
                                  colors: [Colors.white, Colors.blueAccent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  tileMode: TileMode.clamp),
                            ),
                            child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Text(
                                        "${classDetail.name}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    Text(classDetail.type),
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule),
                                        const SizedBox(width: 10.0),
                                        Text(classDetail.time),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined),
                                        const SizedBox(width: 10.0),
                                        Text(classDetail.location),
                                      ],
                                    )
                                  ],
                                )),
                          )),
                    ),
                  );
                }).toList()),
          ]),
        ));
  }

  @override
  void initState() {
    super.initState();
    classDetails = [
      ClassDetail(
          name: 'CSIT321',
          type: 'Project',
          time: '03:30 PM - 06:30 PM',
          location: 'Room 101')
    ];
  }
}

class ClassDetail {
  final String name;
  final String type;
  final String time;
  final String location;

  ClassDetail(
      {required this.name,
      required this.type,
      required this.time,
      required this.location});
}
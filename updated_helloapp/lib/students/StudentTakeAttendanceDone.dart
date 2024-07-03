import 'package:flutter/material.dart';


class TakeAttendanceDonePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Take Attendance', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.blue[900],
            height: 3.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(60, 40.0, 30.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('CSIT 321 - L01',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Project', style: TextStyle(fontSize: 18)),
                  Row(
                    children: <Widget>[
                      Icon(Icons.access_time, size: 18),
                      SizedBox(width: 5),
                      Text('03:30 PM - 06:30PM'),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Icon(Icons.place, size: 18),
                      SizedBox(width: 5),
                      Text('Room 101'),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(60.0, 20, 16.0, 20.0),
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('Present', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              alignment: Alignment.center,
              child: Image.asset('images/face_icon.png', width: 300),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'updateinfo.dart';

class AccountsPage extends StatefulWidget {
  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchUserAccounts() async {
    QuerySnapshot snapshot = await _firestore.collection('Users').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Accounts'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No user accounts found.'));
          }

          List<Map<String, dynamic>> userAccounts = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('First Name')),
                DataColumn(label: Text('Last Name')),
                DataColumn(label: Text('Student ID')),
                DataColumn(label: Text('Major')),
                DataColumn(label: Text('Update')),
              ],
              rows: userAccounts.map((user) {
                return DataRow(
                  cells: [
                    DataCell(Text(user['email'])),
                    DataCell(Text(user['firstName'])),
                    DataCell(Text(user['lastName'])),
                    DataCell(Text(user['studentId'])),
                    DataCell(Text(user['major'])),
                    DataCell(
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdatePage(user: user),
                            ),
                          );
                        },
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}





  

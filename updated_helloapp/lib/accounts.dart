import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register.dart';

class AccountsPage extends StatefulWidget {
  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUserAccounts = [];
  List<Map<String, dynamic>> _filteredUserAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAccounts();
  }

  Future<void> _fetchUserAccounts() async {
    QuerySnapshot snapshot = await _firestore.collection('Users').get();
    setState(() {
      _allUserAccounts = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      _filteredUserAccounts = _allUserAccounts;
    });
  }

  void _filterAccounts(String query) {
    setState(() {
      _filteredUserAccounts = _allUserAccounts.where((user) {
        final emailLower = user['email'].toLowerCase();
        final queryLower = query.toLowerCase();
        return emailLower.contains(queryLower);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Accounts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      _filterAccounts(query);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    backgroundColor: const Color.fromARGB(255, 65, 188, 46),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredUserAccounts.isEmpty
                  ? const Center(child: Text('No user accounts found.'))
                  : SingleChildScrollView(
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
                        rows: _filteredUserAccounts.map((user) {
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
                                    Navigator.pushNamed(
                                      context,
                                      '/update',
                                      arguments: user,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(10),
                                    backgroundColor:
                                        const Color.fromARGB(255, 255, 110, 20),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Update'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

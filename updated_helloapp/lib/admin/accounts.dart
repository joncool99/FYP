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

  Future<void> _deleteAccount(String email) async {
    try {
      await _firestore.collection('Users').doc(email).delete();
      setState(() {
        _filteredUserAccounts.removeWhere((user) => user['email'] == email);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User account deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user account: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(String email) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this account?'),
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
                _deleteAccount(email); // Proceed with deletion
              },
            ),
          ],
        );
      },
    );
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
                          DataColumn(
                              label: Text(
                                  'Delete')), // New column for delete button
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
                                        Color.fromARGB(255, 61, 141, 94),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Update'),
                                ),
                              ),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                        user['email']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(10),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
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

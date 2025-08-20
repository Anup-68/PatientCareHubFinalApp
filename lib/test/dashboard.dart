import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  final CollectionReference employees =
      FirebaseFirestore.instance.collection('employees');

  void _addEmployee() async {
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();

    if (name.isEmpty || position.isEmpty) return;

    await employees.add({
      'name': name,
      'position': position,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    _positionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Form
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Employee Name'),
            ),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addEmployee,
              child: const Text('Add Employee'),
            ),
            const Divider(height: 30),
            const Text('Employee List', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            // Employee List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: employees
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Text('Error loading employees');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data()! as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['name'] ?? ''),
                          subtitle: Text(data['position'] ?? ''),
                          tileColor: const Color.fromARGB(255, 110, 186, 248),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

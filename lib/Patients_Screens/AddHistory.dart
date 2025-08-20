import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddMedicalHistoryScreen extends StatefulWidget {
  const AddMedicalHistoryScreen({super.key});

  @override
  _AddMedicalHistoryScreenState createState() =>
      _AddMedicalHistoryScreenState();
}

class _AddMedicalHistoryScreenState extends State<AddMedicalHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController diagnosedDiseaseController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  Future<void> _saveMedicalHistory() async {
    if (_formKey.currentState!.validate()) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('medicalRecords').add({
        'patientId': userId,
        'dateOfCreation': FieldValue.serverTimestamp(),
        'diagnosedDisease': diagnosedDiseaseController.text.trim(),
        'description': descriptionController.text.trim(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medical history added successfully")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Medical History")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: diagnosedDiseaseController,
                decoration: InputDecoration(
                    labelText: "Diagnosed Disease",
                    border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "Please enter diagnosed disease" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: "Description (Optional)",
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMedicalHistory,
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

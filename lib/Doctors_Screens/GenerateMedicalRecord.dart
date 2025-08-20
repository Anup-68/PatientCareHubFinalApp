import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GenerateMedicalHistoryByDoc extends StatefulWidget {
  final String patientId;

  const GenerateMedicalHistoryByDoc({super.key, required this.patientId});

  @override
  _GenerateMedicalHistoryByDocState createState() =>
      _GenerateMedicalHistoryByDocState();
}

class _GenerateMedicalHistoryByDocState
    extends State<GenerateMedicalHistoryByDoc> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitHistory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current doctor's id (ensure the logged in user is a doctor)
      String doctorId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('medicalRecords').add({
        'patientId': widget.patientId,
        'doctorId': doctorId,
        'diagnosedDisease': _diseaseController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dateOfCreation': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medical history generated successfully.")));
      Navigator.pop(context);
    } catch (e) {
      print("Error generating medical history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate medical history.")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _diseaseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Generate Medical History"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _diseaseController,
                      decoration: InputDecoration(
                        labelText: "Diagnosed Disease",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter the diagnosed disease";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a description";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitHistory,
                      child: Text("Generate Medical History"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

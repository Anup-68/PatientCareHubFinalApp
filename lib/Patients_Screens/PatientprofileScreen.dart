import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PatientProfileScreen extends StatefulWidget {
  final String userId;

  const PatientProfileScreen({super.key, required this.userId});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  DateTime? birthDate;
  String? gender;
  String? profileUrl;
  String? bloodGroup;
  String? bloodPressure;
  String? sugar;
  TextEditingController pastMedicalConditionController =
      TextEditingController();
  List<String> surgicalHistory = [];
  TextEditingController surgicalHistoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      setState(() {
        nameController.text = doc['fullName'] ?? '';
        birthDate =
            doc['birthDate'] != null ? DateTime.parse(doc['birthDate']) : null;
        gender = doc['gender'];
        profileUrl = doc['profileUrl'];
        bloodGroup = doc['bloodGroup'];
        bloodPressure = doc['bloodPressure'];
        sugar = doc['sugar'];
        pastMedicalConditionController.text = doc['pastMedicalCondition'] ?? '';
        surgicalHistory = List<String>.from(doc['surgicalHistory'] ?? []);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      await _uploadImage(file);
    }
  }

  Future<void> _uploadImage(File file) async {
    try {
      String fileName = "profile/${widget.userId}_${Uuid().v4()}.jpg";
      await supabase.storage.from('patient-uploads').upload(fileName, file);
      final publicUrl =
          supabase.storage.from('patient-uploads').getPublicUrl(fileName);
      setState(() => profileUrl = publicUrl);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  void _addSurgicalHistory() {
    if (surgicalHistoryController.text.isNotEmpty) {
      setState(() {
        surgicalHistory.add(surgicalHistoryController.text.trim());
        surgicalHistoryController.clear();
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.userId)
          .set({
        'fullName': nameController.text.trim(),
        'birthDate': birthDate != null
            ? DateFormat('yyyy-MM-dd').format(birthDate!)
            : null,
        'age': birthDate != null ? _calculateAge(birthDate!) : null,
        'gender': gender,
        'profileUrl': profileUrl,
        'bloodGroup': bloodGroup,
        'bloodPressure': bloodPressure,
        'sugar': sugar,
        'pastMedicalCondition': pastMedicalConditionController.text.trim(),
        'surgicalHistory': surgicalHistory,
        'patientId': uid,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Patient Profile")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage:
                        profileUrl != null ? NetworkImage(profileUrl!) : null,
                    child: profileUrl == null
                        ? Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Full Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: "Full Name", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "Please enter full name" : null,
              ),
              SizedBox(height: 20),
              // Birth Date
              GestureDetector(
                onTap: () => _selectBirthDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: "Birth Date", border: OutlineInputBorder()),
                  child: Text(birthDate != null
                      ? DateFormat('yyyy-MM-dd').format(birthDate!)
                      : "Select birth date"),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                      labelText: "Gender", border: OutlineInputBorder()),
                  items: ["Male", "Female"]
                      .map((String value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (newValue) => setState(() => gender = newValue)),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                  value: bloodGroup,
                  decoration: InputDecoration(
                      labelText: "Blood Group", border: OutlineInputBorder()),
                  items: ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
                      .map((String value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (newValue) =>
                      setState(() => bloodGroup = newValue)),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: bloodPressure,
                decoration: InputDecoration(
                    labelText: "Blood Pressure", border: OutlineInputBorder()),
                items: ["High", "Low", "No"].map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => bloodPressure = newValue),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: sugar,
                decoration: InputDecoration(
                    labelText: "Sugar", border: OutlineInputBorder()),
                items: ["Yes", "No"].map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => sugar = newValue),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: pastMedicalConditionController,
                decoration: InputDecoration(
                    labelText: "Past Medical Condition",
                    border: OutlineInputBorder()),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: surgicalHistoryController,
                decoration: InputDecoration(
                  labelText: "Surgical History",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addSurgicalHistory,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("Add Surgery"),
              ),
              SizedBox(height: 10),
              Wrap(
                children: surgicalHistory
                    .map((surgery) => Chip(label: Text(surgery)))
                    .toList(),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 52, 3, 246)),
                  child: Text(
                    "Update Profile",
                    style: TextStyle(color: Color.fromARGB(222, 244, 244, 247)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

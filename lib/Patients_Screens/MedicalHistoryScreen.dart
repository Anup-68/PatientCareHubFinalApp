import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Patients_Screens/AddHistory.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  _MedicalHistoryScreenState createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medical History")),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('medicalRecords')
            .where('patientId', isEqualTo: userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No record found"));
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              // Cast document data to a map.
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              // Convert Firestore Timestamp (or String) to DateTime and format the date.
              var rawDate = data['dateOfCreation'];
              DateTime date;
              if (rawDate is Timestamp) {
                date = rawDate.toDate();
              } else if (rawDate is String) {
                try {
                  date = DateTime.parse(rawDate);
                } catch (e) {
                  date = DateTime.now();
                }
              } else {
                date = DateTime.now();
              }
              String formattedDate = "${date.day}/${date.month}/${date.year}";

              // Check if doctorId exists in the document using the casted data.
              bool hasDoctor = data.containsKey('doctorId') &&
                  data['doctorId'] != null &&
                  (data['doctorId'] as String).isNotEmpty;

              return Card(
                color: Colors.lightBlueAccent,
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🗓 Date: $formattedDate",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("🩺 Diagnosed Disease: ${data['diagnosedDisease']}",
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      if (data['description'] != null &&
                          data['description'].isNotEmpty)
                        Text("📄 Description: ${data['description']}"),
                      SizedBox(height: 8),
                      hasDoctor
                          ? FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(data['doctorId'])
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text("Created by: Doctor",
                                      style: TextStyle(fontSize: 14));
                                }
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  var doctorData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  String doctorName =
                                      doctorData['name'] ?? "Doctor";
                                  return Text("Created by: Dr $doctorName",
                                      style: TextStyle(fontSize: 14));
                                } else {
                                  return Text("Created by: Doctor",
                                      style: TextStyle(fontSize: 14));
                                }
                              },
                            )
                          : Text("Created by: Patient",
                              style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddMedicalHistoryScreen()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Button color
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text("Add Medical History",
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}

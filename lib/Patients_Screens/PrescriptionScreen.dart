import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientPrescriptionsScreen extends StatefulWidget {
  const PatientPrescriptionsScreen({super.key});

  @override
  _PatientPrescriptionsScreenState createState() =>
      _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState
    extends State<PatientPrescriptionsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown Date";
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    String? patientId = _auth.currentUser?.uid;

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Prescriptions")),
        body: Center(child: Text("Error: Patient ID not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Your Prescriptions")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('prescriptions')
            .where('patientId', isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No prescriptions available."));
          }

          return ListView(
            padding: EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;

              String clinicName =
                  (data['clinicName'] ?? "Unknown Clinic").toString();
              String doctorName = (data['doctorName'] ?? "Unknown").toString();
              String clinicAddress =
                  (data['clinicAddress'] ?? "Not Available").toString();
              String date = formatDate(data['createdAt']);
              List<dynamic> medicines = data['medicines'] ?? [];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🏥 $clinicName",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("👨‍⚕️ Dr. $doctorName",
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 5),
                      Text("📍 $clinicAddress",
                          style: TextStyle(color: Colors.grey), softWrap: true),
                      SizedBox(height: 5),
                      Text("📅 Date: $date",
                          style: TextStyle(color: Colors.grey)),
                      Divider(),
                      Text("🩺 Prescribed Medicines",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (medicines.isNotEmpty)
                        Column(
                          children: medicines.map((medicine) {
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (
                                        medicine['medicineName'],
                                        medicine['days'] + " days" ??
                                            "Unknown Medicine"
                                      ).toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16),
                                      softWrap: true,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween, // ✅ Added to prevent overflow
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                  value: medicine['morning'] ??
                                                      false,
                                                  onChanged: null),
                                              Flexible(child: Text("Morning")),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                  value:
                                                      medicine['afternoon'] ??
                                                          false,
                                                  onChanged: null),
                                              Flexible(
                                                  child: Text("Afternoon")),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                  value: medicine['night'] ??
                                                      false,
                                                  onChanged: null),
                                              Flexible(child: Text("Night")),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text("No medicines prescribed.",
                            style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

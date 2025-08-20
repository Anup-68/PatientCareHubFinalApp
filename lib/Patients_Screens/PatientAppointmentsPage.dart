import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    print("🔹 Current User ID: $currentUserId"); // Debugging

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print(
                "⚠️ No appointments found for user: $currentUserId"); // Debugging
            return Center(child: Text("No Appointments Found"));
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var appointmentData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              print("📄 Firestore Patient ID: ${appointmentData['patientId']}");

              if (appointmentData['patientId'] != currentUserId) {
                print(
                    "⚠️ Mismatch: Firestore ID (${appointmentData['patientId']}) vs Current User ($currentUserId)");
                return SizedBox(); // Skip if mismatched
              }

              String doctorId = appointmentData['doctorId'] ?? "";
              String status = appointmentData['status'] ?? "Pending";
              String symptoms = appointmentData['symptoms'] ?? "Not Specified";
              String reason = appointmentData['purpose'] ?? "Not Specified";
              String date = appointmentData['date'] ?? "Unknown Date";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(doctorId)
                    .get(),
                builder: (context, doctorSnapshot) {
                  String doctorFullName = "Unknown Doctor";

                  if (doctorSnapshot.hasData && doctorSnapshot.data!.exists) {
                    var doctorData =
                        doctorSnapshot.data!.data() as Map<String, dynamic>? ??
                            {};
                    String firstName = doctorData['firstName'] ?? "";
                    String lastName = doctorData['lastName'] ?? "";
                    doctorFullName = "$firstName $lastName".trim();
                  }

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Doctor: Dr $doctorFullName",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text("Date: $date", style: TextStyle(fontSize: 14)),
                          Text("Symptoms: $symptoms",
                              style: TextStyle(fontSize: 14)),
                          Text("Reason: $reason",
                              style: TextStyle(fontSize: 14)),
                          SizedBox(height: 5),
                          Text("Status: $status",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: status == "Completed"
                                      ? Colors.green
                                      : Colors.orange)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

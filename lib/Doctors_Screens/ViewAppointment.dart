import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patientcarehub/Doctors_Screens/GenerateMedicalRecord.dart';
import 'package:patientcarehub/Doctors_Screens/GeneratePrescription.dart';
import 'package:patientcarehub/Doctors_Screens/ViewReportOfPatient.dart';

class ViewAppointmentScreen extends StatelessWidget {
  final String appointmentId;
  final String patientId;

  const ViewAppointmentScreen(
      {super.key, required this.appointmentId, required this.patientId});

  int _calculateAge(String birthDate) {
    if (birthDate.isEmpty) return 0;
    DateTime dob = DateFormat('yyyy-MM-dd').parse(birthDate);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _completeAppointment(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': 'Completed',
    });
    // Navigate back to the Doctor Appointments Screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Appointment Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .get(),
        builder: (context, patientSnapshot) {
          if (patientSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!patientSnapshot.hasData || !patientSnapshot.data!.exists) {
            return Center(child: Text("Patient data not found."));
          }

          var patientData =
              patientSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          String fullName = patientData['fullName'] ?? "Unknown";
          String birthDate = patientData['birthDate'] ?? "";
          String age = birthDate.isNotEmpty
              ? _calculateAge(birthDate).toString()
              : "N/A";
          String bloodGroup = patientData['bloodGroup'] ?? "Not Available";
          String bloodPressure =
              patientData['bloodPressure'] ?? "Not Available";
          String sugarLevel = patientData['sugarLevel'] ?? "Not Available";

          List<dynamic>? pastMedicalHistoryList =
              patientData['pastMedicalHistory'] as List<dynamic>?;
          List<dynamic>? surgicalHistoryList =
              patientData['surgicalHistory'] as List<dynamic>?;

          String pastMedicalHistory = pastMedicalHistoryList != null &&
                  pastMedicalHistoryList.isNotEmpty
              ? pastMedicalHistoryList.join(', ')
              : "None";

          String surgicalHistory =
              surgicalHistoryList != null && surgicalHistoryList.isNotEmpty
                  ? surgicalHistoryList.join(', ')
                  : "None";
          String doctorId = FirebaseAuth.instance.currentUser!.uid;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('appointments')
                .doc(appointmentId)
                .get(),
            builder: (context, appointmentSnapshot) {
              if (appointmentSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!appointmentSnapshot.hasData ||
                  !appointmentSnapshot.data!.exists) {
                return Center(child: Text("Appointment data not found."));
              }

              var appointmentData =
                  appointmentSnapshot.data!.data() as Map<String, dynamic>? ??
                      {};
              String symptoms = appointmentData['symptoms'] ?? "Not Specified";
              String reason = appointmentData['reason'] ?? "Not Specified";

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Provide a minimum height based on the screen size minus AppBar height
                    minHeight:
                        MediaQuery.of(context).size.height - kToolbarHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(title: Text("Patient Name: $fullName")),
                        ListTile(title: Text("Age: $age")),
                        ListTile(title: Text("Blood Group: $bloodGroup")),
                        ListTile(title: Text("Blood Pressure: $bloodPressure")),
                        ListTile(title: Text("Sugar Level: $sugarLevel")),
                        ListTile(title: Text("Symptoms: $symptoms")),
                        ListTile(title: Text("Reason for Visit: $reason")),
                        ListTile(
                            title: Text(
                                "Past Medical Conditions: $pastMedicalHistory")),
                        ListTile(
                            title: Text("Surgical History: $surgicalHistory")),
                        Divider(),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Medical History Records",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('medicalRecords')
                              .where('patientId', isEqualTo: patientId)
                              .snapshots(),
                          builder: (context, historySnapshot) {
                            if (historySnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!historySnapshot.hasData ||
                                historySnapshot.data!.docs.isEmpty) {
                              return Center(
                                  child: Text("No Medical History Found"));
                            }

                            return ListView(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              children: historySnapshot.data!.docs.map((doc) {
                                var history =
                                    doc.data() as Map<String, dynamic>;
                                // Format the date from Timestamp
                                String formattedDate = "N/A";
                                if (history['dateOfCreation'] != null) {
                                  try {
                                    Timestamp ts =
                                        history['dateOfCreation'] as Timestamp;
                                    DateTime date = ts.toDate();
                                    formattedDate =
                                        DateFormat('dd/MM/yyyy').format(date);
                                  } catch (e) {
                                    formattedDate = "N/A";
                                  }
                                }
                                return ListTile(
                                  title: Text(
                                      "Disease: ${history['diagnosedDisease']}"),
                                  subtitle: Text(
                                      "Description: ${history['description'] ?? 'N/A'}"),
                                  trailing: Text("Date: $formattedDate"),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        // Buttons for additional actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 234, 250, 90),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GeneratePrescriptionScreen(
                                      patientId: patientId,
                                      doctorId: doctorId,
                                      appointmentId: appointmentId,
                                    ),
                                  ),
                                );
                              },
                              child: Text("Generate Prescription"),
                            ),
                            SizedBox(height: 15),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 243, 159, 25),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GenerateMedicalHistoryByDoc(
                                            patientId: patientId),
                                  ),
                                );
                              },
                              child: Text("Generate Medical Record"),
                            ),
                            SizedBox(height: 15),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 106, 148, 246),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DoctorReportScreen(
                                            patientId: patientId,
                                          )),
                                );
                              },
                              child: Text("View Reports"),
                            ),
                            SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () => _completeAppointment(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: Text("Complete Appointment",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

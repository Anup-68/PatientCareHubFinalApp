import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patientcarehub/Doctors_Screens/ViewAppointment.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  _DoctorAppointmentsScreenState createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String? doctorId;
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchDoctorId();
  }

  Future<void> _fetchDoctorId() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doctorSnapshot =
        await FirebaseFirestore.instance.collection('doctors').doc(uid).get();

    if (doctorSnapshot.exists) {
      setState(() {
        doctorId = doctorSnapshot['doctorId'];
      });
    }
  }

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

  Future<void> _updateAppointmentStatus(
      String appointmentId, String status) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: doctorId == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: doctorId)
                  .where('date', isEqualTo: todayDate)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No Appointments for Today"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String appointmentId = doc.id;
                    String patientId = data['patientId'] ?? '';
                    String symptoms = data['symptoms'] ?? 'Not Specified';
                    String reason = data['purpose'] ?? 'Not Specified';
                    String status = data['status'] ?? 'Pending';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('patients')
                          .doc(patientId)
                          .get(),
                      builder: (context, patientSnapshot) {
                        if (patientSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!patientSnapshot.hasData ||
                            !patientSnapshot.data!.exists) {
                          return _buildAppointmentCard(
                            patientName: "Unknown Patient",
                            age: "N/A",
                            gender: "N/A",
                            symptoms: symptoms,
                            reason: reason,
                            status: status,
                            onView: () => _navigateToAppointmentView(
                                appointmentId, patientId),
                            onDecline: () => _updateAppointmentStatus(
                                appointmentId, "Declined"),
                          );
                        }

                        var patientData = patientSnapshot.data!.data()
                                as Map<String, dynamic>? ??
                            {};
                        String patientName =
                            patientData['fullName'] ?? "Unknown Patient";
                        String birthDate = patientData['birthDate'] ?? "";
                        String gender = patientData['gender'] ?? "N/A";

                        return _buildAppointmentCard(
                          patientName: patientName,
                          age: birthDate.isNotEmpty
                              ? _calculateAge(birthDate).toString()
                              : "N/A",
                          gender: gender,
                          symptoms: symptoms,
                          reason: reason,
                          status: status,
                          onView: () => _navigateToAppointmentView(
                              appointmentId, patientId),
                          onDecline: () => _updateAppointmentStatus(
                              appointmentId, "Declined"),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _navigateToAppointmentView(String appointmentId, String patientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAppointmentScreen(
          appointmentId: appointmentId,
          patientId: patientId,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String patientName,
    required String age,
    required String gender,
    required String symptoms,
    required String reason,
    required String status,
    required VoidCallback onView,
    required VoidCallback onDecline,
  }) {
    return Card(
      color:
          status == "Declined" ? Colors.red.shade100 : Colors.yellow.shade100,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient: $patientName",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("Age: $age", style: TextStyle(fontSize: 14)),
            Text("Gender: $gender", style: TextStyle(fontSize: 14)),
            Text("Symptoms: $symptoms", style: TextStyle(fontSize: 14)),
            Text("Reason: $reason", style: TextStyle(fontSize: 14)),
            Text("Status: $status",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("View Appointment",
                      style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: onDecline,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Decline", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

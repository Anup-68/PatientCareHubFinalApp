import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Patients_Screens/ViewProfile.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No doctors available'));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              var docData = doctors[index].data() as Map<String, dynamic>;
              String doctorId = doctors[index].id; // Fetch document ID
              String doctorName = docData['firstName'] != null
                  ? "Dr. ${docData['firstName']} ${docData['lastName']}"
                  : "Unknown";
              String specialization =
                  docData['specialization'] ?? 'Not Specified';
              int experience = docData['experience'] ?? 0;
              String clinicName = docData['clinicName'] ?? 'No Clinic Info';
              String profileImage =
                  docData['profileImage'] ?? ''; // Fetch profile image URL

              return DoctorCard(
                doctorId: doctorId,
                name: doctorName,
                specialization: specialization,
                experience: experience,
                clinicName: clinicName,
                profileImage: profileImage,
              );
            },
          );
        },
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String doctorId;
  final String name;
  final String specialization;
  final int experience;
  final String clinicName;
  final String profileImage;

  const DoctorCard({
    super.key,
    required this.doctorId,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.clinicName,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.lightBlue[100], // Light blue background
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Doctor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Specialization: $specialization"),
                  Text("Experience: $experience years"),
                  Text("Clinic: $clinicName"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900], // Dark blue button
                    ),
                    onPressed: () {
                      if (doctorId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewProfileScreen(doctorId: doctorId),
                          ),
                        );
                      } else {
                        print("Error: doctorId is empty!");
                      }
                    },
                    child: Text(
                      'View Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Doctor Profile Image
            profileImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      profileImage,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.account_circle, size: 80, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

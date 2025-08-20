import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Admin_pages/ViewDoctordetailspage.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  _DoctorListPageState createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Doctor List"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              var doctorData = doctors[index].data() as Map<String, dynamic>;

              // Safe field access
              String fullName =
                  "${doctorData['firstName'] ?? 'Unknown'} ${doctorData['lastName'] ?? ''}";
              String specialization =
                  doctorData['specialization'] ?? "Not specified";
              String experience = doctorData['experience']?.toString() ?? "0";
              String profileImage = doctorData.containsKey('profileImage') &&
                      doctorData['profileImage'] != null
                  ? doctorData['profileImage']
                  : "assets/doctor.png"; // Default image

              return Card(
                color: Colors.blue,
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profileImage.startsWith("http")
                        ? NetworkImage(profileImage) // Load from URL
                        : AssetImage(profileImage)
                            as ImageProvider, // Load from assets
                  ),
                  title: Text(
                    fullName,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "$specialization\nExperience: $experience years",
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DoctorDetailPage(doctor: doctors[index]),
                        ),
                      );
                    },
                    child: Text("View Profile"),
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

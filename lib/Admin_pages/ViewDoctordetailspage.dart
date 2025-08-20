import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot doctor;

  const DoctorDetailPage({super.key, required this.doctor});

  void toggleDoctorStatus(String doctorId, String status) {
    FirebaseFirestore.instance.collection('doctors').doc(doctorId).update({
      'status': status == 'active' ? 'disable' : 'active',
    });
  }

  void deleteDoctor(String doctorId) async {
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Doctor Details")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(doctor['profileImage']),
              ),
            ),
            SizedBox(height: 10),
            Text("Name: Dr. ${doctor['firstName']} ${doctor['lastName']}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Specialization: ${doctor['specialization']}",
                style: TextStyle(fontSize: 18)),
            Text("Experience: ${doctor['experience']} years",
                style: TextStyle(fontSize: 18)),
            Text("License No: ${doctor['licenseNo']}",
                style: TextStyle(fontSize: 18)),
            Text("Status: ${doctor['status']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("Clinic Details:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Clinic Name: ${doctor['clinicName']} (${doctor['clinicId']})",
                style: TextStyle(fontSize: 18)),
            Text(
                "Address: ${doctor['street']}, ${doctor['city']}, ${doctor['state']} - ${doctor['zipCode']}",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text("Clinic Images:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (doctor['clinic_images'] as List).length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Image.network(
                      doctor['clinic_images'][index],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text("Doctor's Certificate:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Center(
              child: Image.network(
                doctor['certificate_url'],
                width: 250,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      toggleDoctorStatus(doctor.id, doctor['status']),
                  child: Text(
                      doctor['status'] == 'active' ? "Disable" : "Activate"),
                ),
                ElevatedButton(
                  onPressed: () => deleteDoctor(doctor.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:patientcarehub/Patients_Screens/BookAppointmentPage.dart';
import 'package:patientcarehub/Patients_Screens/chatScreen.dart';
import 'package:patientcarehub/Patients_Screens/giveReview.dart';

class ViewProfileScreen extends StatelessWidget {
  final String doctorId;

  const ViewProfileScreen({super.key, required this.doctorId});

  String? getCurrentPatientId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid; // Returns the current logged-in user ID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Doctor not found'));
          }

          var doctorData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor's Profile Image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: doctorData['profileImage'] != null
                        ? Image.network(
                            doctorData['profileImage'],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/docprofile.jpg',
                            width: 150,
                            height: 150,
                          ),
                  ),
                ),
                SizedBox(height: 20),

                // Doctor's Details
                Text("Dr. ${doctorData['firstName']} ${doctorData['lastName']}",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Specialization: ${doctorData['specialization']}"),
                Text("Experience: ${doctorData['experience']} years"),
                Text("Clinic Name: ${doctorData['clinicName']}"),
                Text("License No: ${doctorData['licenseNo']}"),
                Text(
                    "Clinic Morning Time : ${doctorData['morningStart']} To ${doctorData['morningEnd']} "),
                Text(
                    "Clinic Evening Time : ${doctorData['eveningStart']} To ${doctorData['eveningEnd']} "),
                Text(
                    "Address: ${doctorData['street']}, ${doctorData['city']}, ${doctorData['state']}"),
                Text("Zip Code: ${doctorData['zipCode']}"),
                SizedBox(height: 20),

                // Buttons for Book Appointment & Message
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookAppointmentScreen(
                              doctorId: doctorId,
                              patientId: FirebaseAuth.instance.currentUser!.uid,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                      child: Text("Book Appointment",
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GiveReviewPage(
                              doctorId: doctorId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                      child: Text("Give Review",
                          style: TextStyle(color: Colors.white)),
                    ),
                    IconButton(
                      icon: Icon(Icons.message, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              doctorId: doctorId,
                              patientId: FirebaseAuth.instance.currentUser!.uid,
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),

                SizedBox(height: 20),

                // Clinic Images
                Text("Clinic Images:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                doctorData['clinic_images'] != null &&
                        doctorData['clinic_images'] is List
                    ? SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              (doctorData['clinic_images'] as List).length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  doctorData['clinic_images'][index],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Text("No clinic images available"),

                SizedBox(height: 30),
                // Display Reviews
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('doctorId', isEqualTo: doctorId)
                      .where('hidden', isEqualTo: false)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No reviews available.'));
                    }
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(data['review'] ?? 'No review'),
                            subtitle: RatingBarIndicator(
                              rating: (data['rating'] as num).toDouble(),
                              itemCount: 5,
                              itemSize: 20,
                              direction: Axis.horizontal,
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

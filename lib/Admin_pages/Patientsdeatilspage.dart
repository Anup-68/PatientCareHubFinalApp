import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  _PatientListPageState createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  // Fetch patient's appointment statistics (Booked & Completed count)
  Future<Map<String, int>> _getPatientAppointmentStats(String patientId) async {
    try {
      QuerySnapshot bookedAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();

      QuerySnapshot completedAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'Completed')
          .get();

      return {
        'booked': bookedAppointments.docs.length,
        'completed': completedAppointments.docs.length,
      };
    } catch (e) {
      print("Error fetching appointments: $e");
      return {'booked': 0, 'completed': 0}; // Default values in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient List"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No patients found."));
          }

          var patients = snapshot.data!.docs;

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              var patientData = patients[index].data() as Map<String, dynamic>;
              String patientId = patients[index].id;

              // Safe field access
              String fullName = patientData['fullName'] ?? 'Unknown';

              String profileImage = patientData.containsKey('profileImage') &&
                      patientData['profileImage'] != null
                  ? patientData['profileImage']
                  : "assets/patients.png"; // Default image if not available

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
                  subtitle: FutureBuilder<Map<String, int>>(
                    future: _getPatientAppointmentStats(patientId),
                    builder: (context, appointmentSnapshot) {
                      if (appointmentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Text(
                          "Fetching appointment data...",
                          style: TextStyle(color: Colors.white70),
                        );
                      }
                      if (appointmentSnapshot.hasError) {
                        return Text(
                          "Error loading appointments",
                          style: TextStyle(color: Colors.white70),
                        );
                      }
                      return Text(
                        " v5Booked: ${appointmentSnapshot.data!['booked']} | Completed: ${appointmentSnapshot.data!['completed']}",
                        style: TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('patients')
                            .doc(patientId)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Patient removed successfully")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error removing patient: $e")),
                        );
                      }
                    },
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

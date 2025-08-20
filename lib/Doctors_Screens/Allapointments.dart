import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllAppointments extends StatefulWidget {
  const AllAppointments({super.key});

  @override
  _AllAppointmentsState createState() => _AllAppointmentsState();
}

class _AllAppointmentsState extends State<AllAppointments> {
  String? doctorId;
  String? selectedFilter = "This Year";
  String? patientNameQuery;
  DateTime? selectedDate;

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

  Stream<QuerySnapshot> _getFilteredAppointments() {
    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId);

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    DateTime startOfYear = DateTime(now.year, 1, 1);

    if (selectedFilter == "Today") {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay));
    } else if (selectedFilter == "This Week") {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek));
    } else if (selectedFilter == "This Year") {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear));
    } else if (selectedFilter == "Specific Date" && selectedDate != null) {
      DateTime start =
          DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime end = start.add(Duration(days: 1));
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          isLessThan: Timestamp.fromDate(end));
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Appointments")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ["Today", "This Week", "This Year", "Specific Date"]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedFilter = newValue;
                      if (newValue != "Specific Date") selectedDate = null;
                    });
                  },
                ),
                if (selectedFilter == "Specific Date")
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Search by Patient Name",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        patientNameQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: doctorId == null
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _getFilteredAppointments(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No Appointments Found"));
                      }
                      var appointments = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          var data = appointments[index].data()
                              as Map<String, dynamic>;
                          String patientId = data['patientId'] ?? "";

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('patients')
                                .doc(patientId)
                                .get(),
                            builder: (context, patientSnapshot) {
                              if (!patientSnapshot.hasData ||
                                  !patientSnapshot.data!.exists) {
                                return SizedBox.shrink();
                              }

                              var patientData = patientSnapshot.data!.data()
                                      as Map<String, dynamic>? ??
                                  {};
                              String patientName =
                                  patientData['fullName'] ?? "Unknown Patient";
                              String birthDate = patientData['birthDate'] ?? "";
                              String age = birthDate.isNotEmpty
                                  ? _calculateAge(birthDate).toString()
                                  : "N/A";

                              if (patientNameQuery != null &&
                                  !patientName
                                      .toLowerCase()
                                      .contains(patientNameQuery!)) {
                                return SizedBox.shrink();
                              }

                              return Card(
                                color: data['status'] == "Declined"
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: ListTile(
                                  title: Text("Patient: $patientName"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Age: $age"),
                                      Text(
                                          "Symptoms: ${data['symptoms'] ?? 'N/A'}"),
                                      Text(
                                          "Status: ${data['status'] ?? 'Pending'}"),
                                      Text(
                                          "Booking Time: ${DateFormat('dd-MM-yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())}"),
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
          ),
        ],
      ),
    );
  }
}

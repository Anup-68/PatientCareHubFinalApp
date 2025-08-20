import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GeneratePrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String doctorId;

  const GeneratePrescriptionScreen(
      {super.key,
      required this.patientId,
      required this.doctorId,
      required String appointmentId});

  @override
  _GeneratePrescriptionScreenState createState() =>
      _GeneratePrescriptionScreenState();
}

class _GeneratePrescriptionScreenState
    extends State<GeneratePrescriptionScreen> {
  String clinicName = "ABC Health Clinic";
  String clinicAddress = "123 Main Street, City";
  String doctorName = "Unknown Doctor";
  List<Map<String, dynamic>> medicines = [];

  @override
  void initState() {
    super.initState();
    fetchDoctorDetails();
  }

  // Fetch Doctor Details from Firestore
  void fetchDoctorDetails() async {
    var docSnapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .get();

    if (docSnapshot.exists) {
      var doctorData = docSnapshot.data() ?? {};
      clinicName = doctorData['clinicName'] ?? "ABC ";
      String firstName = doctorData['firstName'] ?? "";
      String lastName = doctorData['lastName'] ?? "";
      String street = doctorData['street'] ?? "";
      String city = doctorData['city'] ?? "";
      String state = doctorData['state'] ?? "";
      String zipCode = doctorData['zipCode'] ?? "";

      setState(() {
        doctorName = "$firstName $lastName".trim();
        clinicAddress = "$street $city $state $zipCode".trim();
      });
    }
  }

  // Add new medicine field
  void addMedicineField() {
    setState(() {
      medicines.add({
        'medicineName': '',
        'days': '',
        'morning': false,
        'afternoon': false,
        'night': false,
      });
    });
  }

  // Validate the medicine entries
  bool validateMedicines() {
    for (var medicine in medicines) {
      if (medicine['medicineName'].trim().isEmpty) {
        showErrorMessage("Medicine name cannot be empty.");
        return false;
      }
      if (medicine['days'].trim().isEmpty ||
          int.tryParse(medicine['days'].trim()) == null) {
        showErrorMessage("Please enter a valid number of days.");
        return false;
      }
      if (!(medicine['morning'] ||
          medicine['afternoon'] ||
          medicine['night'])) {
        showErrorMessage(
            "At least one time (Morning, Afternoon, Night) must be selected.");
        return false;
      }
    }
    return true;
  }

  // Show error message
  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Save prescription to Firestore
  Future<void> savePrescription() async {
    if (medicines.isEmpty) {
      showErrorMessage("Please add at least one medicine.");
      return;
    }

    if (!validateMedicines()) return;

    await FirebaseFirestore.instance.collection('prescriptions').add({
      'doctorId': widget.doctorId,
      'patientId': widget.patientId,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'doctorName': doctorName,
      'medicines': medicines,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Prescription Saved Successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generate Prescription")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Clinic: $clinicName ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Address: $clinicAddress", style: TextStyle(fontSize: 16)),
            Text("Doctor: $doctorName",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("Medicines:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          TextField(
                            decoration:
                                InputDecoration(labelText: "Medicine Name"),
                            onChanged: (value) {
                              medicines[index]['medicineName'] = value;
                            },
                          ),
                          TextField(
                            decoration:
                                InputDecoration(labelText: "Number of Days"),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              medicines[index]['days'] = value;
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Checkbox(
                                    value: medicines[index]['morning'],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        medicines[index]['morning'] =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                  Text("Morning"),
                                ],
                              ),
                              Column(
                                children: [
                                  Checkbox(
                                    value: medicines[index]['afternoon'],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        medicines[index]['afternoon'] =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                  Text("Afternoon"),
                                ],
                              ),
                              Column(
                                children: [
                                  Checkbox(
                                    value: medicines[index]['night'],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        medicines[index]['night'] =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                  Text("Night"),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: addMedicineField,
              child: Text("Add Medicine"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: savePrescription,
              child: Text("Save Prescription"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;

  const BookAppointmentScreen(
      {super.key, required this.doctorId, required this.patientId});

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TextEditingController symptomsController = TextEditingController();
  TextEditingController purposeController = TextEditingController();

  bool _isProfileComplete = false; // Track if profile exists
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _checkPatientProfile(); // Check profile existence on page load
  }

  /// ✅ Check if patient profile exists in Firestore before booking
  Future<void> _checkPatientProfile() async {
    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      setState(() {
        _isProfileComplete = patientDoc.exists;
      });
    } catch (e) {
      setState(() {
        _isProfileComplete = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📅 Select Appointment Date
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// ⏰ Select Appointment Time
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  /// 📌 Book Appointment
  Future<void> _bookAppointment() async {
    if (!_isProfileComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Please update your profile before booking an appointment."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() &&
        selectedDate != null &&
        selectedTime != null) {
      try {
        // Convert selected date and time to match Firestore format
        String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
        String formattedTime = selectedTime!.format(context);

        // ✅ Check if an appointment already exists for the same doctor, date, and time
        QuerySnapshot existingAppointments = await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: widget.doctorId)
            .where('date', isEqualTo: formattedDate)
            .where('time', isEqualTo: formattedTime)
            .get();

        if (existingAppointments.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "This time slot is already booked. Please choose a different time."),
              backgroundColor: Colors.orange,
            ),
          );
          return; // Stop booking process
        }

        // Proceed with booking if no conflicts found
        DocumentReference appointmentRef =
            FirebaseFirestore.instance.collection('appointments').doc();

        await appointmentRef.set({
          'appointmentId': appointmentRef.id,
          'doctorId': widget.doctorId,
          'patientId': widget.patientId,
          'date': formattedDate,
          'time': formattedTime,
          'appointmentNumber': appointmentRef.id.substring(0, 6),
          'symptoms': symptomsController.text.trim().isNotEmpty
              ? symptomsController.text.trim()
              : null,
          'purpose': purposeController.text.trim().isNotEmpty
              ? purposeController.text.trim()
              : null,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appointment booked successfully!")),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to book appointment: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book Appointment")),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loader while checking profile
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Date:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate != null
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(selectedDate!)
                                  : "Choose a date",
                              style: TextStyle(fontSize: 16),
                            ),
                            Icon(Icons.calendar_today, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Select Time:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedTime != null
                                  ? selectedTime!.format(context)
                                  : "Choose a time",
                              style: TextStyle(fontSize: 16),
                            ),
                            Icon(Icons.access_time, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: symptomsController,
                      decoration: InputDecoration(
                        labelText: "Symptoms",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: purposeController,
                      decoration: InputDecoration(
                        labelText: "Purpose for Visit",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _bookAppointment,
                        child: Text("Book Appointment"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicDetailsScreen extends StatefulWidget {
  const ClinicDetailsScreen({super.key});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  TextEditingController clinicNameController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController zipCodeController = TextEditingController();
  TextEditingController morningStartController = TextEditingController();
  TextEditingController morningEndController = TextEditingController();
  TextEditingController eveningStartController = TextEditingController();
  TextEditingController eveningEndController = TextEditingController();
  TextEditingController morningAppointmentsController = TextEditingController();
  TextEditingController eveningAppointmentsController = TextEditingController();

  bool isLoading = true;
  String clinicId = "";
  List<String> clinicImageUrls = [];

  @override
  void initState() {
    super.initState();
    fetchClinicDetails();
  }

  Future<void> fetchClinicDetails() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      DocumentSnapshot doctorDoc =
          await _firestore.collection('doctors').doc(userId).get();

      if (doctorDoc.exists && doctorDoc.data() != null) {
        var doctorData = doctorDoc.data() as Map<String, dynamic>;

        setState(() {
          clinicId = doctorData['clinicId'] ?? "";
          clinicNameController.text = doctorData['clinicName'] ?? "";
          streetController.text = doctorData['street'] ?? "";
          cityController.text = doctorData['city'] ?? "";
          stateController.text = doctorData['state'] ?? "";
          zipCodeController.text = doctorData['zipCode'] ?? "";
          morningStartController.text = doctorData['morningStart'] ?? "7 AM";
          morningEndController.text = doctorData['morningEnd'] ?? "1 PM";
          eveningStartController.text = doctorData['eveningStart'] ?? "6 PM";
          eveningEndController.text = doctorData['eveningEnd'] ?? "9 PM";
          morningAppointmentsController.text =
              doctorData['morningAppointments']?.toString() ?? "10";
          eveningAppointmentsController.text =
              doctorData['eveningAppointments']?.toString() ?? "10";
        });

        if (doctorData.containsKey('clinic_images')) {
          fetchClinicImages(List<String>.from(doctorData['clinic_images']));
        }
      } else {
        showSnackBar("Clinic details not found!");
      }
    } catch (e) {
      showSnackBar("Error fetching details: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchClinicImages(List<String> imageUrls) async {
    setState(() {
      clinicImageUrls = imageUrls;
    });
  }

  Future<void> selectAndUploadClinicImage() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    String filePath = "clinicimages/$userId.jpg";

    try {
      await _supabase.storage.from("doctor-uploads").upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      String imageUrl =
          _supabase.storage.from("doctor-uploads").getPublicUrl(filePath);

      clinicImageUrls.add(imageUrl);
      await _firestore
          .collection('doctors')
          .doc(userId)
          .update({'clinic_images': clinicImageUrls});

      if (mounted) setState(() {});
      showSnackBar("Clinic image added successfully!");
    } catch (e) {
      showSnackBar("Error uploading clinic image: $e");
    }
  }

  Future<void> updateClinicDetails() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore.collection('doctors').doc(userId).update({
        'clinicName': clinicNameController.text,
        'street': streetController.text,
        'city': cityController.text,
        'state': stateController.text,
        'zipCode': zipCodeController.text,
        'morningStart': morningStartController.text,
        'morningEnd': morningEndController.text,
        'eveningStart': eveningStartController.text,
        'eveningEnd': eveningEndController.text,
        'morningAppointments':
            int.tryParse(morningAppointmentsController.text) ?? 10,
        'eveningAppointments':
            int.tryParse(eveningAppointmentsController.text) ?? 10,
      });
      showSnackBar("Clinic details updated successfully!");
    } catch (e) {
      showSnackBar("Error updating clinic details: $e");
    }
  }

  void showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clinic Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                      controller: clinicNameController,
                      decoration: const InputDecoration(
                          labelText: "Clinic Name",
                          labelStyle: TextStyle(fontWeight: FontWeight.bold))),
                  TextField(
                      controller: morningStartController,
                      decoration: const InputDecoration(
                          labelText: "Morning start Time")),
                  TextField(
                      controller: morningEndController,
                      decoration:
                          const InputDecoration(labelText: "Morning end Time")),
                  TextField(
                      controller: eveningStartController,
                      decoration: const InputDecoration(
                          labelText: "Evening Start Time")),
                  TextField(
                      controller: eveningEndController,
                      decoration:
                          const InputDecoration(labelText: "Evening End Time")),
                  TextField(
                      controller: morningAppointmentsController,
                      decoration: const InputDecoration(
                          labelText: "Morning Appoitments Limit ")),
                  TextField(
                      controller: eveningAppointmentsController,
                      decoration: const InputDecoration(
                          labelText: "Evening Appointments Limit ")),
                  TextField(
                      controller: streetController,
                      decoration: const InputDecoration(labelText: "Street")),
                  TextField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: "City")),
                  TextField(
                      controller: stateController,
                      decoration: const InputDecoration(labelText: "State")),
                  TextField(
                      controller: zipCodeController,
                      decoration: const InputDecoration(labelText: "Zip Code")),
                  const SizedBox(height: 10),
                  clinicImageUrls.isNotEmpty
                      ? Column(
                          children: clinicImageUrls
                              .map((url) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Image.network(url, height: 150),
                                  ))
                              .toList(),
                        )
                      : const Text("No clinic images uploaded."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: selectAndUploadClinicImage,
                      child: const Text("Upload Clinic Image")),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: updateClinicDetails,
                      child: const Text("Update Clinic Details")),
                ],
              ),
            ),
    );
  }
}

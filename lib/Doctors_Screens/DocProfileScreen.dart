import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  String email = "";
  TextEditingController nameController = TextEditingController();
  TextEditingController specializationController = TextEditingController();
  TextEditingController experienceController = TextEditingController();
  TextEditingController certificateIdController = TextEditingController();

  bool isLoading = true;
  String profileImageUrl = "";
  String certificateImageUrl = "";

  @override
  void initState() {
    super.initState();
    fetchDoctorDetails();
  }

  Future<void> fetchDoctorDetails() async {
    String userId = _auth.currentUser!.uid;
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        email = userDoc['email_id'] ?? "";
      } else {
        showSnackBar("User not found in database!");
        return;
      }

      DocumentSnapshot doctorDoc =
          await _firestore.collection('doctors').doc(userId).get();

      if (doctorDoc.exists && doctorDoc.data() != null) {
        var doctorData = doctorDoc.data() as Map<String, dynamic>;

        setState(() {
          nameController.text =
              "Dr.${doctorData['firstName'] ?? ""} ${doctorData['lastName'] ?? ""}";
          specializationController.text = doctorData['specialization'] ?? "";
          experienceController.text =
              doctorData['experience']?.toString() ?? "0";
          certificateIdController.text = doctorData['licenseNo'] ?? "";
          profileImageUrl = doctorData['profileImage'] ?? "";
        });

        if (doctorData.containsKey('certificate_url')) {
          fetchCertificateImage(doctorData['certificate_url']);
        }
      } else {
        showSnackBar("Doctor details not found!");
      }
    } catch (e) {
      showSnackBar("Error fetching details: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCertificateImage(String certificateUrl) async {
    try {
      setState(() {
        certificateImageUrl = certificateUrl;
      });
    } catch (e) {
      showSnackBar("Error fetching certificate: $e");
    }
  }

  Future<void> selectAndUploadCertificate() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    String userId = _auth.currentUser!.uid;
    String filePath = "certificates/$userId.jpg";

    try {
      await _supabase.storage.from("doctor-uploads").remove([filePath]);

      final response = await _supabase.storage.from("doctor-uploads").upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      if (response.isEmpty) {
        showSnackBar("Failed to upload certificate");
        return;
      }

      String certificateUrl =
          _supabase.storage.from("doctor-uploads").getPublicUrl(filePath);

      await _firestore
          .collection('doctors')
          .doc(userId)
          .update({'certificate_url': certificateUrl});

      setState(() {
        certificateImageUrl = certificateUrl;
      });

      showSnackBar("Certificate updated successfully!");
    } catch (e) {
      showSnackBar("Error uploading certificate: $e");
    }
  }

  Future<void> selectAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    String filePath = "doctor-uploads/Profile/${_auth.currentUser!.uid}.jpg";

    try {
      final response = await _supabase.storage.from("doctor-uploads").upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      if (response.isEmpty) {
        showSnackBar("Failed to upload image");
        return;
      }

      String imageUrl =
          _supabase.storage.from("doctor-uploads").getPublicUrl(filePath);

      await _firestore
          .collection('doctors')
          .doc(_auth.currentUser!.uid)
          .update({'profileImage': imageUrl});

      setState(() {
        profileImageUrl = imageUrl;
      });

      showSnackBar("Profile picture updated!");
    } catch (e) {
      showSnackBar("Error uploading image: $e");
    }
  }

  Future<void> updateDoctorProfile() async {
    String userId = _auth.currentUser!.uid;
    try {
      await _firestore.collection('doctors').doc(userId).update({
        'firstName': nameController.text.split(' ')[0],
        'lastName': nameController.text.split(' ').length > 1
            ? nameController.text.split(' ')[1]
            : "",
        'specialization': specializationController.text,
        'experience': int.tryParse(experienceController.text) ?? 0,
        'licenseNo': certificateIdController.text,
      });
      showSnackBar("Profile updated successfully!");
    } catch (e) {
      showSnackBar("Error updating profile: $e");
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: selectAndUploadProfileImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl.isEmpty
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Email: $email",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: "Full Name")),
                  TextField(
                      controller: specializationController,
                      decoration:
                          const InputDecoration(labelText: "Specialization")),
                  TextField(
                      controller: experienceController,
                      decoration: const InputDecoration(
                          labelText: "Experience (Years)"),
                      keyboardType: TextInputType.number),
                  TextField(
                      controller: certificateIdController,
                      decoration:
                          const InputDecoration(labelText: "Certificate ID")),
                  const SizedBox(height: 10),
                  certificateImageUrl.isNotEmpty
                      ? Image.network(certificateImageUrl, height: 200)
                      : const Text("No certificate uploaded."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: updateDoctorProfile,
                    child: const Text("Update Profile"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectAndUploadCertificate,
                    child: const Text("Upload/Change Certificate"),
                  ),
                ],
              ),
            ),
    );
  }
}

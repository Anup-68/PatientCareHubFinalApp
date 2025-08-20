import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:patientcarehub/USER_Regestration/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Ensure this file is available

class UploadDoctorImages extends StatefulWidget {
  const UploadDoctorImages({super.key});

  @override
  State<UploadDoctorImages> createState() => _UploadDoctorImagesState();
}

class _UploadDoctorImagesState extends State<UploadDoctorImages> {
  final ImagePicker _picker = ImagePicker();
  File? _certificateImage;
  final List<File> _clinicImages = [];
  final SupabaseClient supabase = Supabase.instance.client;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isUploading = false;
  String? userId;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserId();
    });
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _getUserId() {
    userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar("User not logged in!");
    }
  }

  /// Picks an image from the gallery
  Future<void> _pickImage(bool isCertificate) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isCertificate) {
          _certificateImage = File(pickedFile.path);
        } else {
          if (_clinicImages.length < 5) {
            _clinicImages.add(File(pickedFile.path));
          } else {
            _showSnackBar("You can upload a maximum of 5 clinic images");
          }
        }
      });
    }
  }

  /// Uploads an image to Supabase and returns the public URL
  Future<String?> _uploadToSupabase(File file, String folderName) async {
    try {
      String fileName =
          '$folderName/${userId}_${DateTime.now().millisecondsSinceEpoch}_${basename(file.path)}';

      await supabase.storage.from('doctor-uploads').upload(fileName, file);

      return supabase.storage.from('doctor-uploads').getPublicUrl(fileName);
    } catch (e) {
      if (!mounted) return null;
      _showSnackBar("Upload failed: $e");
      return null;
    }
  }

  /// Uploads images and updates the existing doctor's Firestore document.
  /// After a successful upload, the user is redirected to the LoginScreen.
  Future<void> _uploadImages() async {
    if (userId == null) {
      _showSnackBar("User not logged in!");
      return;
    }

    if (_certificateImage == null || _clinicImages.length < 3) {
      _showSnackBar("Please upload a certificate and at least 3 clinic images");
      return;
    }

    setState(() => isUploading = true);

    try {
      // Upload Certificate
      String? certUrl =
          await _uploadToSupabase(_certificateImage!, 'certificates');
      if (certUrl == null) throw Exception("Certificate upload failed");

      // Upload Clinic Images
      List<String> clinicUrls = [];
      for (File image in _clinicImages) {
        String? clinicUrl = await _uploadToSupabase(image, 'clinicimages');
        if (clinicUrl != null) clinicUrls.add(clinicUrl);
      }

      // Update the same Firestore document under "doctors/{userId}"
      await firestore.collection('doctors').doc(userId).update({
        'certificate_url': certUrl,
        'clinic_images': FieldValue.arrayUnion(clinicUrls),
      });

      // Update user type in "Users" collection
      await firestore
          .collection('Users')
          .doc(userId)
          .update({'userType': 'Doctor'});

      if (!mounted) return;
      _showSnackBar("Images Uploaded Successfully. Redirecting to login...");

      // Redirect to LoginScreen after a short delay using the context from the scaffold messenger key
      Future.delayed(Duration(seconds: 2), () {
        if (mounted && _scaffoldMessengerKey.currentContext != null) {
          Navigator.of(_scaffoldMessengerKey.currentContext!).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Upload failed: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey, // Use the GlobalKey for managing SnackBars
      child: Scaffold(
        appBar: AppBar(title: const Text('Upload Doctor Images')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Certificate Upload
                Text("Upload Doctor Certificate",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _certificateImage == null
                    ? ElevatedButton(
                        onPressed: () => _pickImage(true),
                        child: const Text("Upload Certificate"),
                      )
                    : Stack(
                        children: [
                          Image.file(_certificateImage!, height: 150),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _certificateImage = null),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                // Clinic Images Upload
                Text("Upload Clinic Images (Min 3, Max 5)",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _pickImage(false),
                  child: const Text("Upload Clinic Images"),
                ),
                // Preview Uploaded Clinic Images
                _clinicImages.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _clinicImages
                            .asMap()
                            .entries
                            .map((entry) => Stack(
                                  children: [
                                    Image.file(entry.value,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover),
                                    Positioned(
                                      right: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.cancel,
                                            color: Colors.red),
                                        onPressed: () => setState(() =>
                                            _clinicImages.removeAt(entry.key)),
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      )
                    : const SizedBox(),
                const SizedBox(height: 20),
                // Upload Button
                ElevatedButton(
                  onPressed: isUploading ? null : _uploadImages,
                  child: Text(isUploading ? 'Uploading...' : 'Upload Images'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

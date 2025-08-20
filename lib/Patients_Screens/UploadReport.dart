import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class UploadReportScreen extends StatefulWidget {
  final String patientId;
  const UploadReportScreen({super.key, required this.patientId});

  @override
  _UploadReportScreenState createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  bool _isUploading = false;
  final TextEditingController _reportInfoController = TextEditingController();

  Future<void> uploadPDF() async {
    try {
      if (_reportInfoController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter report details!')),
        );
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file selected!')),
        );
        return;
      }

      File file = File(result.files.single.path!);
      String fileName =
          '${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      String storagePath = 'Reports/$fileName'; // Path inside 'patient-uploads'

      setState(() {
        _isUploading = true;
      });

      // Upload to Supabase Storage (Bucket: patient-uploads)
      await Supabase.instance.client.storage
          .from('patient-uploads')
          .upload(storagePath, file);

      // Save to Firebase Firestore
      await FirebaseFirestore.instance.collection('MedicalReports').add({
        'patientId': widget.patientId,
        'timestamp': Timestamp.now(),
        'filePath': storagePath, // Store file path for retrieval
        'reportInfo': _reportInfoController.text, // Store report details
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF Uploaded Successfully!')),
      );

      _reportInfoController.clear(); // Clear text field after upload
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> deletePDF(String docId, String filePath) async {
    try {
      // Delete from Supabase Storage (Bucket: patient-uploads)
      await Supabase.instance.client.storage
          .from('patient-uploads')
          .remove([filePath]);

      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('MedicalReports')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF Deleted Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void viewPDF(String filePath) {
    final supabaseUrl = Supabase.instance.client.storage
        .from('patient-uploads') // Correct bucket name
        .getPublicUrl(filePath);

    print("Opening PDF URL: $supabaseUrl"); // Debugging

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(fileUrl: supabaseUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload & Manage Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _reportInfoController,
              decoration: InputDecoration(
                labelText: "Report Of",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('MedicalReports')
                  .where('patientId', isEqualTo: widget.patientId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final reports = snapshot.data!.docs;

                if (reports.isEmpty) {
                  return Center(child: Text("No reports uploaded yet."));
                }

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    var report = reports[index];
                    String docId = report.id;
                    String filePath = report['filePath'];
                    String reportInfo =
                        report['reportInfo'] ?? "No details available";

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Card(
                        color: Colors.lightGreen[100], // Light green background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            "${index + 1}. $reportInfo",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Tap to view"),
                          onTap: () => viewPDF(filePath),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deletePDF(docId, filePath),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: _isUploading ? null : uploadPDF,
              child: _isUploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Upload PDF', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String fileUrl;
  const PDFViewerScreen({super.key, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View PDF')),
      body: Center(
        child: fileUrl.isNotEmpty
            ? SfPdfViewer.network(fileUrl)
            : Text("Failed to load PDF"),
      ),
    );
  }
}

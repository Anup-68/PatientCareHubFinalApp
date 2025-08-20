import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DoctorReportScreen extends StatelessWidget {
  final String patientId;

  const DoctorReportScreen({super.key, required this.patientId});

  void viewPDF(BuildContext context, String filePath) {
    final supabaseUrl = Supabase.instance.client.storage
        .from('patient-uploads') // Correct Supabase bucket name
        .getPublicUrl(filePath);

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
      appBar: AppBar(title: Text('Reports of Patient: $patientId')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('MedicalReports')
            .where('patientId', isEqualTo: patientId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return Center(child: Text("No reports found for this patient."));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var report = reports[index];
              String filePath = report['filePath'];
              String reportInfo =
                  report['reportInfo'] ?? "No details available";
              Timestamp timestamp = report['timestamp'] as Timestamp;
              DateTime reportDate = timestamp.toDate();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    subtitle: Text(
                      "Date: ${reportDate.toLocal()} • Tap to view",
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () => viewPDF(context, filePath),
                    trailing: Icon(Icons.visibility, color: Colors.blue),
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

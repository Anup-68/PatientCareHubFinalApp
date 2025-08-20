import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class DoctorReviewPage extends StatelessWidget {
  final String doctorId;

  const DoctorReviewPage({super.key, required this.doctorId});

  void toggleReviewVisibility(String reviewId, bool currentState) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .update({'hidden': !currentState});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patient Reviews')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reviews available.'));
          }
          return ListView(
            padding: EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              bool isHidden =
                  data.containsKey('hidden') ? data['hidden'] : false;

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(data['patientId'])
                    .get(),
                builder:
                    (context, AsyncSnapshot<DocumentSnapshot> patientSnapshot) {
                  String patientName = 'Unknown Patient';
                  if (patientSnapshot.connectionState == ConnectionState.done &&
                      patientSnapshot.hasData) {
                    var patientData =
                        patientSnapshot.data!.data() as Map<String, dynamic>?;
                    if (patientData != null &&
                        patientData.containsKey('fullName')) {
                      patientName = patientData['fullName'];
                    }
                  }

                  return Card(
                    color: isHidden
                        ? Colors.red.shade100
                        : Colors.white, // Change color if hidden
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reviewed by: $patientName',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          RatingBarIndicator(
                            rating: (data['rating'] as num).toDouble(),
                            itemCount: 5,
                            itemSize: 20,
                            direction: Axis.horizontal,
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            data['review'] ?? '',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Reviewed on: ${data['timestamp']?.toDate().toString() ?? 'Unknown date'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    toggleReviewVisibility(doc.id, isHidden),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isHidden ? Colors.green : Colors.red,
                                ),
                                child: Text(isHidden ? 'Unhide' : 'Hide'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

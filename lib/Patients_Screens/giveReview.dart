import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class GiveReviewPage extends StatefulWidget {
  final String doctorId;

  const GiveReviewPage({super.key, required this.doctorId});

  @override
  _GiveReviewPageState createState() => _GiveReviewPageState();
}

class _GiveReviewPageState extends State<GiveReviewPage> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submitReview() async {
    String reviewText = _reviewController.text.trim();
    String? patientId = _auth.currentUser?.uid;

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to submit a review.')),
      );
      return;
    }

    if (_rating == 0 || reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide both a rating and a review.')),
      );
      return;
    }

    // Check if the patient has already reviewed this doctor
    QuerySnapshot existingReview = await _firestore
        .collection('reviews')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('patientId', isEqualTo: patientId)
        .get();

    if (existingReview.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already reviewed this doctor.')),
      );
      return;
    }

    // Show confirmation dialog before submitting
    bool confirmSubmit = await _showConfirmationDialog();
    if (!confirmSubmit) return;

    await _firestore.collection('reviews').add({
      'doctorId': widget.doctorId,
      'patientId': patientId,
      'rating': _rating,
      'review': reviewText,
      'timestamp': FieldValue.serverTimestamp(),
      'hidden': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review submitted successfully!')),
    );

    setState(() {
      _rating = 0;
      _reviewController.clear();
    });
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Confirm Review Submission"),
            content: Text("Are you sure you want to submit this review?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Submit"),
              ),
            ],
          ),
        ) ??
        false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Give Review')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate the Doctor:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitReview,
                child: Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PatientCommunityScreen extends StatefulWidget {
  const PatientCommunityScreen({super.key});

  @override
  State<PatientCommunityScreen> createState() => _PatientCommunityScreenState();
}

class _PatientCommunityScreenState extends State<PatientCommunityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("Community Page"),
    );
  }
}
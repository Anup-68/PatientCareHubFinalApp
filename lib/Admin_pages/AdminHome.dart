import 'package:flutter/material.dart';
import 'package:patientcarehub/Admin_pages/DoctorsListPage.dart';
import 'package:patientcarehub/Admin_pages/Patientsdeatilspage.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String activeTab = "Dashboard";

  void changeTab(String tab) {
    setState(() {
      activeTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activeTab),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Admin Panel',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () => changeTab("Dashboard"),
            ),
            ListTile(
              leading: Icon(Icons.medical_services_rounded),
              title: Text('Doctors'),
              onTap: () => {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => DoctorListPage()),
                )
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Patients'),
              onTap: () => {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => PatientListPage()),
                )
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => changeTab("Settings"),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Welcome to $activeTab',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

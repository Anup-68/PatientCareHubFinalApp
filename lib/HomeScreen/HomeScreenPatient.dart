import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Doctors_Screens/CommunityDoctorPage.dart';
import 'package:patientcarehub/HomeScreen/UserNotification.dart';
import 'package:patientcarehub/Patients_Screens/AllChatsScreen.dart';
import 'package:patientcarehub/Patients_Screens/HomeScreen.dart';
import 'package:patientcarehub/Patients_Screens/MedicalHistoryScreen.dart';
import 'package:patientcarehub/Patients_Screens/PatientAppointmentsPage.dart';
import 'package:patientcarehub/Patients_Screens/PatientprofileScreen.dart';
import 'package:patientcarehub/Patients_Screens/PrescriptionScreen.dart';
import 'package:patientcarehub/Patients_Screens/SettingScreen.dart';
import 'package:patientcarehub/Patients_Screens/UploadReport.dart';
import 'package:patientcarehub/USER_Regestration/login_screen.dart';

import '../Doctor_Registration/Doctor_welcomepage.dart';

class Homescreenpatient extends StatefulWidget {
  const Homescreenpatient({super.key});

  @override
  State<Homescreenpatient> createState() => _HomescreenpatientState();
}

class _HomescreenpatientState extends State<Homescreenpatient> {
  int _selectedIndexBottom = 0;
  int _selectedIndexDrawer = 0;

  final List<Widget> _bottomOptions = <Widget>[
    PatientHomeScreen(),
    PatientAppointmentsScreen(),
    ChatListScreen(),
    CommunityListScreen(),
  ];

  final List<Widget> _drawerOptions = <Widget>[
    PatientProfileScreen(
      userId: FirebaseAuth.instance.currentUser!.uid,
    ),
    MedicalHistoryScreen(),
    UploadReportScreen(
      patientId: FirebaseAuth.instance.currentUser!.uid,
    ),
    PatientPrescriptionsScreen(),
    SettingsPage(),

    //const DoctorWelcomepage(), // Include if needed
  ];

  void _onItemTappedBottom(int index) {
    setState(() {
      _selectedIndexBottom = index;
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }

  void _onItemTappedDrawer(int index) {
    setState(() {
      _selectedIndexDrawer = index;
    });
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _drawerOptions[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Patient Care'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Color.fromARGB(255, 58, 7, 245),
            ),
            onPressed: _navigateToNotifications,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndexDrawer == 0,
              onTap: () => _onItemTappedDrawer(0),
            ),
            ListTile(
              leading: const Icon(Icons.medical_information_rounded),
              title: const Text('Medical History'),
              selected: _selectedIndexDrawer == 1,
              onTap: () => _onItemTappedDrawer(1),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Medical Reports'),
              selected: _selectedIndexDrawer == 2,
              onTap: () => _onItemTappedDrawer(2),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Prescriptions'),
              selected: _selectedIndexDrawer == 3,
              onTap: () => _onItemTappedDrawer(3),
            ),
            // ListTile for Doctor Registration (if needed)
            ListTile(
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text('Are You a Doctor ?'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DoctorWelcomepage()),
                );
              },
            ),
            ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                selected: _selectedIndexDrawer == 4,
                onTap: () => _onItemTappedDrawer(4)),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                //Implement sign out logic
              },
            ),
          ],
        ),
      ),
      body: _bottomOptions[_selectedIndexBottom],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
        ],
        currentIndex: _selectedIndexBottom,
        selectedItemColor: const Color.fromARGB(255, 4, 133, 239),
        unselectedItemColor: const Color.fromARGB(255, 140, 234, 247),
        onTap: _onItemTappedBottom,
      ),
    );
  }
}

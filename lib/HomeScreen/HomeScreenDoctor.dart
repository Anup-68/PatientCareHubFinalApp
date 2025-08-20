import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Doctors_Screens/Allapointments.dart';
import 'package:patientcarehub/Doctors_Screens/ClinicDetails.dart';
import 'package:patientcarehub/Doctors_Screens/CommunityDoctorPage.dart';
import 'package:patientcarehub/Doctors_Screens/DocProfileScreen.dart';
import 'package:patientcarehub/Doctors_Screens/DoctorAppointmentpage.dart';
import 'package:patientcarehub/Doctors_Screens/ViewReview.dart';
import 'package:patientcarehub/HomeScreen/UserNotification.dart';
import 'package:patientcarehub/Patients_Screens/AllChatsScreen.dart';
import 'package:patientcarehub/Patients_Screens/SettingScreen.dart';
import 'package:patientcarehub/USER_Regestration/login_screen.dart';
// Import Notification Screen

class HomescreenDoctor extends StatefulWidget {
  const HomescreenDoctor({super.key});

  @override
  State<HomescreenDoctor> createState() => _HomescreenDoctorState();
}

class _HomescreenDoctorState extends State<HomescreenDoctor> {
  int _selectedIndexBottom = 0;
  int _selectedIndexDrawer = 0;

  final List<Widget> _bottomOptions = <Widget>[
    DoctorAppointmentsScreen(),
    ChatListScreen(),
    CommunityListScreen(),
  ];

  final List<Widget> _drawerOptions = <Widget>[
    DoctorProfileScreen(),
    const ClinicDetailsScreen(),
    SettingsPage(),
    AllAppointments(),
    DoctorReviewPage(doctorId: FirebaseAuth.instance.currentUser!.uid),
    SettingsPage(),
  ];

  void _onItemTappedBottom(int index) {
    setState(() {
      _selectedIndexBottom = index;
    });
  }

  void _onItemTappedDrawer(int index) {
    setState(() {
      _selectedIndexDrawer = index;
    });
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _drawerOptions[index]),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 65,
                    backgroundImage:
                        AssetImage("assets/docprofile.jpg"), // Default image
                  ),
                ],
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
              title: const Text('Clinic details'),
              selected: _selectedIndexDrawer == 1,
              onTap: () => _onItemTappedDrawer(1),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Clinic Staff'),
              selected: _selectedIndexDrawer == 2,
              onTap: () => _onItemTappedDrawer(2),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text(' All Appointments '),
              selected: _selectedIndexDrawer == 3,
              onTap: () => _onItemTappedDrawer(3),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text(' Reviews '),
              selected: _selectedIndexDrawer == 4,
              onTap: () => _onItemTappedDrawer(4),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              selected: _selectedIndexDrawer == 5,
              onTap: () => _onItemTappedDrawer(5),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                // Implement sign out logic
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

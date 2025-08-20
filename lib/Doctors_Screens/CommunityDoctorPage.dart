import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Doctors_Screens/CommunityChatScreen.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  _CommunityListScreenState createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isDoctor = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    String userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        _isDoctor = userDoc['userType'] == 'Doctor';
      });
    }
  }

  /// Function to create a new community (Doctors Only)
  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please enter all fields.")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('communities').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser!.uid,
        'memberCount': 1, // Default 1 member (creator)
        'members': [_auth.currentUser!.uid], // adding creator as member
      });

      _nameController.clear();
      _descriptionController.clear();
      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Community Created!")));
    } catch (e) {
      print("Error creating community: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to create community.")));
    }
  }

  /// Shows the community creation dialog for doctors
  void _showCreateCommunityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create Community"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Community Name"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _createCommunity,
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog for doctors to add a patient to a community.
  void _showAddPatientDialog(String communityId, List currentMembers) async {
    String doctorId = _auth.currentUser!.uid;

    QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('status', isEqualTo: 'Completed')
        .where('doctorId', isEqualTo: doctorId) // Filter by logged-in doctor
        .get();

    Set<String> bookedPatientIds = {};
    for (var doc in appointmentSnapshot.docs) {
      bookedPatientIds.add(doc['patientId']);
    }

    List<String> patientsToAdd = bookedPatientIds
        .where((patientId) => !currentMembers.contains(patientId))
        .toList();

    if (patientsToAdd.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("No patients available"),
          content: Text(
              "All patients with completed appointments with you are already added to this community."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Patient to Community"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: patientsToAdd.length,
            itemBuilder: (context, index) {
              String patientId = patientsToAdd[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(patientId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(title: Text("Loading..."));
                  }
                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  String patientName = userData['name'] ?? "Unknown";
                  return ListTile(
                    title: Text(patientName),
                    trailing: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('communities')
                            .doc(communityId)
                            .update({
                          'members': FieldValue.arrayUnion([patientId]),
                          'memberCount': FieldValue.increment(1),
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("$patientName added to community.")));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .where('members',
                arrayContains:
                    _auth.currentUser!.uid) // Show only member communities
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No communities available."));
          }

          return ListView(
            padding: EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              Timestamp createdAt = data['createdAt'] ?? Timestamp.now();
              DateTime createdDate = createdAt.toDate();
              String formattedDate =
                  "${createdDate.day}/${createdDate.month}/${createdDate.year}";
              List currentMembers = data['members'] ?? [];

              return Card(
                color: Color.fromARGB(255, 177, 229, 255),
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: Icon(Icons.group, color: Colors.blue, size: 40),
                  title: Text(
                    data['name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 5),
                      Text("Created on: $formattedDate",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("Members: ${data['memberCount']}",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: _isDoctor
                      ? IconButton(
                          icon: Icon(Icons.person_add),
                          onPressed: () {
                            _showAddPatientDialog(doc.id, currentMembers);
                          },
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorCommunityChatScreen(
                          communityId: doc.id,
                          communityName: data['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: _isDoctor
          ? FloatingActionButton(
              onPressed: _showCreateCommunityDialog,
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

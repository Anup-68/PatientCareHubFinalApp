import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorCommunityChatScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  const DoctorCommunityChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  _DoctorCommunityChatScreenState createState() =>
      _DoctorCommunityChatScreenState();
}

class _DoctorCommunityChatScreenState extends State<DoctorCommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isSending = false;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  /// Check if the current user is a Doctor
  Future<void> _checkUserRole() async {
    String userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        _isDoctor = userDoc['userType'] == 'Doctor';
      });
    }
  }

  /// Sends a text or image message
  Future<void> _sendMessage({String? imageUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null) return;

    String senderId = _auth.currentUser!.uid;

    await _firestore.collection('community_messages').add({
      'communityId': widget.communityId,
      'senderId': senderId,
      'message': imageUrl ?? _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': imageUrl != null,
    });

    _messageController.clear();
  }

  /// Picks and uploads an image to Supabase and then sends the message
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
    String filePath = 'Images/$fileName';

    try {
      setState(() => _isSending = true);

      // Upload image to Supabase
      await _supabase.storage.from('Community').upload(filePath, imageFile);

      // Get public URL
      String imageUrl =
          _supabase.storage.from('Community').getPublicUrl(filePath);

      // Save URL to Firestore messages collection
      await _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image upload failed.")));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.communityName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('community_messages')
                  .where('communityId', isEqualTo: widget.communityId)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet."));
                }

                return ListView(
                  padding: EdgeInsets.all(10),
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    Timestamp? timestamp = data['timestamp'] as Timestamp?;
                    String timeString;
                    if (timestamp != null) {
                      DateTime dt = timestamp.toDate();
                      timeString =
                          "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                    } else {
                      timeString = "Now";
                    }

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            data['isImage'] == true
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImage(
                                              imageUrl: data['message']),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        data['message'],
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Text("Image failed to load");
                                        },
                                      ),
                                    ),
                                  )
                                : Text(
                                    data['message'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                            SizedBox(height: 5),
                            Text(
                              timeString,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Show message input only for doctors
          if (_isDoctor)
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image, color: Colors.blue),
                    onPressed: _isSending ? null : _pickAndUploadImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: _isSending ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Full screen image view for maximizing an image in chat
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

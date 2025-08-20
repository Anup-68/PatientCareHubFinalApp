import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;

  const ChatScreen(
      {super.key, required this.doctorId, required this.patientId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isChatEnabled = true;
  String? _chatId;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _determineUserRole();
    _initializeChat();
  }

  void _determineUserRole() {
    String currentUserId = _auth.currentUser!.uid;
    if (currentUserId == widget.doctorId) {
      setState(() {
        _isDoctor = true;
        _isChatEnabled = true;
      });
    }
  }

  Future<void> _initializeChat() async {
    var chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('patientId', isEqualTo: widget.patientId)
        .where('doctorId', isEqualTo: widget.doctorId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      var chatDoc = chatQuery.docs.first;
      setState(() {
        _chatId = chatDoc.id;
        _isChatEnabled = chatDoc['chatEnabled'];
      });
    }
  }

  void _toggleChatStatus() async {
    if (_chatId != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .update({'chatEnabled': !_isChatEnabled});
      setState(() {
        _isChatEnabled = !_isChatEnabled;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String senderId = _auth.currentUser!.uid;
    String receiverId = _isDoctor ? widget.patientId : widget.doctorId;
    String message = _messageController.text.trim();

    if (_chatId == null) {
      // If no chat exists, create a new one when the first message is sent
      DocumentReference chatRef =
          await FirebaseFirestore.instance.collection('chats').add({
        'patientId': widget.patientId,
        'doctorId': widget.doctorId,
        'chatEnabled': _isDoctor,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _chatId = chatRef.id;
      });
    }

    await FirebaseFirestore.instance.collection('messages').add({
      'chat_id': _chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${_isDoctor ? 'Patient' : 'Doctor'}"),
        actions: [
          if (_isDoctor)
            IconButton(
              icon: Icon(_isChatEnabled ? Icons.lock_open : Icons.lock),
              onPressed: _toggleChatStatus,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatId != null
                  ? FirebaseFirestore.instance
                      .collection('messages')
                      .where('chat_id', isEqualTo: _chatId)
                      .orderBy('timestamp', descending: false)
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("No messages yet. Start chatting!"));
                }

                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.reversed.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
                    DateTime dateTime = timestamp.toDate();
                    String formattedDate =
                        DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['message'],
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              formattedDate,
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
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _isChatEnabled,
                    decoration: InputDecoration(
                      hintText: _isChatEnabled
                          ? "Type a message..."
                          : "Chat is locked",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send,
                      color: _isChatEnabled ? Colors.blue : Colors.grey),
                  onPressed: _isChatEnabled ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

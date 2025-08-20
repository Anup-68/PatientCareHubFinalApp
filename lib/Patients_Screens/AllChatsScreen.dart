import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Patients_Screens/chatScreen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where(Filter.or(
              Filter('patientId', isEqualTo: currentUserId),
              Filter('doctorId', isEqualTo: currentUserId),
            ))
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No chats available."));
          }

          List<QueryDocumentSnapshot> chatDocs = snapshot.data!.docs;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _sortChatsByRecentMessage(chatDocs),
            builder: (context, sortedSnapshot) {
              if (!sortedSnapshot.hasData || sortedSnapshot.data!.isEmpty) {
                return Center(child: Text("No chats available."));
              }

              var sortedChats = sortedSnapshot.data!;

              return ListView.builder(
                padding: EdgeInsets.all(10),
                itemCount: sortedChats.length,
                itemBuilder: (context, index) {
                  var chatData = sortedChats[index];
                  String chatId = chatData['chatId'];
                  String doctorId = chatData['doctorId'];
                  String patientId = chatData['patientId'];
                  bool isChatEnabled = chatData['chatEnabled'];
                  String otherUserId =
                      currentUserId == doctorId ? patientId : doctorId;
                  String lastMessage =
                      chatData['lastMessage'] ?? "No messages yet.";
                  Timestamp? lastMessageTimestamp =
                      chatData['lastMessageTimestamp'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return SizedBox.shrink();
                      var userData =
                          userSnapshot.data!.data() as Map<String, dynamic>?;
                      String otherUserName =
                          userData?['name'] ?? 'Unknown User';

                      return Card(
                        elevation: 3,
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            otherUserName,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          trailing: Icon(
                            isChatEnabled ? Icons.chat : Icons.lock,
                            color: isChatEnabled ? Colors.green : Colors.red,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  doctorId: doctorId,
                                  patientId: patientId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _sortChatsByRecentMessage(
      List<QueryDocumentSnapshot> chatDocs) async {
    List<Map<String, dynamic>> chatsWithLastMessage = [];

    for (var chatDoc in chatDocs) {
      var data = chatDoc.data() as Map<String, dynamic>;
      var messagesQuery = await FirebaseFirestore.instance
          .collection('messages')
          .where('chat_id', isEqualTo: chatDoc.id)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      String lastMessage = "No messages yet.";
      Timestamp? lastMessageTimestamp;

      if (messagesQuery.docs.isNotEmpty) {
        var lastMessageData = messagesQuery.docs.first.data();
        lastMessage = lastMessageData['message'];
        lastMessageTimestamp = lastMessageData['timestamp'];
      }

      chatsWithLastMessage.add({
        'chatId': chatDoc.id,
        'doctorId': data['doctorId'],
        'patientId': data['patientId'],
        'chatEnabled': data['chatEnabled'],
        'lastMessage': lastMessage,
        'lastMessageTimestamp': lastMessageTimestamp,
      });
    }

    chatsWithLastMessage.sort((a, b) {
      Timestamp? timestampA = a['lastMessageTimestamp'];
      Timestamp? timestampB = b['lastMessageTimestamp'];
      if (timestampA == null && timestampB == null) return 0;
      if (timestampA == null) return 1;
      if (timestampB == null) return -1;
      return timestampB.compareTo(timestampA);
    });

    return chatsWithLastMessage;
  }
}

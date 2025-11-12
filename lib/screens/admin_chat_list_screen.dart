import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommers_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Query all chats (no ordering to avoid index requirement)
        stream: FirebaseFirestore.instance
            .collection('chats')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active chats.'));
          }

          // 2. Sort the chats by lastMessageAt in the app
          final chatDocs = snapshot.data!.docs;
          chatDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['lastMessageAt'] as Timestamp?;
            final bTime = bData['lastMessageAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // descending (newest first)
          });
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              
              final String userId = chatDoc.id;
              final String userEmail = chatData['userEmail'] ?? 'User ID: $userId';
              final String lastMessage = chatData['lastMessage'] ?? '...';
              
              // 2. --- NEW: Get the admin's unread count ---
              final int unreadCount = chatData['unreadByAdminCount'] ?? 0;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  lastMessage, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                
                // 3. --- NEW: Show a Badge on the trailing icon ---
                trailing: unreadCount > 0
                    ? Badge(
                        label: Text('$unreadCount'),
                        child: const Icon(Icons.arrow_forward_ios),
                      )
                    : const Icon(Icons.arrow_forward_ios),
                
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatRoomId: userId,
                        userName: userEmail,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

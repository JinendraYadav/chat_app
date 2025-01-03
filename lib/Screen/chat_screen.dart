import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final String chatRoomId;

  const ChatScreen({
    required this.chatRoomId,
    required this.userMap,
    super.key,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _createOrUpdateChatRoom(); // Ensure chat room creation on screen load
  }

  Future<void> _createOrUpdateChatRoom() async {
    // Get current user ID
    final currentUserId = _auth.currentUser?.uid;

    // Create chat room ID using the users' IDs
    final chatRoomId = widget.chatRoomId; // Assume chatRoomId is passed correctly

    // Reference to the chat room document
    final chatRoomDoc = _firestore.collection('chatroom').doc(chatRoomId);

    // Check if the chat room already exists
    final chatRoomSnapshot = await chatRoomDoc.get();

    if (!chatRoomSnapshot.exists) {
      // Create the chat room if it doesn't exist
      await chatRoomDoc.set({
        'participants': [currentUserId, widget.userMap['uid']],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() {
        _imageFile = File(xFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    final String fileName = const Uuid().v1();
    final ref = FirebaseStorage.instance.ref().child('images').child('$fileName.jpg');

    try {
      await ref.putFile(_imageFile!);
      final String imageUrl = await ref.getDownloadURL();

      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .add({
        'sendby': _auth.currentUser?.displayName ?? 'Unknown',
        'message': imageUrl,
        'type': 'img',
        'time': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _showAlertDialog('Error', 'Failed to upload image: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text;
    if (message.isNotEmpty) {
      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .add({
        'sendby': _auth.currentUser?.displayName ?? 'Unknown',
        'message': message,
        'type': 'text',
        'time': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } else {
      await _showAlertDialog('Warning', 'Enter some text to send.');
    }
  }

  Future<void> _showAlertDialog(String title, String message) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(widget.userMap['uid'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final status = snapshot.data?['status'] ?? 'Unknown';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.userMap['name']),
                  Text(status, style: const TextStyle(fontSize: 14)),
                ],
              );
            } else {
              return const Text('Loading...');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatroom')
                  .doc(widget.chatRoomId)
                  .collection('chats')
                  .orderBy('time', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.hasData) {
                  final messages = snapshot.data!.docs;
                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages'));
                  }
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final map = messages[index].data() as Map<String, dynamic>;
                      return _buildMessage(size, map);
                    },
                  );
                }
                return const Center(child: Text('No messages'));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo),
                      ),
                      hintText: 'Send Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Size size, Map<String, dynamic> map) {
    final isCurrentUser = map['sendby'] == _auth.currentUser?.displayName;

    if (map['type'] == 'text') {
      return Container(
        width: size.width,
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isCurrentUser ? Colors.blue : Colors.grey[300],
          ),
          child: Text(
            map['message'],
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
      );
    } else {
      return Container(
        height: size.height / 2.5,
        width: size.width,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ShowImage(imageUrl: map['message'])),
          ),
          child: Container(
            height: size.height / 2.5,
            width: size.width / 2,
            decoration: BoxDecoration(border: Border.all()),
            alignment: map['message'].isNotEmpty ? null : Alignment.center,
            child: map['message'].isNotEmpty
                ? Image.network(map['message'], fit: BoxFit.cover)
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }
  }
}

class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}

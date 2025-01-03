import 'package:chat_app/Group%20Chat/group_chat_screen.dart';
import 'package:chat_app/Screen/chat_screen.dart';
import 'package:chat_app/method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      setStatus("Online");
    } else {
      // offline
      setStatus("Offline");
    }
  }

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

void onSearch() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchText = _search.text.trim();

  setState(() {
    isLoading = true;
  });

  try {
    // Query for email
    QuerySnapshot emailQuery = await firestore
        .collection('users')
        .where("email", isEqualTo: searchText)
        .get();

    // Query for username
    QuerySnapshot usernameQuery = await firestore
        .collection('users')
        .where("name", isEqualTo: searchText)
        .get();

    List<QueryDocumentSnapshot> allDocs = [];

    if (emailQuery.docs.isNotEmpty) {
      allDocs.addAll(emailQuery.docs);
    }

    if (usernameQuery.docs.isNotEmpty) {
      allDocs.addAll(usernameQuery.docs);
    }

    if (mounted) { // Check if the widget is still mounted
      if (allDocs.isNotEmpty) {
        setState(() {
          userMap = allDocs[0].data() as Map<String, dynamic>;
          isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("User Info"),
              content: Text(
                  "User Name: ${userMap?['name']}\nUser Status: ${userMap?['status']}"),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("User Not Found"),
              content: const Text("No user found with the provided email or username."),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(e.toString()),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }
}



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout), onPressed: () => logOut(context))
        ],
      ),
      body: isLoading
          ? Center(
              child: SizedBox(
                height: size.height / 20,
                width: size.height / 20,
                child: const CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: size.height / 20,
                ),
                Container(
                  height: size.height / 14,
                  width: size.width,
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: size.height / 14,
                    width: size.width / 1.15,
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: "Search",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: size.height / 50,
                ),
                ElevatedButton(
                  onPressed: onSearch,
                  child: const Text("Search"),
                ),
                SizedBox(
                  height: size.height / 30,
                ),
                userMap != null
                    ? ListTile(
                        onTap: () {
                          String roomId = chatRoomId(
                              _auth.currentUser!.displayName!,
                              userMap!['name']);

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatRoomId: roomId,
                                userMap: userMap!,
                              ),
                            ),
                          );
                        },
                        leading:
                            const Icon(Icons.account_box, color: Colors.black),
                        title: Text(
                          userMap!['name'],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(userMap!['email']),
                        trailing: const Icon(Icons.chat, color: Colors.black),
                      )
                    : Container(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.group),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GroupChatHomeScreen(),
          ),
        ),
      ),
    );
  }
}

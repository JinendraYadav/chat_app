import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // Import the logger package

class AddMembersINGroup extends StatefulWidget {
  final String groupChatId, name;
  final List<Map<String, dynamic>> membersList;

  const AddMembersINGroup({
    required this.name,
    required this.membersList,
    required this.groupChatId,
    super.key,
  });

  @override
  AddMembersINGroupState createState() => AddMembersINGroupState();
}

class AddMembersINGroupState extends State<AddMembersINGroup> {
  final TextEditingController _search = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(); // Initialize the logger
  Map<String, dynamic>? userMap;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> onSearch() async {
    setState(() {
      isLoading = true;
    });

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where("email", isEqualTo: _search.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          userMap = querySnapshot.docs[0].data();
          isLoading = false;
        });
        _logger.i(userMap); // Use the logger instead of print
      } else {
        setState(() {
          userMap = null;
          isLoading = false;
        });
        _logger.w('No user found with email: ${_search.text}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _logger.e('Error during search: $e');
    }
  }

  Future<void> onAddMembers() async {
    if (userMap == null) return;

    final updatedMembersList = List<Map<String, dynamic>>.from(widget.membersList)..add(userMap!);

    try {
      await _firestore.collection('groups').doc(widget.groupChatId).update({
        "members": updatedMembersList,
      });

      await _firestore
          .collection('users')
          .doc(userMap!['uid'])
          .collection('groups')
          .doc(widget.groupChatId)
          .set({"name": widget.name, "id": widget.groupChatId});
    } catch (e) {
      _logger.e('Error adding member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Members"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: size.width / 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: size.height / 20),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: "Search",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: size.height / 50),
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ElevatedButton(
                    onPressed: onSearch,
                    child: const Text("Search"),
                  ),
            if (userMap != null)
              ListTile(
                onTap: onAddMembers,
                leading: const Icon(Icons.account_box),
                title: Text(userMap!['name']),
                subtitle: Text(userMap!['email']),
                trailing: const Icon(Icons.add),
              ),
          ],
        ),
      ),
    );
  }
}

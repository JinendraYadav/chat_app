import 'package:chat_app/Group%20Chat/add_members.dart';
import 'package:chat_app/Screen/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart'; // Add this for logging

class GroupInfo extends StatefulWidget {
  final String groupId, groupName;

  const GroupInfo({required this.groupId, required this.groupName, super.key});

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  List<Map<String, dynamic>> membersList = [];
  bool isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('GroupInfo'); // Initialize logger

  @override
  void initState() {
    super.initState();
    getGroupDetails();
  }

  Future<void> getGroupDetails() async {
    try {
      final chatDoc =
          await _firestore.collection('groups').doc(widget.groupId).get();
      if (mounted) {
        setState(() {
          membersList = List<Map<String, dynamic>>.from(chatDoc['members']);
          isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Failed to fetch group details', e);
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading on error
        });
      }
    }
  }

  bool checkAdmin() {
    return membersList.any((element) =>
        element['uid'] == _auth.currentUser?.uid && element['isAdmin'] == true);
  }

  Future<void> removeMembers(int index) async {
    final uid = membersList[index]['uid'];
    if (mounted) {
      setState(() {
        isLoading = true;
        membersList.removeAt(index);
      });
    }

    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        "members": membersList,
      });

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('groups')
          .doc(widget.groupId)
          .delete();

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Failed to remove member', e);
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading on error
        });
      }
    }
  }

  void showDialogBox(int index) {
    if (checkAdmin() && _auth.currentUser?.uid != membersList[index]['uid']) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: ListTile(
              onTap: () => removeMembers(index),
              title: const Text("Remove This Member"),
            ),
          );
        },
      );
    }
  }

  Future<void> onLeaveGroup() async {
    if (!checkAdmin()) {
      setState(() {
        isLoading = true;
      });

      try {
        membersList
            .removeWhere((member) => member['uid'] == _auth.currentUser?.uid);

        await _firestore.collection('groups').doc(widget.groupId).update({
          "members": membersList,
        });

        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('groups')
            .doc(widget.groupId)
            .delete();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      } catch (e) {
        _logger.severe('Failed to leave group', e);
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BackButton(),
                    ),
                    SizedBox(
                      height: size.height / 8,
                      width: size.width / 1.1,
                      child: Row(
                        children: [
                          Container(
                            height: size.height / 11,
                            width: size.height / 11,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                            child: Icon(
                              Icons.group,
                              color: Colors.white,
                              size: size.width / 10,
                            ),
                          ),
                          SizedBox(
                            width: size.width / 20,
                          ),
                          Expanded(
                            child: Text(
                              widget.groupName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: size.width / 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height / 20),
                    SizedBox(
                      width: size.width / 1.1,
                      child: Text(
                        "${membersList.length} Members",
                        style: TextStyle(
                          fontSize: size.width / 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height / 20),
                    if (checkAdmin())
                      ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddMembersINGroup(
                              groupChatId: widget.groupId,
                              name: widget.groupName,
                              membersList: membersList,
                            ),
                          ),
                        ),
                        leading: const Icon(Icons.add),
                        title: Text(
                          "Add Members",
                          style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Flexible(
                      child: ListView.builder(
                        itemCount: membersList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final member = membersList[index];
                          return ListTile(
                            onTap: () => showDialogBox(index),
                            leading: const Icon(Icons.account_circle),
                            title: Text(
                              member['name'],
                              style: TextStyle(
                                fontSize: size.width / 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(member['email']),
                            trailing: Text(member['isAdmin'] ? "Admin" : ""),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      onTap: onLeaveGroup,
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(
                        "Leave Group",
                        style: TextStyle(
                          fontSize: size.width / 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

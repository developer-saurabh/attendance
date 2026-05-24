import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterMessagePage extends StatefulWidget {
  const MasterMessagePage({super.key});

  @override
  State<MasterMessagePage> createState() => _MasterMessagePageState();
}

class _MasterMessagePageState extends State<MasterMessagePage> {

  final TextEditingController messageController =
  TextEditingController();

  List<String> selectedFacultyIds = [];

  bool sendToAll = false;

  Future<void> sendMessage() async {

    final msg = messageController.text.trim();

    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter message'),
        ),
      );
      return;
    }

    try {

      final facultySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'faculty')
          .get();

      List<String> facultyIds = [];

      if (sendToAll) {

        facultyIds = facultySnapshot.docs
            .map((e) => e.id)
            .toList();

      } else {

        facultyIds = selectedFacultyIds;
      }

      for (String facultyId in facultyIds) {

        await FirebaseFirestore.instance
            .collection('faculty_messages')
            .add({
          'facultyId': facultyId,
          'message': msg,
          'createdAt': Timestamp.now(),
          'isRead': false,
        });
      }

      messageController.clear();

      setState(() {
        selectedFacultyIds.clear();
        sendToAll = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Centralised Faculty Messaging",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            CheckboxListTile(
              value: sendToAll,
              title: const Text("Send To All Faculty"),
              onChanged: (value) {
                setState(() {
                  sendToAll = value ?? false;

                  if (sendToAll) {
                    selectedFacultyIds.clear();
                  }
                });
              },
            ),

            const SizedBox(height: 10),

            if (!sendToAll)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'faculty')
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {

                        final data =
                        docs[index].data()
                        as Map<String, dynamic>;

                        final facultyId = docs[index].id;

                        return CheckboxListTile(

                          value: selectedFacultyIds
                              .contains(facultyId),

                          title: Text(
                            data['name'] ?? '',
                          ),

                          subtitle: Text(
                            data['email'] ?? '',
                          ),

                          onChanged: (value) {

                            setState(() {

                              if (value == true) {

                                selectedFacultyIds
                                    .add(facultyId);

                              } else {

                                selectedFacultyIds
                                    .remove(facultyId);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Send Message"),
                onPressed: sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
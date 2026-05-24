import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FacultyMessagesPage extends StatelessWidget {
  const FacultyMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final facultyId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('faculty_messages')
                .where('facultyId', isEqualTo: facultyId)
                .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No Data Found"));
          }

          final docs = snapshot.data!.docs;

          // LOCAL SORTING
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;

            final bData = b.data() as Map<String, dynamic>;

            final aTime = aData['createdAt'] as Timestamp?;

            final bTime = bData['createdAt'] as Timestamp?;

            if (aTime == null || bTime == null) {
              return 0;
            }

            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text("No Messages", style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,

            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final Timestamp? timestamp = data['createdAt'];

              DateTime? date = timestamp?.toDate();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign, color: Colors.indigo),

                          const SizedBox(width: 8),

                          const Text(
                            "Message From Master",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        data['message'] ?? '',

                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.bottomRight,

                        child: Text(
                          date == null
                              ? ''
                              : "${date.day}/${date.month}/${date.year}   ${date.hour}:${date.minute}",

                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

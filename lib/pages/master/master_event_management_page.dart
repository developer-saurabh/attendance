import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterEventManagementPage extends StatelessWidget {
  const MasterEventManagementPage({super.key});

  @override
  Widget build(BuildContext context) {

    final db = FirebaseFirestore.instance;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: db.collection('events')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No Event Proposals"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final d = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(d['title']),
                  subtitle: Text(
                      "Dept: ${d['department']} | Budget: ₹${d['estimatedBudget']}"),
                  trailing: d['status'] == 'pending'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          doc.reference.update({
                            'status': 'approved'
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          doc.reference.update({
                            'status': 'rejected'
                          });
                        },
                      ),
                    ],
                  )
                      : Text(
                    d['status'],
                    style: TextStyle(
                        color: d['status'] == 'approved'
                            ? Colors.green
                            : Colors.red),
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
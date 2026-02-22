import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterDailyDiaryPage extends StatelessWidget {
  const MasterDailyDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('daily_diary')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No diary entries"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d =
            docs[index].data() as Map<String, dynamic>;
            final date =
            (d['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(d['title']),
                subtitle: Text(
                    "${d['facultyName']} | ${d['subjectName']} | ${date.toLocal()}"),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(d['title']),
                        content: Text(d['description']),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
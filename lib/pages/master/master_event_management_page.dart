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
        stream:
            db
                .collection('events')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(d['title']),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dept: ${d['department']}"),
                      Text("📅 ${_formatDate(d['eventDate'])}"),
                      Text("⏰ ${d['eventTime']}"),

                      Row(
                        children: [
                          const Text("Done: "),
                          Switch(
                            value: d['isDone'] ?? false,
                            onChanged: (val) {
                              doc.reference.update({'isDone': val});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  trailing:
                      d['status'] == 'pending'
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  // 🚨 OVERLAP CHECK
                                  final isConflict = await _checkOverlap(d);

                                  if (isConflict) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "⚠️ Event time conflict!",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  doc.reference.update({'status': 'approved'});
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  doc.reference.update({'status': 'rejected'});
                                },
                              ),
                            ],
                          )
                          : Text(d['status']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔥 DATE FORMAT
  String _formatDate(dynamic ts) {
    final d = (ts as Timestamp).toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  // 🚨 OVERLAP CHECK
  Future<bool> _checkOverlap(Map<String, dynamic> current) async {
    final db = FirebaseFirestore.instance;

    final sameDay =
        await db
            .collection('events')
            .where('eventDate', isEqualTo: current['eventDate'])
            .get();

    for (var doc in sameDay.docs) {
      final d = doc.data();

      if (d['eventTime'] == current['eventTime'] && d['status'] == 'approved') {
        return true;
      }
    }

    return false;
  }
}

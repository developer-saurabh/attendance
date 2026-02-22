import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterPurchaseRequestsPage extends StatelessWidget {
  const MasterPurchaseRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('inventory_purchase_requests')
          .orderBy('requestDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final d =
            doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text(
                    "${d['itemName']} (${d['quantity']})"),
                subtitle: Text(
                    "${d['facultyName']} | ${d['priority']} | ${d['status']}"),
                trailing: d['status'] == 'pending'
                    ? PopupMenuButton<String>(
                  onSelected: (val) async {
                    await db
                        .collection(
                        'inventory_purchase_requests')
                        .doc(doc.id)
                        .update({
                      'status': val,
                      'actionDate':
                      Timestamp.now()
                    });
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'approved',
                        child: Text("Approve")),
                    PopupMenuItem(
                        value: 'rejected',
                        child: Text("Reject")),
                    PopupMenuItem(
                        value: 'procured',
                        child: Text("Mark Procured")),
                  ],
                )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
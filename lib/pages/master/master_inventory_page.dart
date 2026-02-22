import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterInventoryPage extends StatefulWidget {
  const MasterInventoryPage({super.key});

  @override
  State<MasterInventoryPage> createState() =>
      _MasterInventoryPageState();
}

class _MasterInventoryPageState
    extends State<MasterInventoryPage> {
  final _nameC = TextEditingController();
  final _categoryC = TextEditingController();
  final _qtyC = TextEditingController();
  final _locationC = TextEditingController();

  final db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "Manage Items"),
              Tab(text: "Requests"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildItemsTab(),
                _buildRequestsTab(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _nameC, decoration: const InputDecoration(labelText: "Item Name"))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _categoryC, decoration: const InputDecoration(labelText: "Category"))),
              const SizedBox(width: 8),
              SizedBox(width: 120, child: TextField(controller: _qtyC, decoration: const InputDecoration(labelText: "Qty"), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _locationC, decoration: const InputDecoration(labelText: "Location"))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  await db.collection('inventory_items').add({
                    'name': _nameC.text,
                    'category': _categoryC.text,
                    'quantity': int.parse(_qtyC.text),
                    'location': _locationC.text,
                    'createdAt': Timestamp.now(),
                  });
                  _nameC.clear();
                  _categoryC.clear();
                  _qtyC.clear();
                  _locationC.clear();
                },
                child: const Text("Add"),
              )
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db.collection('inventory_items').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(d['name']),
                    subtitle: Text("Qty: ${d['quantity']} | ${d['location']}"),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('inventory_requests').orderBy('requestDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final d = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text("${d['itemName']} (${d['quantityRequested']})"),
                subtitle: Text("Faculty: ${d['facultyName']} | Status: ${d['status']}"),
                trailing: d['status'] == 'pending'
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _approveRequest(doc.id, d);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await db.collection('inventory_requests')
                            .doc(doc.id)
                            .update({'status': 'rejected'});
                      },
                    )
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

  Future<void> _approveRequest(String requestId, Map<String, dynamic> data) async {
    final itemRef = db.collection('inventory_items').doc(data['itemId']);
    final itemSnap = await itemRef.get();
    final itemData = itemSnap.data() as Map<String, dynamic>;

    final currentQty = itemData['quantity'];
    final requested = data['quantityRequested'];

    if (currentQty >= requested) {
      await itemRef.update({'quantity': currentQty - requested});
      await db.collection('inventory_requests').doc(requestId).update({
        'status': 'approved',
        'approvedDate': Timestamp.now(),
      });
    }
  }
}
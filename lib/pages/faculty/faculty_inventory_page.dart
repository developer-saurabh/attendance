import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FacultyInventoryPage extends StatefulWidget {
  const FacultyInventoryPage({super.key});

  @override
  State<FacultyInventoryPage> createState() =>
      _FacultyInventoryPageState();
}

class _FacultyInventoryPageState
    extends State<FacultyInventoryPage> {

  final db = FirebaseFirestore.instance;
  final _qtyC = TextEditingController();
  String? _selectedItemId;
  String? _selectedItemName;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('inventory_items').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final items = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Item"),
                items: items.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text("${d['name']} (Qty: ${d['quantity']})"),
                  );
                }).toList(),
                onChanged: (val) {
                  final doc = items.firstWhere((e) => e.id == val);
                  final d = doc.data() as Map<String, dynamic>;
                  setState(() {
                    _selectedItemId = val;
                    _selectedItemName = d['name'];
                  });
                },
              );
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _qtyC,
            decoration: const InputDecoration(labelText: "Quantity"),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () async {
              if (_selectedItemId == null) return;

              await db.collection('inventory_requests').add({
                'itemId': _selectedItemId,
                'itemName': _selectedItemName,
                'facultyId': user.uid,
                'facultyName': user.email,
                'quantityRequested': int.parse(_qtyC.text),
                'status': 'pending',
                'requestDate': Timestamp.now(),
              });

              _qtyC.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Request Sent")),
              );
            },
            child: const Text("Request Item"),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('inventory_requests')
                  .where('facultyId', isEqualTo: user.uid)
                  .snapshots(), // removed orderBy
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No requests found"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d =
                    docs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                          "${d['itemName']} (${d['quantityRequested']})"),
                      subtitle: Text("Status: ${d['status']}"),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
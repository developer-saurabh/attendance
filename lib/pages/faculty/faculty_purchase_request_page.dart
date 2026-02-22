import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FacultyPurchaseRequestPage extends StatefulWidget {
  const FacultyPurchaseRequestPage({super.key});

  @override
  State<FacultyPurchaseRequestPage> createState() =>
      _FacultyPurchaseRequestPageState();
}

class _FacultyPurchaseRequestPageState
    extends State<FacultyPurchaseRequestPage> {

  final _itemNameC = TextEditingController();
  final _qtyC = TextEditingController();
  final _justificationC = TextEditingController();

  String _category = "Lab Equipment";
  String _priority = "Medium";

  final db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          TextField(
            controller: _itemNameC,
            decoration: const InputDecoration(
              labelText: "Item Name",
            ),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
                labelText: "Category"),
            items: const [
              DropdownMenuItem(
                  value: "Lab Equipment",
                  child: Text("Lab Equipment")),
              DropdownMenuItem(
                  value: "Stationery",
                  child: Text("Stationery")),
              DropdownMenuItem(
                  value: "IT Equipment",
                  child: Text("IT Equipment")),
            ],
            onChanged: (val) =>
                setState(() => _category = val!),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _qtyC,
            keyboardType: TextInputType.number,
            decoration:
            const InputDecoration(labelText: "Quantity"),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _priority,
            decoration:
            const InputDecoration(labelText: "Priority"),
            items: const [
              DropdownMenuItem(
                  value: "Low", child: Text("Low")),
              DropdownMenuItem(
                  value: "Medium", child: Text("Medium")),
              DropdownMenuItem(
                  value: "High", child: Text("High")),
            ],
            onChanged: (val) =>
                setState(() => _priority = val!),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _justificationC,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: "Justification"),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () async {
              if (_itemNameC.text.isEmpty ||
                  _qtyC.text.isEmpty) return;

              await db
                  .collection('inventory_purchase_requests')
                  .add({
                'facultyId': user.uid,
                'facultyName': user.email,
                'itemName': _itemNameC.text,
                'category': _category,
                'quantity':
                int.parse(_qtyC.text),
                'justification':
                _justificationC.text,
                'priority': _priority,
                'status': 'pending',
                'requestDate':
                Timestamp.now(),
              });

              _itemNameC.clear();
              _qtyC.clear();
              _justificationC.clear();

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                    content:
                    Text("Purchase Request Sent")),
              );
            },
            child: const Text("Submit Request"),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection(
                  'inventory_purchase_requests')
                  .where('facultyId',
                  isEqualTo: user.uid)
                  .orderBy('requestDate',
                  descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No purchase requests yet"),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data()
                    as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(
                            "${d['itemName']} (${d['quantity']})"),
                        subtitle: Text(
                            "Priority: ${d['priority']} | Status: ${d['status']}"),
                      ),
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
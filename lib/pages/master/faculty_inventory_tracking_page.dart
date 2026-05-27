import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FacultyInventoryTrackingPage extends StatefulWidget {
  const FacultyInventoryTrackingPage({super.key});

  @override
  State<FacultyInventoryTrackingPage> createState() =>
      _FacultyInventoryTrackingPageState();
}

class _FacultyInventoryTrackingPageState
    extends State<FacultyInventoryTrackingPage> {
  final db = FirebaseFirestore.instance;

  String? selectedFacultyId;
  String? selectedItemId;

  final qtyC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// FACULTY DROPDOWN
        StreamBuilder<QuerySnapshot>(
          stream: db
              .collection('users')
              .where('role', isEqualTo: 'faculty')
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();

            return DropdownButtonFormField<String>(
              hint: const Text("Select Faculty"),
              items: snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;

                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(d['name'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedFacultyId = val;
                });
              },
            );
          },
        ),

        const SizedBox(height: 10),

        /// ITEM DROPDOWN
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('inventory_items').snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();

            return DropdownButtonFormField<String>(
              hint: const Text("Select Item"),
              items: snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;

                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(
                    "${d['name']} (${d['itemCode'] ?? ''})",
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedItemId = val;
                });
              },
            );
          },
        ),

        const SizedBox(height: 10),

        /// QTY
        TextField(
          controller: qtyC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Assign Quantity",
          ),
        ),

        const SizedBox(height: 10),

        /// ASSIGN BUTTON
        ElevatedButton(
          onPressed: () async {
            try {
              if (selectedFacultyId == null ||
                  selectedItemId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Select faculty & item"),
                  ),
                );
                return;
              }

              final qty = int.tryParse(qtyC.text) ?? 0;

              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Enter valid quantity"),
                  ),
                );
                return;
              }

              final facultySnap = await db
                  .collection('users')
                  .doc(selectedFacultyId)
                  .get();

              final itemSnap = await db
                  .collection('inventory_items')
                  .doc(selectedItemId)
                  .get();

              final faculty =
                  facultySnap.data() as Map<String, dynamic>;

              final item =
                  itemSnap.data() as Map<String, dynamic>;

              final currentStock =
                  (item['quantity'] ?? 0) as int;

              if (currentStock < qty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Not enough stock"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              /// UPDATE STOCK
              await db
                  .collection('inventory_items')
                  .doc(selectedItemId)
                  .update({
                'quantity': currentStock - qty,
              });

              /// SAVE ASSIGNMENT
              await db.collection('faculty_inventory').add({
                'facultyId': selectedFacultyId,
                'facultyName': faculty['name'],
                'itemId': selectedItemId,
                'itemName': item['name'],
                'itemCode': item['itemCode'],
                'quantityAssigned': qty,
                'assignedDate': Timestamp.now(),
              });

              qtyC.clear();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text("Inventory assigned successfully"),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error: $e"),
                ),
              );
            }
          },
          child: const Text("Assign Inventory"),
        ),

        const SizedBox(height: 20),

        /// ASSIGNED INVENTORY LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('faculty_inventory')
                .orderBy('assignedDate', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snap.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No inventory assigned"),
                );
              }

              return ListView(
                children: snap.data!.docs.map((doc) {
                  final d =
                      doc.data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.inventory_2),
                      title: Text(
                        "${d['itemName']} (${d['itemCode']})",
                      ),
                      subtitle: Text(
                        "Faculty: ${d['facultyName']}\nQty: ${d['quantityAssigned']}",
                      ),
                      trailing: Text(
                        d['assignedDate'] != null
                            ? (d['assignedDate']
                                    as Timestamp)
                                .toDate()
                                .toString()
                                .split(' ')[0]
                            : '',
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
import 'package:attendance/pages/master/inventory_dashboard.dart';
import 'package:attendance/pages/master/inventory_reports_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterInventoryPage extends StatefulWidget {
  const MasterInventoryPage({super.key});

  @override
  State<MasterInventoryPage> createState() => _MasterInventoryPageState();
}

class _MasterInventoryPageState extends State<MasterInventoryPage> {
  final db = FirebaseFirestore.instance;

  final _nameC = TextEditingController();
  final _qtyC = TextEditingController();
  final _minQtyC = TextEditingController();

  final _purchaseQtyC = TextEditingController();
  final _costC = TextEditingController();
  final _billNoC = TextEditingController();

  String? selectedItemId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "Dashboard"),
              Tab(text: "Items"),
              Tab(text: "Purchase"),
              Tab(text: "Requests"),
              Tab(text: "Reports"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const InventoryDashboard(),
                _itemsTab(),
                _purchaseTab(),
                _requestsTab(),
                const InventoryReportsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ITEMS =================
  Widget _itemsTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: "Item Name"),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _qtyC,
                decoration: const InputDecoration(labelText: "Qty"),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _minQtyC,
                decoration: const InputDecoration(labelText: "Min Qty"),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await db.collection('inventory_items').add({
                  'name': _nameC.text,
                  'quantity': int.parse(_qtyC.text),
                  'minQty': int.parse(_minQtyC.text),
                });
              },
              child: const Text("Add"),
            ),
          ],
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db.collection('inventory_items').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();

              return ListView(
                children:
                    snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final qty = (d['quantity'] ?? 0) as int;
                      final minQty = (d['minQty'] ?? 0) as int;

                      final isLow = qty <= minQty;
                      return ListTile(
                        title: Text((d['name'] ?? "Unnamed Item").toString()),
                        subtitle: Text("Stock: ${d['quantity']}"),
                        trailing:
                            isLow
                                ? const Icon(Icons.warning, color: Colors.red)
                                : null,
                      );
                    }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= PURCHASE =================
  Widget _purchaseTab() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('inventory_items').snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();

            return DropdownButtonFormField<String>(
              hint: const Text("Select Item"),
              items:
                  snap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(d['name']),
                    );
                  }).toList(),
              onChanged: (val) => selectedItemId = val,
            );
          },
        ),

        TextField(
          controller: _purchaseQtyC,
          decoration: const InputDecoration(labelText: "Purchase Qty"),
        ),
        TextField(
          controller: _costC,
          decoration: const InputDecoration(labelText: "Cost"),
        ),
        TextField(
          controller: _billNoC,
          decoration: const InputDecoration(labelText: "Bill No"),
        ),

        ElevatedButton(
          onPressed: () async {
            try {
              print("---- PURCHASE START ----");

              if (selectedItemId == null) {
                print("❌ No item selected");
                return;
              }

              print("Selected Item ID: $selectedItemId");

              final itemRef = db
                  .collection('inventory_items')
                  .doc(selectedItemId);

              final snap = await itemRef.get();

              if (!snap.exists) {
                print("❌ Item does not exist in DB");
                return;
              }

              final data = snap.data();
              print("Raw Firestore Data: $data");

              final currentQty = (data?['quantity'] ?? 0);
              print("Current Quantity: $currentQty");

              final purchaseQty = int.tryParse(_purchaseQtyC.text) ?? 0;
              print("Entered Purchase Qty: $purchaseQty");

              final newQty = currentQty + purchaseQty;
              print("New Quantity: $newQty");

              // update stock
              await itemRef.update({'quantity': newQty});
              print("✅ Stock Updated");

              // add purchase record
              await db.collection('inventory_purchases').add({
                'itemId': selectedItemId,
                'quantity': purchaseQty,
                'cost': _costC.text,
                'billNo': _billNoC.text,
                'date': Timestamp.now(),
              });

              print("✅ Purchase Record Added");

              print("---- PURCHASE END ----");
            } catch (e, stack) {
              print("🔥 ERROR: $e");
              print(stack);
            }
          },
          child: const Text("Add Purchase"),
        ),
      ],
    );
  }

  // ================= REQUESTS =================
  Widget _requestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('inventory_requests').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();

        return ListView(
          children:
              snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text("${d['itemName']} (${d['quantityRequested']})"),
                  trailing: ElevatedButton(
                    child: const Text("Approve"),
                    onPressed: () async {
                      final itemRef = db
                          .collection('inventory_items')
                          .doc(d['itemId']);
                      final item = await itemRef.get();

                      final current = (item['quantity'] ?? 0) as int;
                      final req = (d['quantityRequested'] ?? 0) as int;

                      if (current >= req) {
                        await itemRef.update({'quantity': current - req});

                        await db.collection('inventory_consumption').add({
                          'itemId': d['itemId'],
                          'facultyId': d['facultyId'],
                          'quantity': req,
                          'date': Timestamp.now(),
                        });

                        await doc.reference.update({'status': 'approved'});
                      }
                    },
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

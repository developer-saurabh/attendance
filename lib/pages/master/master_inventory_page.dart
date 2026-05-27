import 'package:attendance/pages/master/inventory_dashboard.dart';
import 'package:attendance/pages/master/inventory_reports_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterInventoryPage extends StatefulWidget {
  const MasterInventoryPage({super.key});

  @override
  State<MasterInventoryPage> createState() => _MasterInventoryPageState();
}

class _MasterInventoryPageState extends State<MasterInventoryPage>
    with TickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  DateTime? selectedBillDate;
  final _nameC = TextEditingController();
  final _qtyC = TextEditingController();
  final _minQtyC = TextEditingController();

  final _purchaseQtyC = TextEditingController();
  final _costC = TextEditingController();
  final _billNoC = TextEditingController();

  final _vendorNameC = TextEditingController();
  final _cityC = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _clearForms();
      }
    });
  }

  void _clearForms() {
    _nameC.clear();
    _qtyC.clear();
    _minQtyC.clear();
    _purchaseQtyC.clear();
    _costC.clear();
    _billNoC.clear();

    _vendorNameC.clear(); // NEW
    _cityC.clear(); // NEW

    selectedItemId = null;
  }

  @override
  void dispose() {
    _tabController.dispose();

    _nameC.dispose();
    _qtyC.dispose();
    _minQtyC.dispose();
    _purchaseQtyC.dispose();
    _costC.dispose();
    _billNoC.dispose();

    super.dispose();
  }

  String? selectedItemId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Dashboard"),
            Tab(text: "Items"),
            Tab(text: "Purchase"),
            Tab(text: "Requests"),
            Tab(text: "Reports"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Qty"),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _minQtyC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Min Qty"),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameC.text.trim().toLowerCase();
                final qty = int.tryParse(_qtyC.text) ?? 0;
                final minQty = int.tryParse(_minQtyC.text) ?? 0;

                if (name.isEmpty || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Enter valid item & quantity"),
                    ),
                  );
                  return;
                }

                try {
                  // 🔍 Check if item already exists
                  final existing =
                      await db
                          .collection('inventory_items')
                          .where('name', isEqualTo: name)
                          .get();

                  if (existing.docs.isNotEmpty) {
                    // 🔥 UPDATE EXISTING ITEM
                    final doc = existing.docs.first;
                    final currentQty = (doc['quantity'] ?? 0) as int;

                    await doc.reference.update({
                      'quantity': currentQty + qty,
                      'minQty': minQty,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Quantity updated to existing item"),
                      ),
                    );
                  } else {
                    // 🔥 CREATE NEW ITEM WITH CODE
                    final itemCode =
                        "ITM-${DateTime.now().millisecondsSinceEpoch}";

                    await db.collection('inventory_items').add({
                      'name': name,
                      'quantity': qty,
                      'minQty': minQty,
                      'itemCode': itemCode,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ New item added")),
                    );
                  }

                  // 🔄 clear form
                  _nameC.clear();
                  _qtyC.clear();
                  _minQtyC.clear();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Error adding item")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db.collection('inventory_items').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();

              if (snap.data!.docs.isEmpty) {
                return const Center(child: Text("No items found"));
              }

              return ListView(
                children:
                    snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final qty = (d['quantity'] ?? 0) as int;
                      final minQty = (d['minQty'] ?? 0) as int;
                      final isLow = qty <= minQty;

                      return Card(
                        child: ListTile(
                          title: Text(
                            "${d['name']} (${d['itemCode'] ?? 'No Code'})",
                          ),
                          subtitle: Text("Stock: $qty | Min: $minQty"),
                          leading:
                              isLow
                                  ? const Icon(Icons.warning, color: Colors.red)
                                  : const Icon(Icons.inventory),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await doc.reference.delete();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("🗑 Item deleted"),
                                  ),
                                );
                              }
                            },
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

  // ================= PURCHASE =================
  Widget _purchaseTab() {
    return Column(
      children: [
        // 🔽 ITEM DROPDOWN WITH CODE
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
                      child: Text(
                        "${d['name']} (${d['itemCode'] ?? 'No Code'})",
                      ),
                    );
                  }).toList(),
              onChanged: (val) => selectedItemId = val,
            );
          },
        ),

        // 🔽 PURCHASE QTY
        TextField(
          controller: _purchaseQtyC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Purchase Qty"),
        ),

        // 🔽 COST
        TextField(
          controller: _costC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Cost"),
        ),

        // 🔽 BILL NUMBER
        TextField(
          controller: _billNoC,
          decoration: const InputDecoration(labelText: "Bill Number"),
        ),

        // 🔽 VENDOR / SHOP NAME
        TextField(
          controller: _vendorNameC,
          decoration: const InputDecoration(labelText: "Vendor / Shop Name"),
        ),

        // 🔽 CITY
        TextField(
          controller: _cityC,
          decoration: const InputDecoration(labelText: "Purchase City"),
        ),

        // 🔽 BILL DATE PICKER
        Row(
          children: [
            Expanded(
              child: Text(
                selectedBillDate == null
                    ? "Select Bill Date"
                    : "Bill Date: ${selectedBillDate!.toLocal().toString().split(' ')[0]}",
              ),
            ),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() => selectedBillDate = picked);
                }
              },
              child: const Text("Pick Date"),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔥 ADD PURCHASE BUTTON
        ElevatedButton(
          onPressed: () async {
            try {
              if (selectedItemId == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("❌ Select item")));
                return;
              }

              final purchaseQty = int.tryParse(_purchaseQtyC.text) ?? 0;

              if (purchaseQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Enter valid quantity")),
                );
                return;
              }

              final itemRef = db
                  .collection('inventory_items')
                  .doc(selectedItemId);

              final snap = await itemRef.get();
              final data = snap.data();

              final currentQty = (data?['quantity'] ?? 0) as int;
              final itemCode = data?['itemCode'] ?? 'NA';
              final itemName = data?['name'] ?? '';

              final newQty = currentQty + purchaseQty;

              // ✅ update stock
              await itemRef.update({'quantity': newQty});

              // ✅ add purchase record
              await db.collection('inventory_purchases').add({
                'itemId': selectedItemId,
                'itemName': itemName,
                'itemCode': itemCode, // 🔥 added
                'quantity': purchaseQty,
                'cost': _costC.text,
                'billNo': _billNoC.text,
                // NEW FIELDS
                'vendorName': _vendorNameC.text.trim(),
                'purchaseCity': _cityC.text.trim(),

                'billDate':
                    selectedBillDate != null
                        ? Timestamp.fromDate(selectedBillDate!)
                        : Timestamp.now(),
                'createdAt': Timestamp.now(),
              });

              // ✅ success message
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Purchase Added Successfully"),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              // 🔄 clear form
              _purchaseQtyC.clear();
              _costC.clear();
              _billNoC.clear();
              setState(() {
                selectedItemId = null;
                selectedBillDate = null;
              });
            } catch (e) {
              print("Purchase Error: $e");

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Something went wrong"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
      stream:
          db
              .collection('inventory_requests')
              .where('status', isNotEqualTo: 'approved') // 🔥 hide approved
              .snapshots(),
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
                      try {
                        final itemRef = db
                            .collection('inventory_items')
                            .doc(d['itemId']);

                        final item = await itemRef.get();

                        final current = (item['quantity'] ?? 0) as int;
                        final req = (d['quantityRequested'] ?? 0) as int;

                        if (current >= req) {
                          // ✅ update stock
                          await itemRef.update({'quantity': current - req});

                          // ✅ add consumption log
                          await db.collection('inventory_consumption').add({
                            'itemId': d['itemId'],
                            'facultyId': d['facultyId'],
                            'quantity': req,
                            'date': Timestamp.now(),
                          });

                          // ✅ mark approved
                          await doc.reference.update({'status': 'approved'});

                          // 🔥 UI FEEDBACK
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "✅ Request Approved Successfully",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          // ❌ Not enough stock
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("❌ Not enough stock"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print("Approve Error: $e");

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("❌ Something went wrong"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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

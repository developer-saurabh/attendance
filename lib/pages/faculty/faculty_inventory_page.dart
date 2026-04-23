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
    extends State<FacultyInventoryPage>
    with TickerProviderStateMixin {

  final db = FirebaseFirestore.instance;

  final _qtyC = TextEditingController();
  final _deptC = TextEditingController();
  final _locationC = TextEditingController();

  String? _selectedItemId;
  String? _selectedItemName;
  String? _selectedItemCode;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qtyC.dispose();
    _deptC.dispose();
    _locationC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Inventory"),
              Tab(text: "Report"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [

                // ================= INVENTORY TAB =================
                Column(
                  children: [

                    StreamBuilder<QuerySnapshot>(
                      stream: db.collection('inventory_items').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final items = snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: "Select Item"),
                          items: items.map((doc) {
                            final d =
                                doc.data() as Map<String, dynamic>;

                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                  "${d['name']} (${d['itemCode'] ?? ''}) | Qty: ${d['quantity']}"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final doc =
                                items.firstWhere((e) => e.id == val);
                            final d =
                                doc.data() as Map<String, dynamic>;

                            setState(() {
                              _selectedItemId = val;
                              _selectedItemName = d['name'];
                              _selectedItemCode = d['itemCode'];
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // PRODUCT CODE (READ ONLY)
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Product Code",
                        hintText: _selectedItemCode ?? "Auto",
                      ),
                    ),

                    TextField(
                      controller: _deptC,
                      decoration: const InputDecoration(
                          labelText: "Department"),
                    ),

                    TextField(
                      controller: _locationC,
                      decoration: const InputDecoration(
                          labelText: "Location"),
                    ),

                    TextField(
                      controller: _qtyC,
                      decoration:
                          const InputDecoration(labelText: "Quantity"),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: () async {
                        if (_selectedItemId == null ||
                            _qtyC.text.isEmpty) return;

                        await db.collection('inventory_requests').add({
                          'itemId': _selectedItemId,
                          'itemName': _selectedItemName,
                          'itemCode': _selectedItemCode,
                          'facultyId': user.uid,
                          'facultyName': user.email,
                          'department': _deptC.text,
                          'location': _locationC.text,
                          'quantityRequested':
                              int.parse(_qtyC.text),
                          'status': 'pending',
                          'requestDate': Timestamp.now(),
                        });

                        _qtyC.clear();
                        _deptC.clear();
                        _locationC.clear();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("✅ Request Sent")),
                          );
                        }
                      },
                      child: const Text("Request Item"),
                    ),
                  ],
                ),

                // ================= REPORT TAB =================
                StreamBuilder<QuerySnapshot>(
                  stream: db
                      .collection('inventory_requests')
                      .where('facultyId', isEqualTo: user.uid)
                      .orderBy('requestDate', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text("Error: ${snapshot.error}"));
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text("No requests found"));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final d = docs[index].data()
                            as Map<String, dynamic>;

                        final date = (d['requestDate']
                                as Timestamp)
                            .toDate();

                        return Card(
                          child: ListTile(
                            title: Text(
                                "${d['itemName']} (${d['itemCode'] ?? ''})"),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Qty: ${d['quantityRequested']}"),
                                Text(
                                    "Dept: ${d['department'] ?? ''}"),
                                Text(
                                    "Location: ${d['location'] ?? ''}"),
                                Text(
                                    "Date: ${date.day}/${date.month}/${date.year}"),
                                Text(
                                    "Status: ${d['status']}"),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
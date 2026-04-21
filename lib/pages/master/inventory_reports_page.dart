import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'inventory_graph.dart';
import 'inventory_pdf.dart';

class InventoryReportsPage extends StatelessWidget {
  const InventoryReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: "Purchase"), Tab(text: "Consumption")]),

          ElevatedButton(
            onPressed: generateInventoryPdf,
            child: const Text("Download PDF"),
          ),

          const SizedBox(height: 10),

          const SizedBox(height: 250, child: InventoryGraph()),

          Expanded(
            child: TabBarView(
              children: [
                // PURCHASE REPORT
                StreamBuilder<QuerySnapshot>(
                  stream:
                      db
                          .collection('inventory_purchases')
                          .orderBy('date', descending: true)
                          .snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();

                    return ListView(
                      children:
                          snap.data!.docs.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;

                            return ListTile(
                              title: Text("Qty: ${d['quantity']}"),
                              subtitle: Text("Bill: ${d['billNo']}"),
                            );
                          }).toList(),
                    );
                  },
                ),

                // CONSUMPTION REPORT
                StreamBuilder<QuerySnapshot>(
                  stream:
                      db
                          .collection('inventory_consumption')
                          .orderBy('date', descending: true)
                          .snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();

                    return ListView(
                      children:
                          snap.data!.docs.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;

                            return ListTile(
                              title: Text(
                                "${d['itemName'] ?? 'Item'} (${d['quantity']})",
                              ),
                              subtitle: Text(
                                "Faculty: ${d['facultyName'] ?? 'Unknown'}",
                              ),
                            );
                          }).toList(),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventoryDashboard extends StatelessWidget {
  const InventoryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('inventory_items').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        int totalItems = docs.length;
        int totalStock = 0;
        int lowStock = 0;

        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final qty = (d['quantity'] ?? 0) as int;
          final minQty = (d['minQty'] ?? 0) as int;

          totalStock += qty;
          if (qty <= minQty) lowStock++;
        }

        return Column(
          children: [
            Row(
              children: [
                _card("Items", totalItems.toString(), Colors.blue),
                _card("Stock", totalStock.toString(), Colors.green),
                _card("Low Stock", lowStock.toString(), Colors.red),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final qty = (d['quantity'] ?? 0) as int;
                  final minQty = (d['minQty'] ?? 0) as int;

                  return ListTile(
                    title: Text((d['name'] ?? "Unnamed").toString()),
                    subtitle: Text("Stock: $qty"),
                    trailing: qty <= minQty
                        ? const Icon(Icons.warning, color: Colors.red)
                        : null,
                  );
                }).toList(),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _card(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
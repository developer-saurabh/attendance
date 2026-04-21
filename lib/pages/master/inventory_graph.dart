import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InventoryGraph extends StatelessWidget {
  const InventoryGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('inventory_purchases').snapshots(),
      builder: (context, purchaseSnap) {
        if (!purchaseSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('inventory_consumption').snapshots(),
          builder: (context, consumeSnap) {
            if (!consumeSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final purchaseDocs = purchaseSnap.data!.docs;
            final consumeDocs = consumeSnap.data!.docs;

            // simple monthly aggregation (last 6 entries)
            List<FlSpot> purchaseSpots = [];
            List<FlSpot> consumeSpots = [];

            for (int i = 0; i < purchaseDocs.length; i++) {
              final d = purchaseDocs[i].data() as Map<String, dynamic>;
              final qty = (d['quantity'] ?? 0) as int;
              purchaseSpots.add(FlSpot(i.toDouble(), qty.toDouble()));
            }

            for (int i = 0; i < consumeDocs.length; i++) {
              final d = consumeDocs[i].data() as Map<String, dynamic>;
              final qty = (d['quantity'] ?? 0) as int;
              consumeSpots.add(FlSpot(i.toDouble(), qty.toDouble()));
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: purchaseSpots,
                      isCurved: true,
                    ),
                    LineChartBarData(
                      spots: consumeSpots,
                      isCurved: true,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
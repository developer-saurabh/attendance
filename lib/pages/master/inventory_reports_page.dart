import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'inventory_pdf.dart';

class InventoryReportsPage extends StatefulWidget {
  const InventoryReportsPage({super.key});

  @override
  State<InventoryReportsPage> createState() =>
      _InventoryReportsPageState();
}

class _InventoryReportsPageState
    extends State<InventoryReportsPage> {
  final db = FirebaseFirestore.instance;

  DateTimeRange? selectedRange;

  Future<Map<String, dynamic>> _loadAnalytics() async {
    final items =
        await db.collection('inventory_items').get();

    final purchases =
        await db.collection('inventory_purchases').get();

    final consumption =
        await db.collection('inventory_consumption').get();

    int totalItems = items.docs.length;
    int totalStock = 0;
    int totalPurchaseQty = 0;
    int totalConsumptionQty = 0;

    for (var d in items.docs) {
      totalStock +=
          ((d.data()['quantity'] ?? 0) as num).toInt();
    }

    for (var d in purchases.docs) {
      final data = d.data();

      final qty =
          ((data['quantity'] ?? 0) as num).toInt();

      final ts = data['billDate'];

      if (_isWithinRange(ts)) {
        totalPurchaseQty += qty;
      }
    }

    for (var d in consumption.docs) {
      final data = d.data();

      final qty =
          ((data['quantity'] ?? 0) as num).toInt();

      final ts = data['date'];

      if (_isWithinRange(ts)) {
        totalConsumptionQty += qty;
      }
    }

    return {
      'totalItems': totalItems,
      'totalStock': totalStock,
      'totalPurchaseQty': totalPurchaseQty,
      'totalConsumptionQty': totalConsumptionQty,
    };
  }

  bool _isWithinRange(dynamic timestamp) {
    if (selectedRange == null) return true;

    if (timestamp == null) return false;

    final date = (timestamp as Timestamp).toDate();

    return date.isAfter(
          selectedRange!.start.subtract(
            const Duration(days: 1),
          ),
        ) &&
        date.isBefore(
          selectedRange!.end.add(
            const Duration(days: 1),
          ),
        );
  }

  Widget analyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [

          /// TABS
          const TabBar(
            tabs: [
              Tab(text: "Purchase"),
              Tab(text: "Consumption"),
            ],
          ),

          /// EVERYTHING SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.all(10),
                child: Column(
                  children: [

                    /// FILTER + PDF
                    Row(
                      children: [

                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.date_range,
                          ),
                          label: const Text(
                            "Date Filter",
                          ),
                          onPressed: () async {
                            final picked =
                                await showDateRangePicker(
                              context: context,
                              firstDate:
                                  DateTime(2020),
                              lastDate:
                                  DateTime.now(),
                            );

                            if (picked != null) {
                              setState(() {
                                selectedRange =
                                    picked;
                              });
                            }
                          },
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            selectedRange == null
                                ? "All Dates"
                                : "${selectedRange!.start.toString().split(' ')[0]}"
                                    " → "
                                    "${selectedRange!.end.toString().split(' ')[0]}",
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed:
                              generateInventoryPdf,
                          icon: const Icon(
                            Icons.picture_as_pdf,
                          ),
                          label:
                              const Text("PDF"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// ANALYTICS
                    FutureBuilder<
                        Map<String, dynamic>>(
                      future: _loadAnalytics(),
                      builder: (_, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        }

                        final data = snap.data!;

                        return GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          children: [

                            analyticsCard(
                              "Total Items",
                              "${data['totalItems']}",
                              Icons.inventory,
                              Colors.blue,
                            ),

                            analyticsCard(
                              "Current Stock",
                              "${data['totalStock']}",
                              Icons.warehouse,
                              Colors.green,
                            ),

                            analyticsCard(
                              "Purchased Qty",
                              "${data['totalPurchaseQty']}",
                              Icons.shopping_cart,
                              Colors.orange,
                            ),

                            analyticsCard(
                              "Consumed Qty",
                              "${data['totalConsumptionQty']}",
                              Icons.bar_chart,
                              Colors.red,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    /// FIXED HEIGHT TAB VIEW
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        children: [

                          /// PURCHASE REPORT
                          StreamBuilder<
                              QuerySnapshot>(
                            stream: db
                                .collection(
                                    'inventory_purchases')
                                .orderBy(
                                  'billDate',
                                  descending: true,
                                )
                                .snapshots(),
                            builder: (_, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              }

                              final docs =
                                  snap.data!.docs
                                      .where(
                                          (doc) {
                                final data =
                                    doc.data()
                                        as Map<
                                            String,
                                            dynamic>;

                                return _isWithinRange(
                                  data[
                                      'billDate'],
                                );
                              }).toList();

                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No purchase data",
                                  ),
                                );
                              }

                              return ListView
                                  .builder(
                                itemCount:
                                    docs.length,
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final d = docs[
                                              index]
                                          .data()
                                      as Map<
                                          String,
                                          dynamic>;

                                  return Card(
                                    child:
                                        ListTile(
                                      leading:
                                          const Icon(
                                        Icons
                                            .shopping_cart,
                                        color: Colors
                                            .green,
                                      ),

                                      title:
                                          Text(
                                        "${d['itemName'] ?? 'Item'} (${d['quantity']})",
                                      ),

                                      subtitle:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [

                                          Text(
                                            "Bill: ${d['billNo'] ?? ''}",
                                          ),

                                          Text(
                                            "Vendor: ${d['vendorName'] ?? 'N/A'}",
                                          ),

                                          Text(
                                            "City: ${d['purchaseCity'] ?? 'N/A'}",
                                          ),

                                          Text(
                                            "Cost: ${d['cost'] ?? ''}",
                                          ),
                                        ],
                                      ),

                                      trailing:
                                          Text(
                                        d['billDate'] !=
                                                null
                                            ? (d['billDate']
                                                    as Timestamp)
                                                .toDate()
                                                .toString()
                                                .split(
                                                    ' ')[0]
                                            : '',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          /// CONSUMPTION REPORT
                          StreamBuilder<
                              QuerySnapshot>(
                            stream: db
                                .collection(
                                    'inventory_consumption')
                                .orderBy(
                                  'date',
                                  descending: true,
                                )
                                .snapshots(),
                            builder: (_, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              }

                              final docs =
                                  snap.data!.docs
                                      .where(
                                          (doc) {
                                final data =
                                    doc.data()
                                        as Map<
                                            String,
                                            dynamic>;

                                return _isWithinRange(
                                  data['date'],
                                );
                              }).toList();

                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No usage data",
                                  ),
                                );
                              }

                              return ListView
                                  .builder(
                                itemCount:
                                    docs.length,
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final d = docs[
                                              index]
                                          .data()
                                      as Map<
                                          String,
                                          dynamic>;

                                  return Card(
                                    child:
                                        ListTile(
                                      leading:
                                          const Icon(
                                        Icons
                                            .person,
                                        color: Colors
                                            .red,
                                      ),

                                      title:
                                          Text(
                                        "${d['itemName'] ?? 'Item'} (${d['quantity']})",
                                      ),

                                      subtitle:
                                          Text(
                                        "Faculty: ${d['facultyName'] ?? 'Unknown'}",
                                      ),

                                      trailing:
                                          Text(
                                        d['date'] !=
                                                null
                                            ? (d['date']
                                                    as Timestamp)
                                                .toDate()
                                                .toString()
                                                .split(
                                                    ' ')[0]
                                            : '',
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
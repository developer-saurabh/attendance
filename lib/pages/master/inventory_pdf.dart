import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateInventoryPdf() async {
  final db = FirebaseFirestore.instance;

  final items = await db.collection('inventory_items').get();
  final purchases = await db.collection('inventory_purchases').get();
  final consumption = await db.collection('inventory_consumption').get();

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Inventory Report", style: pw.TextStyle(fontSize: 20)),

            pw.SizedBox(height: 20),

            pw.Text("Items"),
            ...items.docs.map((doc) {
              final d = doc.data();
              return pw.Text(
                  "${d['name']} - Qty: ${d['quantity'] ?? 0}");
            }),

            pw.SizedBox(height: 20),

            pw.Text("Purchases"),
            ...purchases.docs.map((doc) {
              final d = doc.data();
              return pw.Text(
                  "Qty: ${d['quantity']} | Bill: ${d['billNo']}");
            }),

            pw.SizedBox(height: 20),

            pw.Text("Consumption"),
            ...consumption.docs.map((doc) {
              final d = doc.data();
              return pw.Text(
                  "${d['itemName']} - ${d['quantity']} by ${d['facultyName']}");
            }),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}
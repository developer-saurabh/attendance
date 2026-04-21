// daily_diary_analytics_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DailyDiaryAnalyticsPage extends StatefulWidget {
  const DailyDiaryAnalyticsPage({super.key});

  @override
  State<DailyDiaryAnalyticsPage> createState() =>
      _DailyDiaryAnalyticsPageState();
}

class _DailyDiaryAnalyticsPageState extends State<DailyDiaryAnalyticsPage> {
  String? subjectId;
  String? subjectName;

  int view = 0; // 0 = daily, 1 = weekly, 2 = monthly

  double total = 0;
  List<FlSpot> spots = [];

  Future<void> loadData() async {
    if (subjectId == null) return;

    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;

    DateTime start;
    DateTime end;

    final now = DateTime.now();

    if (view == 0) {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (view == 1) {
      start = now.subtract(const Duration(days: 7));
      end = now;
    } else {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    }

    final snapshot =
        await db
            .collection('daily_diary')
            .where('facultyId', isEqualTo: user.uid)
            .where('subjectId', isEqualTo: subjectId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .orderBy('date')
            .get();

    double sum = 0;
    List<FlSpot> tempSpots = [];

    int index = 0;

    for (var doc in snapshot.docs) {
      final d = doc.data();
      final val = (d['percentageCovered'] ?? 0).toDouble();

      sum += val;
      tempSpots.add(FlSpot(index.toDouble(), val));
      index++;
    }

    setState(() {
      total = sum;
      spots = tempSpots;
    });
  }

  Future<void> generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              children: [
                pw.Text(
                  "Daily Diary Report",
                  style: pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Subject: ${subjectName ?? ''}"),
                pw.Text("Total Coverage: ${total.toStringAsFixed(1)}%"),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Diary Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// SUBJECT
            StreamBuilder<DocumentSnapshot>(
              stream: db.collection('users').doc(user.uid).snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();

                final assigned = List<String>.from(
                  (userSnap.data!.data() as Map)['assignedSubjects'] ?? [],
                );

                if (assigned.isEmpty) {
                  return const Text("No subjects assigned");
                }

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      db
                          .collection('subjects')
                          .where(FieldPath.documentId, whereIn: assigned)
                          .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox();

                    final subjects = snap.data!.docs;

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Subject"),
                      items:
                          subjects.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(d['name']),
                            );
                          }).toList(),
                      onChanged: (v) {
                        final doc = subjects.firstWhere((e) => e.id == v);
                        final d = doc.data() as Map<String, dynamic>;

                        setState(() {
                          subjectId = v;
                          subjectName = d['name'];
                        });

                        loadData();
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            /// VIEW SELECTOR
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text("Daily")),
                ButtonSegment(value: 1, label: Text("Weekly")),
                ButtonSegment(value: 2, label: Text("Monthly")),
              ],
              selected: {view},
              onSelectionChanged: (v) {
                setState(() => view = v.first);
                loadData();
              },
            ),

            const SizedBox(height: 20),

            /// TOTAL
            Text(
              "${total.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(value: (total / 100).clamp(0, 1)),

            const SizedBox(height: 20),

            /// GRAPH
            Expanded(
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(spots: spots, isCurved: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// PDF BUTTON
            ElevatedButton(
              onPressed: generatePDF,
              child: const Text("Download Report (PDF)"),
            ),
          ],
        ),
      ),
    );
  }
}

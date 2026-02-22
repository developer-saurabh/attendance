import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() =>
      _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState
    extends State<AttendanceAnalyticsPage> {
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          /// SUBJECT DROPDOWN
          StreamBuilder<DocumentSnapshot>(
            stream: db.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final data =
              userSnap.data!.data() as Map<String, dynamic>?;

              if (data == null) {
                return const Text("User data not found");
              }

              final assigned =
              List<String>.from(data['assignedSubjects'] ?? []);

              if (assigned.isEmpty) {
                return const Text(
                  "No subjects assigned.",
                  style: TextStyle(color: Colors.red),
                );
              }

              final limited =
              assigned.length > 10 ? assigned.sublist(0, 10) : assigned;

              return StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('subjects')
                    .where(FieldPath.documentId, whereIn: limited)
                    .snapshots(),
                builder: (context, subjectSnap) {
                  if (!subjectSnap.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final subjects = subjectSnap.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                        labelText: "Select Subject"),
                    items: subjects.map((doc) {
                      final d =
                      doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(d['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSubjectId = val);
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          if (_selectedSubjectId != null)
            Expanded(child: _buildAnalytics(_selectedSubjectId!)),
        ],
      ),
    );
  }

  Widget _buildAnalytics(String subjectId) {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('attendance_sessions')
          .where('facultyId', isEqualTo: user.uid)
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!.docs;

        if (sessions.isEmpty) {
          return const Center(
              child: Text("No attendance history"));
        }

        Map<String, int> presentCount = {};
        Map<String, int> totalCount = {};
        Map<String, int> monthlyCount = {};

        for (var doc in sessions) {
          final data = doc.data() as Map<String, dynamic>;

          final date =
          (data['date'] as Timestamp).toDate();
          final monthKey =
              "${date.year}-${date.month.toString().padLeft(2, '0')}";

          monthlyCount[monthKey] =
              (monthlyCount[monthKey] ?? 0) + 1;

          final presence =
          Map<String, dynamic>.from(data['studentPresence']);

          presence.forEach((studentId, isPresent) {
            totalCount[studentId] =
                (totalCount[studentId] ?? 0) + 1;

            if (isPresent == true) {
              presentCount[studentId] =
                  (presentCount[studentId] ?? 0) + 1;
            }
          });
        }

        final rows = totalCount.keys.map((studentId) {
          final total = totalCount[studentId]!;
          final present = presentCount[studentId] ?? 0;
          final percent =
          ((present / total) * 100).toStringAsFixed(1);

          return {
            'studentId': studentId,
            'present': present,
            'total': total,
            'percent': percent,
          };
        }).toList();

        return Column(
          children: [
            /// MONTHLY BREAKDOWN
            Wrap(
              spacing: 10,
              children: monthlyCount.entries.map((e) {
                return Chip(
                  label:
                  Text("${e.key} → ${e.value} classes"),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            /// GRAPH
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: rows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final percent =
                    double.parse(entry.value['percent'] as String);
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: percent)
                    ]);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// EXPORT PDF
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Export PDF"),
              onPressed: () => _exportPDF(rows),
            ),

            const SizedBox(height: 20),

            /// DATA TABLE
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Student ID")),
                    DataColumn(label: Text("Present")),
                    DataColumn(label: Text("Total")),
                    DataColumn(label: Text("Attendance %")),
                  ],
                  rows: rows.map((r) {
                    final percent =
                    double.parse(r['percent'] as String);

                    return DataRow(
                      onSelectChanged: (_) {
                        _showHistoryPopup(
                            context, sessions);
                      },
                      cells: [
                        DataCell(
                            Text(r['studentId'].toString())),
                        DataCell(
                            Text(r['present'].toString())),
                        DataCell(
                            Text(r['total'].toString())),
                        DataCell(
                          Text(
                            "${r['percent']}%",
                            style: TextStyle(
                              color: percent < 75
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryPopup(
      BuildContext context, List<QueryDocumentSnapshot> sessions) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Attendance History"),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView(
              children: sessions.map((s) {
                final d =
                (s['date'] as Timestamp).toDate();
                return ListTile(
                  title: Text(
                      "${d.year}-${d.month}-${d.day}"),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportPDF(
      List<Map<String, dynamic>> rows) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Table.fromTextArray(
            headers: [
              "StudentID",
              "Present",
              "Total",
              "Percentage"
            ],
            data: rows.map((r) {
              final studentId = r['studentId']?.toString() ?? '';
              final present = r['present']?.toString() ?? '0';
              final total = r['total']?.toString() ?? '0';
              final percent = r['percent']?.toString() ?? '0';

              return [
                studentId,
                present,
                total,
                percent
              ];
            }).toList(),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  } }
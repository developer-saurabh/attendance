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
                return const CircularProgressIndicator();
              }

              final userData =
              userSnap.data!.data() as Map<String, dynamic>;

              final assigned =
              List<String>.from(userData['assignedSubjects'] ?? []);

              if (assigned.isEmpty) {
                return const Text("No subjects assigned");
              }

              return StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('subjects')
                    .where(FieldPath.documentId, whereIn: assigned)
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
                        child: Text(d['name']),
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
          .snapshots(),
      builder: (context, attendanceSnap) {

        if (!attendanceSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = attendanceSnap.data!.docs;

        if (sessions.isEmpty) {
          return const Center(child: Text("No attendance data"));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('students').snapshots(),
          builder: (context, studentSnap) {

            if (!studentSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final studentDocs = studentSnap.data!.docs;

            Map<String, String> studentNameMap = {};
            for (var doc in studentDocs) {
              final data = doc.data() as Map<String, dynamic>;
              studentNameMap[doc.id] = data['name'] ?? "Unknown";
            }

            Map<String, int> presentCount = {};
            int totalSessions = sessions.length;

            for (var doc in sessions) {
              final data = doc.data() as Map<String, dynamic>;
              final map =
              Map<String, dynamic>.from(data['studentPresence']);

              map.forEach((studentId, present) {
                presentCount.putIfAbsent(studentId, () => 0);
                if (present == true) {
                  presentCount[studentId] =
                      presentCount[studentId]! + 1;
                }
              });
            }

            List<Map<String, dynamic>> analytics = [];

            int below75 = 0;
            int above75 = 0;

            presentCount.forEach((studentId, present) {
              double percent =
                  (present / totalSessions) * 100;

              if (percent < 75) {
                below75++;
              } else {
                above75++;
              }

              analytics.add({
                "studentId": studentId,
                "studentName":
                studentNameMap[studentId] ?? "Unknown",
                "present": present,
                "total": totalSessions,
                "percent": percent.toStringAsFixed(1)
              });
            });

            return _buildAnalyticsUI(
                analytics,
                totalSessions,
                above75,
                below75);
          },
        );
      },
    );
  }

  /// FULL UI SECTION
  Widget _buildAnalyticsUI(
      List<Map<String, dynamic>> analytics,
      int totalSessions,
      int above75,
      int below75) {

    return SingleChildScrollView(
      child: Column(
        children: [

          /// SUMMARY CARD
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Total Sessions: $totalSessions"),
                  Text("Above 75%: $above75"),
                  Text("Below 75%: $below75",
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// PIE CHART
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: above75.toDouble(),
                    title: "Above 75%",
                    color: Colors.green,
                  ),
                  PieChartSectionData(
                    value: below75.toDouble(),
                    title: "Below 75%",
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// BAR CHART
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barGroups: analytics
                    .asMap()
                    .entries
                    .map((e) {
                  final index = e.key;
                  final percent =
                  double.parse(e.value['percent']);

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percent,
                        color: percent < 75
                            ? Colors.red
                            : Colors.green,
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// TABLE
          DataTable(
            columns: const [
              DataColumn(label: Text("Student")),
              DataColumn(label: Text("Present")),
              DataColumn(label: Text("Total")),
              DataColumn(label: Text("%")),
            ],
            rows: analytics.map((row) {
              final percent =
              double.parse(row['percent']);

              return DataRow(
                color: percent < 75
                    ? MaterialStateProperty.all(
                    Colors.red.shade100)
                    : null,
                cells: [
                  DataCell(Text(row['studentName'])),
                  DataCell(Text(row['present'].toString())),
                  DataCell(Text(row['total'].toString())),
                  DataCell(Text(row['percent'])),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () => _exportPDF(analytics),
            child: const Text("Export PDF"),
          ),
        ],
      ),
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
              "Student Name",
              "Present",
              "Total",
              "Percentage"
            ],
            data: rows.map((r) {
              return [
                r['studentName'],
                r['present'].toString(),
                r['total'].toString(),
                r['percent'],
              ];
            }).toList(),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
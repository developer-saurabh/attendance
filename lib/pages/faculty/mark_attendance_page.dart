import 'package:attendance/widgets/pp_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_text_field.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final _sectionC = TextEditingController(text: 'A');

  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _presence = {};

  String? _selectedSubjectId;
  Map<String, dynamic>? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    final svc = FirestoreService.instance;

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
                return const Text(
                  "No subjects assigned by master.",
                  style: TextStyle(color: Colors.red),
                );
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
                      labelText: "Select Subject",
                    ),
                    items: subjects.map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                            "${data['name']} (Y${data['year']} - S${data['semester']})"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final doc =
                          subjects.firstWhere((e) => e.id == val);
                      setState(() {
                        _selectedSubjectId = val;
                        _selectedSubject =
                            doc.data() as Map<String, dynamic>;
                      });
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),

          if (_selectedSubject == null)
            const Text("Please select a subject first.")
          else
            Expanded(
              child: _buildStudentTable(
                svc,
                user.uid,
                _selectedSubject!['year'],
                _selectedSubject!['semester'],
                _sectionC.text,
              ),
            ),

          const SizedBox(height: 12),

          if (_selectedSubject != null)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  await svc.markAttendance(
                    facultyId: user.uid,
                    year: _selectedSubject!['year'],
                    semester: _selectedSubject!['semester'],
                    section: _sectionC.text,
                    date: _selectedDate,
                    studentPresence: _presence,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Attendance saved')),
                    );
                  }
                },
                child: const Text("Save Attendance"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentTable(
    FirestoreService svc,
    String facultyId,
    int year,
    int sem,
    String section,
  ) {
    return StreamBuilder<List<Student>>(
      stream: svc.studentsStream(
        facultyId: facultyId,
        year: year,
        semester: sem,
        section: section,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data!;
        if (students.isEmpty) {
          return const Center(child: Text("No students found"));
        }

        for (final s in students) {
          _presence.putIfAbsent(s.id, () => true);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Present")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Roll No")),
            ],
            rows: students.map((s) {
              return DataRow(
                cells: [
                  DataCell(
                    Checkbox(
                      value: _presence[s.id] ?? true,
                      onChanged: (v) {
                        setState(() {
                          _presence[s.id] = v ?? false;
                        });
                      },
                    ),
                  ),
                  DataCell(Text(s.name)),
                  DataCell(Text(s.rollNo)),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
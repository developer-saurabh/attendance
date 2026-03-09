import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageSubjectsPage extends StatefulWidget {
  const ManageSubjectsPage({super.key});

  @override
  State<ManageSubjectsPage> createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  final _nameC = TextEditingController();
  final _yearC = TextEditingController();
  final _semesterC = TextEditingController();
  bool _loading = false;
  String? _msg;

  final db = FirebaseFirestore.instance;

  int? _selectedSemester; // 🔹 FILTER SEMESTER

  Future<void> _createSubject() async {
    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      await db.collection('subjects').add({
        'name': _nameC.text.trim(),
        'year': int.parse(_yearC.text.trim()),
        'semester': int.parse(_semesterC.text.trim()),
      });

      _msg = "Subject created successfully";

      _nameC.clear();
      _yearC.clear();
      _semesterC.clear();
    } catch (e) {
      _msg = "Error: $e";
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _assignSubject(String facultyId, String subjectId) async {
    await db.collection('users').doc(facultyId).update({
      'assignedSubjects': FieldValue.arrayUnion([subjectId])
    });
  }

  Future<void> _revokeSubject(String facultyId, String subjectId) async {
    await db.collection('users').doc(facultyId).update({
      'assignedSubjects': FieldValue.arrayRemove([subjectId])
    });
  }

  Stream<QuerySnapshot> _subjectStream() {
    if (_selectedSemester == null) {
      return db.collection('subjects').snapshots();
    }

    return db
        .collection('subjects')
        .where('semester', isEqualTo: _selectedSemester)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// LEFT SIDE → CREATE SUBJECT
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Create Subject",
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameC,
                      decoration:
                      const InputDecoration(labelText: "Subject Name"),
                    ),
                    TextField(
                      controller: _yearC,
                      decoration:
                      const InputDecoration(labelText: "Year"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _semesterC,
                      decoration:
                      const InputDecoration(labelText: "Semester"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _createSubject,
                      child: const Text("Create"),
                    ),
                    if (_msg != null) Text(_msg!)
                  ],
                ),
              ),
            ),
          ),
        ),

        /// RIGHT SIDE → ASSIGN SUBJECT
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('users')
                .where('role', isEqualTo: 'faculty')
                .snapshots(),
            builder: (context, facultySnap) {
              if (!facultySnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final facultyDocs = facultySnap.data!.docs;

              return ListView.builder(
                itemCount: facultyDocs.length,
                itemBuilder: (context, index) {
                  final faculty =
                  facultyDocs[index].data() as Map<String, dynamic>;
                  final facultyId = facultyDocs[index].id;
                  final assigned =
                  List<String>.from(faculty['assignedSubjects'] ?? []);

                  return ExpansionTile(
                    title: Text(faculty['name']),
                    subtitle: Text(faculty['email']),
                    children: [

                      /// 🔹 SEMESTER FILTER DROPDOWN
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: DropdownButtonFormField<int?>(
                          value: _selectedSemester,
                          decoration: const InputDecoration(
                            labelText: "Filter by Semester",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text("All Semesters")),
                            DropdownMenuItem(value: 1, child: Text("Semester 1")),
                            DropdownMenuItem(value: 2, child: Text("Semester 2")),
                            DropdownMenuItem(value: 3, child: Text("Semester 3")),
                            DropdownMenuItem(value: 4, child: Text("Semester 4")),
                            DropdownMenuItem(value: 5, child: Text("Semester 5")),
                            DropdownMenuItem(value: 6, child: Text("Semester 6")),
                            DropdownMenuItem(value: 7, child: Text("Semester 7")),
                            DropdownMenuItem(value: 8, child: Text("Semester 8")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSemester = value;
                            });
                          },
                        ),
                      ),

                      /// SUBJECT LIST
                      StreamBuilder<QuerySnapshot>(
                        stream: _subjectStream(),
                        builder: (context, subjectSnap) {
                          if (!subjectSnap.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final subjectDocs = subjectSnap.data!.docs;

                          return Column(
                            children: subjectDocs.map((doc) {
                              final data =
                              doc.data() as Map<String, dynamic>;
                              final subjectId = doc.id;
                              final isAssigned =
                              assigned.contains(subjectId);

                              return ListTile(
                                title: Text(
                                    "${data['name']} (Y${data['year']} - S${data['semester']})"),
                                trailing: isAssigned
                                    ? TextButton(
                                  onPressed: () => _revokeSubject(
                                      facultyId, subjectId),
                                  child: const Text("Revoke",
                                      style: TextStyle(
                                          color: Colors.red)),
                                )
                                    : TextButton(
                                  onPressed: () => _assignSubject(
                                      facultyId, subjectId),
                                  child: const Text("Assign"),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      )
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
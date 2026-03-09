import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FacultyDailyDiaryPage extends StatefulWidget {
  const FacultyDailyDiaryPage({super.key});

  @override
  State<FacultyDailyDiaryPage> createState() =>
      _FacultyDailyDiaryPageState();
}

class _FacultyDailyDiaryPageState
    extends State<FacultyDailyDiaryPage> {
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _sectionC = TextEditingController(text: 'A');

  DateTime _selectedDate = DateTime.now();

  String? _selectedSubjectId;
  String? _selectedSubjectName;

  int? _selectedYear;
  int? _selectedSemester;

  final _yearC = TextEditingController();
  final _semC = TextEditingController();

  List<int> getSemesters(int year) {
    switch (year) {
      case 1:
        return [1, 2];
      case 2:
        return [3, 4];
      case 3:
        return [5, 6];
      case 4:
        return [7, 8];
      default:
        return [1, 2];
    }
  }

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
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                );
              }

              final userData =
              userSnap.data!.data() as Map<String, dynamic>;

              final assigned =
              List<String>.from(userData['assignedSubjects'] ?? []);

              if (assigned.isEmpty) {
                return const Text("No subjects assigned.");
              }

              return StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('subjects')
                    .where(FieldPath.documentId, whereIn: assigned)
                    .snapshots(),
                builder: (context, subjectSnap) {
                  if (!subjectSnap.hasData) {
                    return const Center(
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child:
                        CircularProgressIndicator(strokeWidth: 3),
                      ),
                    );
                  }

                  final subjects = subjectSnap.data!.docs;

                  return DropdownButtonFormField<String>(
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
                      final doc =
                      subjects.firstWhere((e) => e.id == val);

                      final d =
                      doc.data() as Map<String, dynamic>;

                      setState(() {
                        _selectedSubjectId = val;
                        _selectedSubjectName = d['name'];

                        _selectedYear = d['year'];
                        _selectedSemester = d['semester'];

                        _yearC.text = d['year'].toString();
                        _semC.text = d['semester'].toString();
                      });
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12),

          /// YEAR + SEM DROPDOWN
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration:
                  const InputDecoration(labelText: "Year"),
                  items: [1, 2, 3, 4]
                      .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text("Year $y"),
                  ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedYear = v;
                      _selectedSemester =
                          getSemesters(v!).first;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedSemester,
                  decoration:
                  const InputDecoration(labelText: "Semester"),
                  items: _selectedYear == null
                      ? []
                      : getSemesters(_selectedYear!)
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text("Sem $s"),
                  ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedSemester = v;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// TITLE
          TextField(
            controller: _titleC,
            decoration:
            const InputDecoration(labelText: "Title"),
          ),

          const SizedBox(height: 12),

          /// DESCRIPTION
          TextField(
            controller: _descC,
            maxLines: 4,
            decoration:
            const InputDecoration(labelText: "Description"),
          ),

          const SizedBox(height: 12),

          /// SECTION
          TextField(
            controller: _sectionC,
            decoration:
            const InputDecoration(labelText: "Section"),
          ),

          const SizedBox(height: 12),

          /// SAVE BUTTON
          ElevatedButton(
            onPressed: () async {
              if (_selectedSubjectId == null) return;

              await db.collection('daily_diary').add({
                'facultyId': user.uid,
                'facultyName': user.email,
                'subjectId': _selectedSubjectId,
                'subjectName': _selectedSubjectName,
                'year': _selectedYear,
                'semester': _selectedSemester,
                'section': _sectionC.text,
                'date': Timestamp.fromDate(_selectedDate),
                'title': _titleC.text,
                'description': _descC.text,
                'createdAt': Timestamp.now(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Diary Saved")));

              _titleC.clear();
              _descC.clear();
            },
            child: const Text("Save Diary"),
          ),

          const SizedBox(height: 20),

          /// DIARY LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('daily_diary')
                  .where('facultyId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      height: 30,
                      width: 30,
                      child:
                      CircularProgressIndicator(strokeWidth: 3),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No diary entries");
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d =
                    docs[index].data() as Map<String, dynamic>;

                    final date =
                    (d['date'] as Timestamp).toDate();

                    return Card(
                      child: ListTile(
                        title: Text(d['title']),
                        subtitle: Text(
                            "${d['subjectName']} | Y${d['year']} S${d['semester']} | ${date.toLocal()}"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                return const Text("No subjects assigned.");
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
                      final doc = subjects
                          .firstWhere((e) => e.id == val);
                      final d =
                      doc.data() as Map<String, dynamic>;
                      setState(() {
                        _selectedSubjectId = val;
                        _selectedSubjectName = d['name'];
                      });
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _titleC,
            decoration:
            const InputDecoration(labelText: "Title"),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _descC,
            maxLines: 4,
            decoration:
            const InputDecoration(labelText: "Description"),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _sectionC,
            decoration:
            const InputDecoration(labelText: "Section"),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () async {
              if (_selectedSubjectId == null) return;

              await db.collection('daily_diary').add({
                'facultyId': user.uid,
                'facultyName': user.email,
                'subjectId': _selectedSubjectId,
                'subjectName': _selectedSubjectName,
                'year': 0,
                'semester': 0,
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

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('daily_diary')
                  .where('facultyId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
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
                            "${d['subjectName']} | ${date.toLocal()}"),
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
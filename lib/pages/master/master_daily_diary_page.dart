import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterDailyDiaryPage extends StatefulWidget {
  const MasterDailyDiaryPage({super.key});

  @override
  State<MasterDailyDiaryPage> createState() => _MasterDailyDiaryPageState();
}

class _MasterDailyDiaryPageState extends State<MasterDailyDiaryPage> {
  final db = FirebaseFirestore.instance;

  int _view = 0;

  int? year;
  int? semester;
  String? section;

  String? subjectId;
  String? facultyId;

  List<int> semesters(int year) {
    if (year == 1) return [1, 2];
    if (year == 2) return [3, 4];
    if (year == 3) return [5, 6];
    if (year == 4) return [7, 8];
    return [];
  }

  int getYearFromSem(int sem) {
    if (sem <= 2) return 1;
    if (sem <= 4) return 2;
    if (sem <= 6) return 3;
    return 4;
  }

  Query diaryQuery() {
    Query q = db.collection('daily_diary');

    if (_view == 0) {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 1));

      q = q
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }

    if (_view == 1 && subjectId != null) {
      q = q.where('subjectId', isEqualTo: subjectId);
    }

    if (_view == 1 && facultyId != null) {
      q = q.where('facultyId', isEqualTo: facultyId);
    }

    if (_view == 2) {
      if (year != null) q = q.where('year', isEqualTo: year);
      if (semester != null) q = q.where('semester', isEqualTo: semester);
      if (section != null) q = q.where('section', isEqualTo: section);
    }

    return q.orderBy('date', descending: true);
  }

  Widget viewTabs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text("Today")),
          ButtonSegment(value: 1, label: Text("Subject")),
          ButtonSegment(value: 2, label: Text("Class")),
        ],
        selected: {_view},
        onSelectionChanged: (v) {
          setState(() {
            _view = v.first;
          });
        },
      ),
    );
  }

  Widget subjectFilters() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('subjects').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();

        final subjects = snap.data!.docs;

        return Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Subject"),
              items: subjects.map((s) {
                final d = s.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(d['name']),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  subjectId = v;
                  facultyId = null;
                });
              },
            ),

            const SizedBox(height: 12),

            if (subjectId != null)
              StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('users')
                    .where('assignedSubjects', arrayContains: subjectId)
                    .snapshots(),
                builder: (context, facultySnap) {
                  if (!facultySnap.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final facultyDocs = facultySnap.data!.docs;

                  if (facultyDocs.length == 1) {
                    facultyId = facultyDocs.first.id;
                    return Text(
                        "Teacher: ${(facultyDocs.first.data() as Map)['name']}");
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Teacher"),
                    items: facultyDocs.map((f) {
                      final d = f.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: f.id,
                        child: Text(d['name']),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        facultyId = v;
                      });
                    },
                  );
                },
              )
          ],
        );
      },
    );
  }

  Widget classFilters() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: year,
            decoration: const InputDecoration(labelText: "Year"),
            items: const [
              DropdownMenuItem(value: 1, child: Text("Year 1")),
              DropdownMenuItem(value: 2, child: Text("Year 2")),
              DropdownMenuItem(value: 3, child: Text("Year 3")),
              DropdownMenuItem(value: 4, child: Text("Year 4")),
            ],
            onChanged: (v) {
              setState(() {
                year = v;
                semester = null;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: semester,
            decoration: const InputDecoration(labelText: "Semester"),
            items: (year == null ? <int>[] : semesters(year!))
                .map<DropdownMenuItem<int>>(
                  (s) => DropdownMenuItem<int>(
                value: s,
                child: Text("Sem $s"),
              ),
            )
                .toList(),
            onChanged: (v) {
              setState(() {
                semester = v;
                year = getYearFromSem(v!);
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: section,
            decoration: const InputDecoration(labelText: "Section"),
            items: const [
              DropdownMenuItem(value: "A", child: Text("A")),
              DropdownMenuItem(value: "B", child: Text("B")),
              DropdownMenuItem(value: "C", child: Text("C")),
            ],
            onChanged: (v) {
              setState(() {
                section = v;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget diaryCard(Map data) {
    final date = (data['date'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(data['title']),
        subtitle: Text(
            "${data['facultyName']} | ${data['subjectName']}\nY${data['year']} S${data['semester']} Sec ${data['section']}"),
        trailing: Text(
          "${date.day}-${date.month}-${date.year}",
        ),
        onTap: () {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(data['title']),
                content: Text(data['description']),
              ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        viewTabs(),

        Padding(
          padding: const EdgeInsets.all(16),
          child: _view == 1
              ? subjectFilters()
              : _view == 2
              ? classFilters()
              : const SizedBox(),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: diaryQuery().snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text("Firestore index required"));
              }

              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No diary entries"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return diaryCard(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
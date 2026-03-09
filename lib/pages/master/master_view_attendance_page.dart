import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterViewAttendancePage extends StatefulWidget {
  const MasterViewAttendancePage({super.key});

  @override
  State<MasterViewAttendancePage> createState() =>
      _MasterViewAttendancePageState();
}

class _MasterViewAttendancePageState extends State<MasterViewAttendancePage> {

  final db = FirebaseFirestore.instance;

  int? year;
  int? semester;
  String? section;
  String search = "";

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

  Query attendanceQuery() {
    Query q = db.collection('attendance_sessions');

    if (year != null) q = q.where('year', isEqualTo: year);
    if (semester != null) q = q.where('semester', isEqualTo: semester);
    if (section != null) q = q.where('section', isEqualTo: section);

    return q.orderBy('date', descending: true);
  }

  Widget filterBar() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [

            Expanded(
              child: DropdownButtonFormField<int>(
                value: year,
                decoration: const InputDecoration(
                    labelText: "Year",
                    border: OutlineInputBorder()),
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
                decoration: const InputDecoration(
                    labelText: "Semester",
                    border: OutlineInputBorder()),
                items: (year == null ? [] : semesters(year!))
                    .map((s) => DropdownMenuItem<int>(
                  value: s,
                  child: Text("Sem $s"),
                ))
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
                decoration: const InputDecoration(
                    labelText: "Section",
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "A", child: Text("A")),
                  DropdownMenuItem(value: "B", child: Text("B")),
                  DropdownMenuItem(value: "C", child: Text("C")),
                ],
                onChanged: (v) {
                  setState(() => section = v);
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: "Search subject / faculty",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() => search = v.toLowerCase());
                },
              ),
            ),

            const SizedBox(width: 10),

            ElevatedButton(
                onPressed: () {
                  setState(() {
                    year = null;
                    semester = null;
                    section = null;
                    search = "";
                  });
                },
                child: const Text("Reset"))
          ],
        ),
      ),
    );
  }

  Widget attendanceCard(Map data, String subject, String faculty) {

    final date = (data['date'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(

        leading: const Icon(Icons.event_available, color: Colors.green),

        title: Text(subject,
            style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text(
            "Faculty: $faculty\nYear ${data['year']} | Sem ${data['semester']} | Section ${data['section']}"),

        trailing: Text(
          "${date.day}-${date.month}-${date.year}",
          style: const TextStyle(fontSize: 12),
        ),

        onTap: () {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Lecture Details"),
                content: Text(
                    "Subject: $subject\nFaculty: $faculty\nYear ${data['year']} Sem ${data['semester']}\nSection ${data['section']}"),
              ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        filterBar(),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: attendanceQuery().snapshots(),

            builder: (context, snap) {

              if (snap.hasError) {
                return const Center(child: Text("Firestore index required"));
              }

              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No attendance found"));
              }

              return ListView.builder(

                itemCount: docs.length,

                itemBuilder: (context, i) {

                  final data = docs[i].data() as Map;

                  final subjectId = data['subjectId'];
                  final facultyId = data['facultyId'];

                  return FutureBuilder<List<DocumentSnapshot>>(

                    future: Future.wait([
                      db.collection("subjects").doc(subjectId).get(),
                      db.collection("users").doc(facultyId).get()
                    ]),

                    builder: (context, f) {

                      if (!f.hasData) {
                        return const ListTile(title: Text("Loading..."));
                      }

                      final subject =
                          (f.data![0].data() as Map?)?['name'] ?? "Unknown";

                      final faculty =
                          (f.data![1].data() as Map?)?['name'] ?? "Unknown";

                      if (search.isNotEmpty &&
                          !subject.toLowerCase().contains(search) &&
                          !faculty.toLowerCase().contains(search)) {
                        return const SizedBox();
                      }

                      return attendanceCard(data, subject, faculty);
                    },
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
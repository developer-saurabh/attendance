import 'package:attendance/widgets/pp_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_text_field.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final _yearC = TextEditingController(text: '1');
  final _semC = TextEditingController(text: '1');
  final _sectionC = TextEditingController(text: 'A');

  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _presence = {};

  // Filters
  bool _onlyMyStudents = true;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = FirestoreService.instance;

    int year = int.tryParse(_yearC.text) ?? 1;
    int sem = int.tryParse(_semC.text) ?? 1;
    String sec = _sectionC.text;

    final facultyId = _onlyMyStudents ? user.uid : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mark Attendance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _selectedDate.toLocal().toString().split(' ').first,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // filter row
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: AppTextField(controller: _yearC, label: 'Year'),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: AppTextField(controller: _semC, label: 'Semester'),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: AppTextField(
                      controller: _sectionC,
                      label: 'Section',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search name/roll',
                      ),
                      onChanged:
                          (v) =>
                              setState(() => _search = v.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Text('Only my students'),
                      Switch(
                        value: _onlyMyStudents,
                        onChanged: (v) => setState(() => _onlyMyStudents = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // table card
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<List<Student>>(
                  stream: svc.studentsStream(
                    facultyId: facultyId,
                    year: year,
                    semester: sem,
                    section: sec,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    var students = snapshot.data!;
                    if (_search.isNotEmpty) {
                      students =
                          students.where((s) {
                            final q = _search;
                            return s.name.toLowerCase().contains(q) ||
                                s.rollNo.toLowerCase().contains(q);
                          }).toList();
                    }
                    if (students.isEmpty)
                      return const Center(child: Text('No students'));

                    for (final s in students)
                      _presence.putIfAbsent(s.id, () => true);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade50,
                        ),
                        columns: const [
                          DataColumn(label: Text('Present')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Roll No')),
                          DataColumn(label: Text('Year')),
                          DataColumn(label: Text('Sem')),
                          DataColumn(label: Text('Section')),
                        ],
                        rows:
                            students.map((s) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: _presence[s.id] ?? true,
                                      onChanged:
                                          (v) => setState(
                                            () => _presence[s.id] = v ?? false,
                                          ),
                                    ),
                                  ),
                                  DataCell(Text(s.name)),
                                  DataCell(Text(s.rollNo)),
                                  DataCell(Text(s.year.toString())),
                                  DataCell(Text(s.semester.toString())),
                                  DataCell(Text(s.section)),
                                ],
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser!;
                  await svc.markAttendance(
                    facultyId: user.uid,
                    year: year,
                    semester: sem,
                    section: sec,
                    date: _selectedDate,
                    studentPresence: _presence,
                  );
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attendance saved')),
                    );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Save Attendance'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:attendance/widgets/pp_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_text_field.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  final _nameC = TextEditingController();
  final _rollC = TextEditingController();
  final _yearC = TextEditingController(text: '1');
  final _semC = TextEditingController(text: '1');
  final _sectionC = TextEditingController(text: 'A');

  // Filters / UI state
  int _filterYear = 1;
  int _filterSem = 1;
  String _filterSection = 'A';
  bool _showOnlyMyStudents = true;
  String _search = '';

  final svc = FirestoreService.instance;

  @override
  void dispose() {
    _nameC.dispose();
    _rollC.dispose();
    _yearC.dispose();
    _semC.dispose();
    _sectionC.dispose();
    super.dispose();
  }

  Future<void> _openAddStudentDialog(BuildContext ctx) async {
    final user = FirebaseAuth.instance.currentUser!;
    // dialog form controllers
    final nameC = TextEditingController();
    final rollC = TextEditingController();
    final yearC = TextEditingController(text: _yearC.text);
    final semC = TextEditingController(text: _semC.text);
    final sectionC = TextEditingController(text: _sectionC.text);
    String assignedFacultyId = user.uid; // default
    bool addAnother = false;
    bool loading = false;

    // simple helper to show snackbar from dialog
    void showMsg(String msg) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    // stateful dialog so we can update local loading/addAnother
    await showDialog(
      context: ctx,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            Future<void> submit({required bool keepOpen}) async {
              final year = int.tryParse(yearC.text) ?? 1;
              final sem = int.tryParse(semC.text) ?? 1;
              final student = Student(
                id: '',
                name: nameC.text.trim(),
                rollNo: rollC.text.trim(),
                year: year,
                semester: sem,
                section: sectionC.text.trim(),
                facultyId: assignedFacultyId,
              );

              if (student.name.isEmpty || student.rollNo.isEmpty) {
                showMsg('Please provide name and roll number.');
                return;
              }

              try {
                setDialogState(() => loading = true);
                await svc.addStudent(student);
                showMsg('Student added');
                if (!keepOpen) {
                  Navigator.of(dialogCtx).pop();
                } else {
                  // clear fields for next entry
                  nameC.clear();
                  rollC.clear();
                  setDialogState(() => loading = false);
                }
              } catch (e) {
                setDialogState(() => loading = false);
                showMsg('Error adding student: $e');
              }
            }

            return AlertDialog(
              title: const Text('Add Student'),
              content: SizedBox(
                width: 640,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // name + roll
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: nameC,
                              label: 'Student Name',
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 240,
                            child: AppTextField(
                              controller: rollC,
                              label: 'Roll No',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // year/sem/section and faculty assign (option)
                      Row(
                        children: [
                          SizedBox(width: 12, child: const SizedBox()),
                          SizedBox(
                            width: 120,
                            child: AppTextField(
                              controller: yearC,
                              label: 'Year',
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: AppTextField(
                              controller: semC,
                              label: 'Semester',
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: AppTextField(
                              controller: sectionC,
                              label: 'Section',
                            ),
                          ),
                          const SizedBox(width: 12),
                          // assigned faculty (for now only current user; placeholder for master)
                          Expanded(
                            child: TextFormField(
                              initialValue: assignedFacultyId,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Faculty ID (optional)',
                              ),
                              onChanged: (v) => assignedFacultyId = v.trim(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // extra options row
                      Row(
                        children: [
                          Checkbox(
                            value: addAnother,
                            onChanged:
                                (v) => setDialogState(
                                  () => addAnother = v ?? false,
                                ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Add another after saving'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              // placeholder for CSV/bulk import
                              Navigator.of(dialogCtx).pop();
                              showMsg(
                                'Bulk import not implemented (placeholder).',
                              );
                            },
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Import CSV'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      loading ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      loading
                          ? null
                          : () async => await submit(keepOpen: false),
                  child:
                      loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Add & Close'),
                ),
                ElevatedButton(
                  onPressed:
                      loading
                          ? null
                          : () async =>
                              await submit(keepOpen: addAnother || true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child:
                      loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : const Text('Add & Add Another'),
                ),
              ],
            );
          },
        );
      },
    );

    // refresh outer page once dialog is closed so stream UI reflects latest (if not realtime already)
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final facultyId = _showOnlyMyStudents ? user.uid : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // header row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage Students',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Export CSV'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export not implemented yet')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Add Student'),
                onPressed: () => _openAddStudentDialog(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filters row
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  DropdownButton<int>(
                    value: _filterYear,
                    items:
                        List.generate(5, (i) => i + 1)
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text('Year $y'),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _filterYear = v ?? 1),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _filterSem,
                    items:
                        List.generate(8, (i) => i + 1)
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text('Sem $s'),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _filterSem = v ?? 1),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: TextEditingController(text: _filterSection),
                      decoration: const InputDecoration(labelText: 'Section'),
                      onChanged: (v) => setState(() => _filterSection = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search by name or roll no',
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
                        value: _showOnlyMyStudents,
                        onChanged:
                            (v) => setState(() => _showOnlyMyStudents = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Students table area inside a card
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<List<Student>>(
                  stream: svc.studentsStream(
                    facultyId: facultyId,
                    year: _filterYear,
                    semester: _filterSem,
                    section: _filterSection,
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

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 28,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade50,
                        ),
                        columns: const [
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
        ],
      ),
    );
  }
}

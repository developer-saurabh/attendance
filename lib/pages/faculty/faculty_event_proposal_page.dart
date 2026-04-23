import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FacultyEventProposalPage extends StatefulWidget {
  const FacultyEventProposalPage({super.key});

  @override
  State<FacultyEventProposalPage> createState() =>
      _FacultyEventProposalPageState();
}

class _FacultyEventProposalPageState
    extends State<FacultyEventProposalPage> {

  final _titleC = TextEditingController();
  final _venueC = TextEditingController();
  final _descC = TextEditingController();
  final _budgetC = TextEditingController();
  final _deptC = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  final db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          TextField(
            controller: _titleC,
            decoration: const InputDecoration(labelText: "Event Title"),
          ),

          const SizedBox(height: 12),

          // ✅ Department TEXT FIELD (no dropdown)
          TextField(
            controller: _deptC,
            decoration: const InputDecoration(labelText: "Department"),
          ),

          const SizedBox(height: 12),

          // ✅ DATE PICKER
          Row(
            children: [
              Expanded(
                child: Text(
                  "Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: const Text("Pick Date"),
              )
            ],
          ),

          // ✅ TIME PICKER
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedTime == null
                      ? "Select Time"
                      : "Time: ${_selectedTime!.format(context)}",
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                child: const Text("Pick Time"),
              )
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _venueC,
            decoration: const InputDecoration(labelText: "Venue"),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _budgetC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Estimated Budget"),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _descC,
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Description"),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () async {

              if (_titleC.text.isEmpty || _selectedTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fill all required fields")),
                );
                return;
              }

              await db.collection('events').add({
                'title': _titleC.text,
                'department': _deptC.text,
                'proposedBy': user.uid,
                'proposedByName': user.email,
                'eventDate': Timestamp.fromDate(_selectedDate),
                'eventTime': _selectedTime!.format(context),
                'venue': _venueC.text,
                'description': _descC.text,
                'estimatedBudget': int.tryParse(_budgetC.text) ?? 0,
                'status': 'pending',
                'isDone': false,
                'createdAt': Timestamp.now(),
              });

              _titleC.clear();
              _venueC.clear();
              _descC.clear();
              _budgetC.clear();
              _deptC.clear();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Event Proposal Submitted")),
              );
            },
            child: const Text("Submit Proposal"),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('events')
                  .where('proposedBy', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(d['title']),
                        subtitle: Text(
                            "${d['department']} | ${d['eventTime']} | ${d['status']}"),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
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

  String _department = "Computer";
  int _semester = 1;
  DateTime _selectedDate = DateTime.now();

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

          DropdownButtonFormField<String>(
            value: _department,
            decoration: const InputDecoration(labelText: "Department"),
            items: const [
              DropdownMenuItem(value: "Computer", child: Text("Computer")),
              DropdownMenuItem(value: "Mechanical", child: Text("Mechanical")),
              DropdownMenuItem(value: "Civil", child: Text("Civil")),
            ],
            onChanged: (v) => setState(() => _department = v!),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            value: _semester,
            decoration: const InputDecoration(labelText: "Semester"),
            items: List.generate(
                8,
                    (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text("Sem ${index + 1}"))),
            onChanged: (v) => setState(() => _semester = v!),
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

              if (_titleC.text.isEmpty) return;

              await db.collection('events').add({
                'title': _titleC.text,
                'department': _department,
                'semester': _semester,
                'proposedBy': user.uid,
                'proposedByName': user.email,
                'eventDate': Timestamp.fromDate(_selectedDate),
                'venue': _venueC.text,
                'description': _descC.text,
                'estimatedBudget': int.tryParse(_budgetC.text) ?? 0,
                'status': 'pending',
                'remarks': '',
                'createdAt': Timestamp.now(),
              });

              _titleC.clear();
              _venueC.clear();
              _descC.clear();
              _budgetC.clear();

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Event Proposal Submitted")));
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

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Events"));
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
                            "Dept: ${d['department']} | Status: ${d['status']}"),
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
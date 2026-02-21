import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterViewAttendancePage extends StatelessWidget {
  const MasterViewAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('attendance_sessions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading attendance'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No attendance records yet'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            return ListTile(
              title: Text(
                  'Year ${data['year']} Sem ${data['semester']} Sec ${data['section']}'),
              subtitle: Text('Faculty: ${data['facultyId']} | ${date.toLocal()}'),
              onTap: () {
                // You could open detailed records view here
              },
            );
          },
        );
      },
    );
  }
}

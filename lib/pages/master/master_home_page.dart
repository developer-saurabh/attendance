import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'create_faculty_page.dart';
import 'master_daily_diary_page.dart';
import 'master_event_management_page.dart';
import 'master_inventory_page.dart';
import 'master_purchase_requests_page.dart';
import 'master_view_attendance_page.dart';
import 'manage_subjects_page.dart';

class MasterHomePage extends StatefulWidget {
  const MasterHomePage({super.key});

  @override
  State<MasterHomePage> createState() => _MasterHomePageState();
}

class _MasterHomePageState extends State<MasterHomePage> {

  Map<String, dynamic>? selectedFaculty;

  @override
  Widget build(BuildContext context) {

    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),

      body: Row(
        children: [

          /// LEFT NAVIGATION
          NavigationRail(
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Faculty'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment),
                label: Text('Attendance'),
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (index) {},
          ),

          const VerticalDivider(width: 1),

          /// MAIN CONTENT
          Expanded(
            child: DefaultTabController(
              length: 7,
              child: Column(
                children: [

                  const TabBar(
                    tabs: [
                      Tab(text: 'Manage Faculty'),
                      Tab(text: 'View Attendance'),
                      Tab(text: 'Subjects'),
                      Tab(text: 'Daily Diary'),
                      Tab(text: 'Inventory'),
                      Tab(text: 'Inventory Approval'),
                      Tab(text: 'Events'),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [

                        /// TAB 1 → MANAGE FACULTY
                        Column(
                          children: [

                            /// FACULTY INFORMATION CARD
                            if (selectedFaculty != null)
                              Card(
                                margin: const EdgeInsets.all(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      const Text(
                                        "Faculty Information",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),

                                      const SizedBox(height: 10),

                                      Text(
                                          "Name: ${selectedFaculty!['name']}"),

                                      Text(
                                          "Email: ${selectedFaculty!['email']}"),

                                      Text(
                                          "Phone: ${selectedFaculty!['phone'] ?? 'Not added'}"),

                                      const SizedBox(height: 6),

                                      FutureBuilder<QuerySnapshot>(
                                        future: db.collection('subjects').get(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const CircularProgressIndicator();
                                          }

                                          final subjectDocs = snapshot.data!.docs;
                                          final assignedIds =
                                          List<String>.from(selectedFaculty!['assignedSubjects'] ?? []);

                                          final subjectNames = subjectDocs
                                              .where((doc) => assignedIds.contains(doc.id))
                                              .map((doc) => (doc.data() as Map<String, dynamic>)['name'])
                                              .toList();

                                          return Text(
                                            "Subjects: ${subjectNames.isEmpty ? "None assigned" : subjectNames.join(", ")}",
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),

                            /// FACULTY LIST
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: db
                                    .collection('users')
                                    .where('role', isEqualTo: 'faculty')
                                    .snapshots(),
                                builder: (context, snapshot) {

                                  if (snapshot.hasError) {
                                    return const Center(
                                        child: Text(
                                            'Error loading faculty'));
                                  }

                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child:
                                      CircularProgressIndicator(),
                                    );
                                  }

                                  final docs = snapshot.data!.docs;

                                  if (docs.isEmpty) {
                                    return const Center(
                                        child: Text('No faculty found'));
                                  }

                                  return ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {

                                      final data =
                                      docs[index].data()
                                      as Map<String, dynamic>;

                                      return ListTile(
                                        title: Text(
                                            data['name'] ?? 'No name'),

                                        subtitle: Text(
                                            data['email'] ?? ''),

                                        onTap: () {
                                          setState(() {
                                            selectedFaculty = data;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// CREATE FACULTY BUTTON
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label:
                                const Text('Create Faculty'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const CreateFacultyPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        /// TAB 2
                        const MasterViewAttendancePage(),

                        /// TAB 3
                        const ManageSubjectsPage(),

                        /// TAB 4
                        const MasterDailyDiaryPage(),

                        /// TAB 5
                        const MasterInventoryPage(),

                        /// TAB 6
                        const MasterPurchaseRequestsPage(),

                        /// TAB 7
                        const MasterEventManagementPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
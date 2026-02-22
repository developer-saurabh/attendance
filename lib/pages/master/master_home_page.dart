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

class MasterHomePage extends StatelessWidget {
  const MasterHomePage({super.key});

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
            onDestinationSelected: (index) {
              // We’ll just navigate via buttons below in this simple version
            },
          ),
          const VerticalDivider(width: 1),
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
                        // Tab 1: Faculty list + add
                        Column(
                          children: [
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream:
                                    db
                                        .collection('users')
                                        .where('role', isEqualTo: 'faculty')
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Center(
                                      child: Text('Error loading faculty'),
                                    );
                                  }
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final docs = snapshot.data!.docs;
                                  if (docs.isEmpty) {
                                    return const Center(
                                      child: Text('No faculty found'),
                                    );
                                  }
                                  return ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final data =
                                          docs[index].data()
                                              as Map<String, dynamic>;
                                      return ListTile(
                                        title: Text(data['name'] ?? 'No name'),
                                        subtitle: Text(data['email'] ?? ''),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Create Faculty'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreateFacultyPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        // Tab 2: Attendance sessions
                        const MasterViewAttendancePage(),

                        // 3 Subjects
                        const ManageSubjectsPage(),

                        const MasterDailyDiaryPage(),

                        const MasterInventoryPage(),

                        const MasterPurchaseRequestsPage(),
                        const MasterEventManagementPage (),

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

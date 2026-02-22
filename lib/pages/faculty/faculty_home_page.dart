import 'package:attendance/pages/faculty/attendance_analytics_page.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'faculty_event_proposal_page.dart';
import 'faculty_inventory_page.dart';
import 'faculty_purchase_request_page.dart';
import 'manage_students_page.dart';
import 'mark_attendance_page.dart';
import 'faculty_daily_diary_page.dart';

class FacultyHomePage extends StatefulWidget {
  const FacultyHomePage({super.key});

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> {
  int _selectedIndex = 0;

  final _pages = const [
    ManageStudentsPage(),
    MarkAttendancePage(),
    AttendanceAnalyticsPage(),
    FacultyDailyDiaryPage(),
    FacultyInventoryPage(),
    FacultyPurchaseRequestPage(),
    FacultyEventProposalPage (),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryA = Colors.indigo.shade700;
    final primaryB = Colors.pink.shade400;

    return Scaffold(
      // gradient appbar-like top area
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryA, primaryB]),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Faculty Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
                tooltip: 'Logout',
              ),
            ],
          ),
        ),
      ),

      body: Row(
        children: [
          // Left Sidebar
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // profile card
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: primaryB,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Faculty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Manage Attendance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // nav items
                    _NavTile(
                      icon: Icons.group,
                      label: 'Manage Students',
                      selected: _selectedIndex == 0,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    _NavTile(
                      icon: Icons.check_box,
                      label: 'Mark Attendance',
                      selected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),

                    _NavTile(
                      icon: Icons.analytics,
                      label: 'Attendance Analytics',
                      selected: _selectedIndex == 2,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),

                    _NavTile(
                      icon: Icons.book,
                      label: 'Daily Diary',
                      selected: _selectedIndex == 3,
                      onTap: () => setState(() => _selectedIndex = 3),
                    ),

                    _NavTile(
                      icon: Icons.inventory,
                      label: 'Inventory',
                      selected: _selectedIndex == 4,
                      onTap: () => setState(() => _selectedIndex = 4),
                    ),

                    _NavTile(
                      icon: Icons.request_page,
                      label: 'Purchase Request',
                      selected: _selectedIndex == 5,
                      onTap: () => setState(() => _selectedIndex = 5),
                    ),

                    _NavTile(
                      icon: Icons.event_available_sharp,
                      label: 'Event Request',
                      selected: _selectedIndex == 6,
                      onTap: () => setState(() => _selectedIndex = 6),
                    ),

                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Attendance System',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // divider
          Container(width: 1, color: Colors.grey.shade200),

          // content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _pages[_selectedIndex],
              transitionBuilder: (child, anim) {
                return FadeTransition(opacity: anim, child: child);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).primaryColor : Colors.grey[700],
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      dense: true,
      horizontalTitleGap: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

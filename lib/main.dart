import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pages/auth/login_page.dart';
import 'pages/master/master_home_page.dart';
import 'pages/faculty/faculty_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // <-- Put your web config here (from Firebase Console)
    const firebaseOptions = FirebaseOptions(
      apiKey: 'AIzaSyBdgdUnIBT3m_PDFipZkMcliSpwKAkEQvM',
      authDomain: 'attendance-bfb4b.firebaseapp.com',
      projectId: 'attendance-bfb4b',
      // NOTE: storageBucket should normally be "<PROJECT_ID>.appspot.com"
      storageBucket: 'attendance-bfb4b.appspot.com',
      messagingSenderId: '720655354308',
      appId: '1:720655354308:web:d4dfeb9647230f736b3c91',
      // measurementId: 'G-XXXXXXX', // optional
    );

    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    // Mobile (Android / iOS) - use native firebase config files (google-services.json / GoogleService-Info.plist)
    await Firebase.initializeApp();
  }

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Management System',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/master': (_) => const MasterHomePage(),
        '/faculty': (_) => const FacultyHomePage(),
      },
    );
  }
}

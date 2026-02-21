import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== Students =====
  Future<void> addStudent(Student student) async {
    await _db.collection('students').add(student.toMap());
  }

  /// Flexible students stream.
  /// If facultyId is null, returns students across all faculties.
  Stream<List<Student>> studentsStream({
    String? facultyId,
    required int year,
    required int semester,
    required String section,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('students');

    if (facultyId != null && facultyId.isNotEmpty) {
      query = query.where('facultyId', isEqualTo: facultyId);
    }

    if (year != 0) {
      query = query.where('year', isEqualTo: year);
    }

    if (semester != 0) {
      query = query.where('semester', isEqualTo: semester);
    }

    if (section.isNotEmpty) {
      query = query.where('section', isEqualTo: section);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => Student.fromMap(doc.id, doc.data()))
              .toList(),
    );
  }

  // ===== Attendance =====
  Future<void> markAttendance({
    required String facultyId,
    required int year,
    required int semester,
    required String section,
    required DateTime date,
    required Map<String, bool> studentPresence, // studentId -> present?
  }) async {
    final sessionRef = await _db.collection('attendance_sessions').add({
      'facultyId': facultyId,
      'year': year,
      'semester': semester,
      'section': section,
      'date': Timestamp.fromDate(date),
    });

    final batch = _db.batch();

    studentPresence.forEach((studentId, present) {
      final recordRef = sessionRef.collection('records').doc(studentId);
      batch.set(recordRef, {
        'studentId': studentId,
        'present': present,
      }, SetOptions(merge: true));
    });

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> attendanceSessionsStream() {
    return _db
        .collection('attendance_sessions')
        .orderBy('date', descending: true)
        .snapshots();
  }
}

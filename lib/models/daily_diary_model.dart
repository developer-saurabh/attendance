import 'package:cloud_firestore/cloud_firestore.dart';

class DailyDiary {
  final String id;
  final String facultyId;
  final String facultyName;
  final String subjectId;
  final String subjectName;
  final int year;
  final int semester;
  final String section;
  final DateTime date;
  final String title;
  final String description;

  DailyDiary({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.subjectId,
    required this.subjectName,
    required this.year,
    required this.semester,
    required this.section,
    required this.date,
    required this.title,
    required this.description,
  });

  factory DailyDiary.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyDiary(
      id: doc.id,
      facultyId: data['facultyId'],
      facultyName: data['facultyName'],
      subjectId: data['subjectId'],
      subjectName: data['subjectName'],
      year: data['year'],
      semester: data['semester'],
      section: data['section'],
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'],
      description: data['description'],
    );
  }
}
class Student {
  final String id;
  final String name;
  final String rollNo;
  final int year;
  final int semester;
  final String section;
  final String facultyId;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.year,
    required this.semester,
    required this.section,
    required this.facultyId,
  });

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      rollNo: data['rollNo'] ?? '',
      year: data['year'] ?? 1,
      semester: data['semester'] ?? 1,
      section: data['section'] ?? '',
      facultyId: data['facultyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNo': rollNo,
      'year': year,
      'semester': semester,
      'section': section,
      'facultyId': facultyId,
    };
  }
}

class Student {
  final int id;
  final String name;
  final String course;

  Student({required this.id, required this.name, required this.course});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      name: json['name'] as String,
      course: json['course'] as String,
    );
  }
}
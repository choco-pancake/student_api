import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class StudentApi {
  static const baseUrl = 'http://127.0.0.1:8000/api/students';
  static const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<List<Student>> getStudents() async {
    final res = await http.get(Uri.parse(baseUrl), headers: headers);
    if (res.statusCode != 200) throw Exception('Failed to load students (${res.statusCode})');
    final List data = jsonDecode(res.body);
    return data.map((e) => Student.fromJson(e)).toList();
  }

  static Future<void> addStudent(String name, String course) async {
    final res = await http.post(Uri.parse(baseUrl),
        headers: headers, body: jsonEncode({'name': name, 'course': course}));
    if (res.statusCode != 201) throw Exception('Failed to add student (${res.statusCode})');
  }

  static Future<void> updateStudent(int id, String name, String course) async {
    final res = await http.put(Uri.parse('$baseUrl/$id'),
        headers: headers, body: jsonEncode({'name': name, 'course': course}));
    if (res.statusCode != 200) throw Exception('Failed to update student (${res.statusCode})');
  }

  static Future<void> deleteStudent(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/$id'), headers: headers);
    if (res.statusCode != 204) throw Exception('Failed to delete student (${res.statusCode})');
  }
}
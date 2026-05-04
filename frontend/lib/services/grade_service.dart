import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/grade.dart';
import 'api_service.dart';

class GradeService {
  static Future<List<CourseGrade>> getGrades() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/grades'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['grades'] as List<dynamic>? ?? [])
          .map((e) => CourseGrade.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load grades (${response.statusCode})');
  }
}

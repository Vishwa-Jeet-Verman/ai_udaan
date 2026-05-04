import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/download_item.dart';
import 'api_service.dart';

class DownloadService {
  static Future<List<DownloadItem>> getDownloads() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/downloads'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['downloads'] as List<dynamic>? ?? [];
      return list
          .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load downloads (${response.statusCode})');
  }
}

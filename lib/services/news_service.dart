import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const String apiUrl = 'http://10.0.2.2:5001/api/news'; // for Android emulator

  static Future<List<dynamic>> fetchNews() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load news');
    }
  }
}
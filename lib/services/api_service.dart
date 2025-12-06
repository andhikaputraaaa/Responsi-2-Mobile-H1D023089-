import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/inventaris.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth APIs
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<void> logout() async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: headers,
    );
  }

  // Inventaris APIs
  Future<List<Inventaris>> getInventaris() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/inventaris'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> inventarisList = data['data'];
      return inventarisList.map((json) => Inventaris.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load inventaris');
    }
  }

  Future<Map<String, dynamic>> addInventaris(Inventaris inventaris) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/inventaris'),
      headers: headers,
      body: jsonEncode(inventaris.toJson()),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateInventaris(int id, Inventaris inventaris) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/inventaris/$id'),
      headers: headers,
      body: jsonEncode(inventaris.toJson()),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteInventaris(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/inventaris/$id'),
      headers: headers,
    );

    return jsonDecode(response.body);
  }
}
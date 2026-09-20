import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ================= LOGIN =================

  static Future<String> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/investments/api/token/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['access'].toString();
    }

    throw Exception(
      'Login failed: ${response.body}',
    );
  }

  // ================= RESPONSE LIST =================

  static List<dynamic> _listFromResponse(
    String body,
  ) {
    final data = jsonDecode(body);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  // ================= GET OPPORTUNITIES =================

  static Future<List<dynamic>> getOpportunities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/investments/api/'),
    );

    if (response.statusCode == 200) {
      return _listFromResponse(response.body);
    }

    throw Exception(
      'Failed to load opportunities: ${response.body}',
    );
  }

  // ================= MY INVESTMENTS =================

  static Future<List<dynamic>> getMyInvestments(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/investments/api/my-investments/',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return _listFromResponse(response.body);
    }

    throw Exception(
      'Failed to load portfolio: ${response.body}',
    );
  }

  // ================= CREATE INVESTMENT =================

  static Future<Map<String, dynamic>> createInvestment({
    required String token,
    required int opportunityId,
    required int units,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/investments/api/create-investment/',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'opportunity_id': opportunityId,
        'units': units,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error'] ?? 'Investment failed',
    );
  }

  // ================= REFRESH TOKEN =================

  static Future<String> refreshToken(
    String refreshToken,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/investments/api/token/refresh/',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['access'].toString();
    }

    throw Exception(
      'Token refresh failed: ${response.body}',
    );
  }
}
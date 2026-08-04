import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // Base URL supports local Wi-Fi IP (192.168.0.7), Android emulator (10.0.2.2), or custom host
  static String baseUrl = 'http://192.168.0.7:8000/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_access_token');
  }

  static Future<void> saveToken(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_access_token', accessToken);
    await prefs.setString('jwt_refresh_token', refreshToken);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_access_token');
    await prefs.remove('jwt_refresh_token');
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/token/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access'], data['refresh']);
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  static Future<bool> register({
    required String username,
    required String password,
    required String email,
    String firstName = '',
    String lastName = '',
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      if (response.statusCode == 201) {
        return await login(username, password);
      }
    } catch (e) {
      print('Registration error: $e');
    }
    return false;
  }

  static Future<UserModel?> fetchUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/auth/profile/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Fetch user profile error: $e');
    }
    return null;
  }
}

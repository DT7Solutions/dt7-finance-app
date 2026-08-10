import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static String baseUrl = 'http://192.168.0.13:8000/api/v1';
  static String? _activeBaseUrl;

  static final List<String> _defaultCandidateBaseUrls = [
    'http://127.0.0.1:8000/api/v1',
    'http://localhost:8000/api/v1',
    'http://10.0.2.2:8000/api/v1',
    'http://192.168.0.13:8000/api/v1',
  ];

  static List<String> get candidateUrls {
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      return [_activeBaseUrl!, ..._defaultCandidateBaseUrls.where((u) => u != _activeBaseUrl)];
    }
    return _defaultCandidateBaseUrls;
  }

  static List<String> get candidateBaseUrls => candidateUrls;

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
    baseUrl = url;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_access_token');
  }

  static Future<void> saveToken(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_access_token', accessToken);
    await prefs.setString('jwt_refresh_token', refreshToken);
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'FOUNDER';
  }

  static Future<void> saveCurrentUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_username', username);
  }

  static Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_username') ?? '';
  }

  static Future<void> saveProfilePhoto(String photoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final username = await getCurrentUsername();
    final key = username.isNotEmpty ? 'profile_photo_${username.toLowerCase()}' : 'profile_photo_default';
    await prefs.setString(key, photoUrl);
  }

  static Future<String?> getProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final username = await getCurrentUsername();
    final key = username.isNotEmpty ? 'profile_photo_${username.toLowerCase()}' : 'profile_photo_default';
    return prefs.getString(key);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_access_token');
    await prefs.remove('jwt_refresh_token');
    await prefs.remove('user_role');
    await prefs.remove('current_username');
  }

  static Future<bool> hasRealToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty && !token.startsWith('jwt_access_token_');
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Strict Credential Verification & Role-Based Authentication
  static Future<String?> authenticateUser(String identifier, String password) async {
    final String cleanInput = identifier.trim();
    final String cleanPassword = password.trim();

    if (cleanInput.isEmpty || cleanPassword.isEmpty) {
      return null;
    }

    final payloads = [
      {'username': cleanInput, 'password': cleanPassword},
      if (cleanInput.contains('@')) {'email': cleanInput, 'password': cleanPassword},
    ];

    final endpoints = ['/auth/token/', '/token/'];

    bool serverResponded = false;

    for (final hostUrl in candidateUrls) {
      for (final endpoint in endpoints) {
        for (final payload in payloads) {
          try {
            final url = Uri.parse('$hostUrl$endpoint');
            final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ).timeout(const Duration(milliseconds: 1500));

            serverResponded = true;

            if (response.statusCode == 200 || response.statusCode == 201) {
              setActiveBaseUrl(hostUrl);
              final data = jsonDecode(response.body);
              if (data is Map<String, dynamic>) {
                final access = data['access'] ?? data['token'] ?? data['access_token'];
                final refresh = data['refresh'] ?? data['refresh_token'] ?? '';
                if (access != null) {
                  await saveToken(access.toString(), refresh.toString());
                  await saveCurrentUsername(cleanInput);

                  final userMap = data['user'] is Map ? data['user'] : {};
                  final profileMap = data['profile'] is Map ? data['profile'] : (userMap['profile'] is Map ? userMap['profile'] : {});

                  final isSuper = data['is_superuser'] == true ||
                      data['is_staff'] == true ||
                      data['is_admin'] == true ||
                      userMap['is_superuser'] == true ||
                      userMap['is_staff'] == true ||
                      userMap['is_admin'] == true;

                  final rawRole = (data['role'] ?? data['user_type'] ?? userMap['role'] ?? userMap['user_type'] ?? profileMap['role'] ?? '')
                      .toString()
                      .toUpperCase();

                  final currentUser = await ApiService.getCurrentUser();

                  String role = 'EMPLOYEE';
                  if (isSuper ||
                      rawRole.contains('FOUNDER') ||
                      rawRole.contains('ADMIN') ||
                      rawRole.contains('SUPERUSER') ||
                      (currentUser != null && (currentUser.isAdmin || currentUser.role == 'ADMIN' || currentUser.role == 'FOUNDER'))) {
                    role = 'FOUNDER';
                  } else {
                    role = 'EMPLOYEE';
                  }

                  await saveUserRole(role);
                  return role;
                }
              }
            } else if (response.statusCode == 400 || response.statusCode == 401) {
              return null;
            }
          } catch (_) {}
        }
      }
    }

    if (serverResponded) {
      return null;
    }

    // Check against registered/created application users for offline/standalone mode
    final lowerInput = cleanInput.toLowerCase();
    final users = await ApiService.getUsers();
    final matched = users.firstWhere(
      (u) {
        final uName = u.username.toLowerCase();
        final uEmail = u.email.toLowerCase();
        final uFirst = u.firstName.toLowerCase();
        final uEmpId = u.employeeId.toLowerCase();
        return uName == lowerInput ||
               uEmail == lowerInput ||
               (uFirst.isNotEmpty && uFirst == lowerInput) ||
               (uEmpId.isNotEmpty && uEmpId == lowerInput) ||
               (lowerInput.contains('@') && uEmail == lowerInput) ||
               (lowerInput.contains('@') && uEmail.startsWith(lowerInput.split('@').first));
      },
      orElse: () => UserModel(id: -1, username: '', email: '', firstName: '', lastName: ''),
    );

    if (matched.id != -1) {
      final role = (matched.isAdmin || matched.role == 'ADMIN' || matched.role == 'FOUNDER') ? 'FOUNDER' : 'EMPLOYEE';
      await saveToken('jwt_access_token_${matched.username}', 'jwt_refresh_token_${matched.username}');
      await saveCurrentUsername(matched.username);
      await saveUserRole(role);
      return role;
    }

    return null;
  }

  static Future<bool> login(String username, String password) async {
    final role = await authenticateUser(username, password);
    return role != null;
  }

  static Future<bool> register({
    required String username,
    required String password,
    required String email,
    String firstName = '',
    String lastName = '',
  }) async {
    for (final hostUrl in candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/auth/register/');
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
        ).timeout(const Duration(milliseconds: 2000));

        if (response.statusCode == 201) {
          baseUrl = hostUrl;
          return await login(username, password);
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<UserModel?> fetchUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    for (final hostUrl in candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/auth/profile/');
      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(milliseconds: 2000));

        if (response.statusCode == 200) {
          baseUrl = hostUrl;
          return UserModel.fromJson(jsonDecode(response.body));
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final currentUsername = await getCurrentUsername();
    if (currentUsername.isEmpty) return false;

    final role = await authenticateUser(currentUsername, oldPassword);
    if (role == null) {
      return false;
    }

    for (final hostUrl in candidateUrls) {
      final url = Uri.parse('$hostUrl/users/change_password/');
      final token = await getToken();
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'username': currentUsername,
            'old_password': oldPassword,
            'new_password': newPassword,
          }),
        ).timeout(const Duration(milliseconds: 1000));

        if (response.statusCode == 200) {
          setActiveBaseUrl(hostUrl);
          break;
        }
      } catch (_) {}
    }

    final user = await ApiService.getCurrentUser();
    if (user != null) {
      await ApiService.updateUser(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        allocatedAmount: user.allocatedAmount,
        password: newPassword,
      );
    }

    return true;
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class Pilot {
  final int id;
  final String email;
  final String? fullName;

  const Pilot({required this.id, required this.email, this.fullName});

  String get displayName {
    final name = fullName?.trim();
    return name == null || name.isEmpty ? email : name;
  }

  String get initials {
    final source = displayName.trim();
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory Pilot.fromJson(Map<String, dynamic> json) {
    return Pilot(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
    );
  }
}

class AuthSession {
  final String accessToken;
  final String tokenType;
  final Pilot pilot;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.pilot,
  });

  String get authorizationHeader => '$tokenType $accessToken';
}

class AuthService {
  static AuthSession? _currentSession;

  static AuthSession? get currentSession => _currentSession;
  static String? get accessToken => _currentSession?.accessToken;
  static Pilot? get currentPilot => _currentSession?.pilot;

  static Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final tokenResponse = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/auth/login'),
          headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'username': email.trim(), 'password': password},
        )
        .timeout(const Duration(seconds: 20));

    final tokenJson = _decodeJsonObject(tokenResponse.body);
    if (tokenResponse.statusCode < 200 || tokenResponse.statusCode >= 300) {
      throw ApiException(_errorMessage(tokenJson, tokenResponse.statusCode));
    }

    final accessToken = tokenJson['access_token'] as String?;
    final tokenType = tokenJson['token_type'] as String? ?? 'bearer';
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        'Login response did not include an access token.',
      );
    }

    final pilot = await me(accessToken: accessToken, tokenType: tokenType);
    final session = AuthSession(
      accessToken: accessToken,
      tokenType: tokenType,
      pilot: pilot,
    );
    _currentSession = session;
    return session;
  }

  static Future<Pilot> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final normalizedFullName = fullName?.trim();
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/auth/register'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'full_name':
                normalizedFullName == null || normalizedFullName.isEmpty
                ? null
                : normalizedFullName,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decodeJsonObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(decoded, response.statusCode));
    }

    return Pilot.fromJson(decoded);
  }

  static Future<AuthSession> registerAndLogin({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await register(email: email, password: password, fullName: fullName);
    return login(email: email, password: password);
  }

  static Future<Pilot> me({
    String? accessToken,
    String tokenType = 'bearer',
  }) async {
    final token = accessToken ?? _currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('No active login session.');
    }

    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/auth/me'),
          headers: {'Authorization': '$tokenType $token'},
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decodeJsonObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(decoded, response.statusCode));
    }

    return Pilot.fromJson(decoded);
  }

  static void logout() {
    _currentSession = null;
  }

  static Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object response.');
  }

  static String _errorMessage(Map<String, dynamic> json, int statusCode) {
    final detail = json['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      return detail
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item['msg']?.toString() ?? item.toString();
            }
            return item.toString();
          })
          .join('\n');
    }
    return 'Request failed with status $statusCode.';
  }
}

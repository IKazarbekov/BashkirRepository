import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_endpoints.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // 1. Регистрация: POST /user/reg?login=...&password=...&email=...
  Future<Map<String, dynamic>> register({
    required String login,
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.register).replace(
        queryParameters: {
          'login': login,
          'password': password,
          'email': email,
        },
      );

      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
      );

      final data = _decodeResponse(response);

      // Проверяем HTTP 200/201 И поле "status": "ok" в теле ответа
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          _isStatusOk(data)) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': _extractError(data, response.statusCode),
      };
    } catch (e) {
      return {'success': false, 'message': 'Нет связи с сервером: $e'};
    }
  }

  // 2. Авторизация: POST /user/log?login=...&password=...
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.login).replace(
        queryParameters: {
          'login': login,
          'password': password,
        },
      );

      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
      );

      final data = _decodeResponse(response);

      // Проверяем HTTP 200 И "status": "ok" (или наличие токена)
      if (response.statusCode == 200 && _isStatusOk(data)) {
        if (data is Map) {
          final token = data['access_token'] ?? data['token'];
          if (token != null) {
            await _saveToken(token.toString());
          }
        }
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': _extractError(data, response.statusCode),
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка входа: $e'};
    }
  }

  // 3. Текущий пользователь: GET /users/me
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Вы не авторизованы'};
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.currentUser),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': _extractError(data, response.statusCode),
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка профиля: $e'};
    }
  }

  // Проверка, что сервер вернул {"status": "ok"} (или токен)
  bool _isStatusOk(dynamic data) {
    if (data is Map) {
      if (data.containsKey('status')) {
        return data['status'].toString().toLowerCase() == 'ok';
      }
      // На случай, если /user/log возвращает сразу access_token без поля status
      if (data.containsKey('access_token') || data.containsKey('token')) {
        return true;
      }
    }
    return false;
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return {};
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String _extractError(dynamic data, int statusCode) {
    if (data is Map) {
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('status') && data['status'] != 'ok') {
        return data['status'].toString();
      }
    }
    return 'Ошибка сервера ($statusCode)';
  }
}

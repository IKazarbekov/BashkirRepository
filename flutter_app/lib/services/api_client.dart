import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiError implements Exception {
  const ApiError(this.message, [this.status = 0]);
  final String message;
  final int status;

  @override
  String toString() => message;
}

class ApiClient {
  // Chrome and iOS simulator can reach the local server on localhost.
  // Android Emulator uses the special 10.0.2.2 host address. On a physical
  // Android or iPhone, pass --dart-define=API_BASE_URL=https://your-server.
  ApiClient({String? baseUrl})
      : baseUrl = (baseUrl ?? (const String.fromEnvironment('API_BASE_URL').isNotEmpty
          ? const String.fromEnvironment('API_BASE_URL')
          : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000')).replaceAll(RegExp(r'/$'), '');

  final String baseUrl;
  String? token;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authorized = true,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    late http.Response response;
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (authorized && token != null) headers['Authorization'] = 'Bearer $token';
      final uri = Uri.parse('$baseUrl$path');
      final payload = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          response = await http.post(uri, headers: headers, body: payload).timeout(timeout);
        case 'PUT':
          response = await http.put(uri, headers: headers, body: payload).timeout(timeout);
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: payload).timeout(timeout);
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(timeout);
        default:
          throw const ApiError('Неизвестный метод запроса');
      }
    } catch (error) {
      if (error is ApiError) rethrow;
      throw ApiError('Не удаётся связаться с сервером. Запусти backend_api и проверь адрес $baseUrl');
    }
    Map<String, dynamic> result;
    try {
      result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const ApiError('Некорректный ответ сервера');
    }
    if (response.statusCode >= 400) {
      throw ApiError('${result['detail'] ?? 'Ошибка сервера'}', response.statusCode);
    }
    return result;
  }

  Future<String> getText(String path) async {
    if (token == null) throw const ApiError('Сначала войди в аккаунт');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw ApiError('Не удалось получить выгрузку', response.statusCode);
      return utf8.decode(response.bodyBytes);
    } catch (error) {
      if (error is ApiError) rethrow;
      throw const ApiError('Сервер недоступен');
    }
  }

  Future<Map<String, dynamic>> uploadSpeech(int gameId, Uint8List bytes) async {
    if (token == null) throw const ApiError('Сначала войди');
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/extras/games/$gameId/speech'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('audio', bytes,
        filename: 'speech.wav', contentType: MediaType('audio', 'wav')));
      final streamed = await request.send().timeout(const Duration(seconds: 100));
      final response = await http.Response.fromStream(streamed);
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode >= 400) throw ApiError('${result['detail'] ?? 'Ошибка распознавания'}', response.statusCode);
      return result;
    } on ApiError {
      rethrow;
    } catch (_) {
      throw const ApiError('Нет связи с сервером распознавания речи');
    }
  }

  Future<Uint8List> speech(String text, String language, String speaker) async {
    if (token == null) throw const ApiError('Сначала войди в аккаунт');
    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/tts/speak'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'text': text, 'language': language, 'speaker': speaker}),
      ).timeout(const Duration(seconds: 70));
    } catch (_) {
      throw const ApiError('Сервер озвучки недоступен');
    }
    if (response.statusCode != 200) {
      try {
        final message = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        throw ApiError('${message['detail'] ?? 'Ошибка озвучки'}', response.statusCode);
      } on FormatException {
        throw ApiError('Ошибка озвучки: ${response.statusCode}', response.statusCode);
      }
    }
    return response.bodyBytes;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart'; // Ensure this contains your global navigatorKey
import 'token_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android Emulator

  // Central private request sender
  static Future<http.Response> _sendRequest(
      String method,
      String endpoint, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    final token = await TokenService.getToken();

    // Merge standard content headers + Auth Bearer token
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final uri = Uri.parse('$baseUrl$endpoint');
    late http.Response response;

    // Direct the HTTP verb execution
    switch (method.toUpperCase()) {

      case 'GET':
        response = await http.get(uri, headers: requestHeaders);
        break;

      case 'POST':
        response = await http.post(uri, headers: requestHeaders, body: jsonEncode(body));
        break;

      case 'PUT':
        response = await http.put(uri, headers: requestHeaders, body: jsonEncode(body));
        break;

      default:
        throw Exception('HTTP Method $method not supported');
    }

    // 🚨 GLOBAL 401 INTERCEPTOR
    if (response.statusCode == 401) {
      await TokenService.deleteToken();

      // Kick them out to login screen and erase the entire route history stack
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    }

    return response;
  }

  // Exposed clean methods for your app screens to use
  static Future<http.Response> get(String endpoint) => _sendRequest('GET', endpoint);
  static Future<http.Response> post(String endpoint, Object body) => _sendRequest('POST', endpoint, body: body);
  static Future<http.Response> put(String endpoint, Object body) => _sendRequest('PUT', endpoint, body: body);
}
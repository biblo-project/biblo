import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  // Initialize the secure storage manager
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Key name constant to prevent typos
  static const String _tokenKey = "access_token";

  // SAVE the token (Call this inside your Login/Signup screen logic)
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // READ the token (This is what you need for your preferences screen)
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // DELETE the token (Call this when the user logs out)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // NEW: Extracts the logged-in user's id from the stored JWT's "sub" claim.
  // Backend sets this during login:
  // create_access_token(data={"sub": str(user.id)})
  static Future<int?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final decoded = JwtDecoder.decode(token);
      final userIdString = decoded['sub'];
      return int.tryParse(userIdString);
    } catch (e) {
      print("Failed to decode JWT for user id: $e");
      return null;
    }
  }
}
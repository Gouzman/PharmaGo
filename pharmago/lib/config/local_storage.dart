import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  static const storage = FlutterSecureStorage();

  static Future<bool> hasUserData() async {
    final name = await storage.read(key: 'user_name');
    return name != null;
  }

  static Future<void> saveUserData({
    required String name,
    required String country,
    required String city,
    required String district,
  }) async {
    await storage.write(key: 'user_name', value: name);
    await storage.write(key: 'country', value: country);
    await storage.write(key: 'city', value: city);
    await storage.write(key: 'district', value: district);
  }

  static Future<void> clearUserData() async {
    await storage.deleteAll();
  }
}

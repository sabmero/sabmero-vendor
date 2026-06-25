import 'package:shared_preferences/shared_preferences.dart';

// Stores the JWT + basic identity in browser localStorage (via shared_preferences
// on web). Simple and adequate for an internal admin panel.
class TokenStore {
  static const _kToken = 'sabmero_vendor_token';
  static const _kName = 'sabmero_vendor_name';
  static const _kRole = 'sabmero_vendor_role';

  static Future<void> save(String token, String name, String role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kName, name);
    await p.setString(_kRole, role);
  }

  static Future<String?> token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken);
  }

  static Future<String?> name() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kName);
  }

  static Future<String?> role() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRole);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kName);
    await p.remove(_kRole);
  }
}

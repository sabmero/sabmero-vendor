import '../core/api_client.dart';
import '../core/token_store.dart';

// Vendor login. Only the Vendor role may enter this panel.
class AuthService {
  final _api = ApiClient.instance;

  Future<({bool ok, String message})> login(String phone, String password) async {
    final res = await _api.post('/Auth/login', body: {
      'phone': phone,
      'password': password,
    });

    if (!res.ok) {
      return (ok: false, message: res.message ?? 'Login failed.');
    }

    final data = res.data;
    if (data is! Map) {
      return (ok: false, message: 'Unexpected response from server.');
    }

    final token = data['token']?.toString() ?? '';
    final user = (data['user'] as Map?) ?? {};
    final role = user['role']?.toString() ?? '';
    final name = user['fullName']?.toString() ?? 'Vendor';

    if (token.isEmpty) {
      return (ok: false, message: 'No token returned.');
    }
    if (role != 'Vendor') {
      return (
        ok: false,
        message: role == 'Customer'
            ? 'This account is not a vendor yet. Apply and wait for admin approval.'
            : 'This panel is for vendors only. Your role is "$role".'
      );
    }

    await TokenStore.save(token, name, role);
    return (ok: true, message: 'Welcome, $name');
  }

  Future<void> logout() => TokenStore.clear();
}

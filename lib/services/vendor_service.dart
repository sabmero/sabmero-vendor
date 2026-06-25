import '../core/api_client.dart';
import '../models/models.dart';

// Wraps the endpoints a vendor uses: profile, their products (CRUD), orders for
// their products, and payment verification.
class VendorService {
  final _api = ApiClient.instance;

  List<Map<String, dynamic>> _list(dynamic data) =>
      ((data as List?) ?? []).whereType<Map<String, dynamic>>().toList();

  // ── Profile ──
  Future<VendorProfile?> myProfile() async {
    final res = await _api.get('/Vendors/me');
    if (!res.ok || res.data is! Map) return null;
    return VendorProfile.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Products ──
  Future<List<Product>> myProducts() async {
    final res = await _api.get('/Products/mine');
    return _list(res.data).map(Product.fromJson).toList();
  }

  Future<List<CategoryRow>> categories() async {
    final res = await _api.get('/Categories');
    return _list(res.data).map(CategoryRow.fromJson).toList();
  }

  Future<ApiResult> createProduct(Map<String, dynamic> body) =>
      _api.post('/Products', body: body);

  Future<ApiResult> updateProduct(int id, Map<String, dynamic> body) =>
      _api.put('/Products/$id', body: body);

  Future<ApiResult> deleteProduct(int id) => _api.delete('/Products/$id');

  // ── Orders (containing my products) ──
  Future<List<OrderRow>> myOrders() async {
    final res = await _api.get('/Orders/vendor');
    return _list(res.data).map(OrderRow.fromJson).toList();
  }

  // ── Payments to verify ──
  Future<List<PendingPayment>> pendingPayments() async {
    final res = await _api.get('/Payments/pending');
    return _list(res.data).map(PendingPayment.fromJson).toList();
  }

  Future<ApiResult> verifyPayment(int id, bool approved) =>
      _api.post('/Payments/verify', body: {'id': id, 'approved': approved});

  // ── KYC ──
  Future<KycStatus?> kycStatus() async {
    final res = await _api.get('/Auth/kyc-status');
    if (!res.ok || res.data is! Map) return null;
    return KycStatus.fromJson(res.data as Map<String, dynamic>);
  }

  // Upload a KYC document (image/pdf bytes) → returns the saved server path.
  Future<({bool ok, String message, String? path})> uploadKycFile(
      List<int> bytes, String filename) async {
    final res = await _api.uploadBytes('/Uploads/kyc', bytes, filename);
    if (!res.ok) return (ok: false, message: res.message ?? 'Upload failed.', path: null);
    final data = res.data;
    final path = (data is Map) ? data['path']?.toString() : null;
    if (path == null || path.isEmpty) {
      return (ok: false, message: 'Upload succeeded but no path returned.', path: null);
    }
    return (ok: true, message: 'Uploaded.', path: path);
  }

  // Submit a previously-uploaded KYC document path for review.
  Future<ApiResult> submitKyc(String documentPath) =>
      _api.post('/Auth/kyc', body: {'documentPath': documentPath});

  // Upload a product image → returns its server path.
  Future<({bool ok, String message, String? path})> uploadProductImage(
      List<int> bytes, String filename) async {
    final res = await _api.uploadBytes('/Uploads/product', bytes, filename);
    if (!res.ok) return (ok: false, message: res.message ?? 'Upload failed.', path: null);
    final data = res.data;
    final path = (data is Map) ? data['path']?.toString() : null;
    if (path == null || path.isEmpty) {
      return (ok: false, message: 'Upload succeeded but no path returned.', path: null);
    }
    return (ok: true, message: 'Uploaded.', path: path);
  }
}

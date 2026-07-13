import 'package:dio/dio.dart';
import 'app_config.dart';
import 'token_store.dart';

// A thin wrapper over Dio. Adds the JWT to every request and normalizes the
// backend's { success, message, data } envelope into a simple ApiResult.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        // Don't throw on non-2xx — we handle status codes ourselves.
        validateStatus: (_) => true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStore.token();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Future<ApiResult> get(String path, {Map<String, dynamic>? query}) async =>
      _wrap(() => _dio.get(path, queryParameters: query));

  Future<ApiResult> post(String path, {dynamic body}) async =>
      _wrap(() => _dio.post(path, data: body));

  // Multipart upload: field name "file", used by all /Uploads/* endpoints.
  Future<ApiResult> uploadBytes(
    String path,
    List<int> bytes,
    String filename,
  ) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return _wrap(() => _dio.post(path, data: form));
  }

  Future<ApiResult> put(String path, {dynamic body}) async =>
      _wrap(() => _dio.put(path, data: body));

  Future<ApiResult> delete(String path) async => _wrap(() => _dio.delete(path));

  Future<ApiResult> _wrap(Future<Response> Function() call) async {
    try {
      final res = await call();
      final code = res.statusCode ?? 0;
      final data = res.data;

      // Backend usually returns { success, message, data }.
      if (data is Map<String, dynamic>) {
        final success =
            (data['success'] == true) || (code >= 200 && code < 300);
        return ApiResult(
          ok: success && code >= 200 && code < 300,
          statusCode: code,
          message: data['message']?.toString(),
          data: data.containsKey('data') ? data['data'] : data,
        );
      }

      // Non-envelope responses (rare).
      return ApiResult(
        ok: code >= 200 && code < 300,
        statusCode: code,
        data: data,
      );
    } on DioException catch (e) {
      return ApiResult(
        ok: false,
        statusCode: e.response?.statusCode ?? 0,
        message: _friendly(e),
      );
    } catch (e) {
      return ApiResult(ok: false, statusCode: 0, message: e.toString());
    }
  }

  String _friendly(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection.';
    }
    return e.message ?? 'Something went wrong.';
  }
}

// Normalized result every screen/provider works with.
class ApiResult {
  final bool ok;
  final int statusCode;
  final String? message;
  final dynamic data;

  ApiResult({
    required this.ok,
    required this.statusCode,
    this.message,
    this.data,
  });

  bool get isAuthError => statusCode == 401;
  bool get isForbidden => statusCode == 403;
}

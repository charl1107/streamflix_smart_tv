import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    final headers = <String, String>{};
    if (ApiConfig.appSecret.isNotEmpty) {
      headers['X-App-Secret'] = ApiConfig.appSecret;
    }

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.backendBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      queryParameters: {'language': 'en-US'},
      headers: headers,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        String message = 'An unexpected error occurred';
        if (e.type == DioExceptionType.connectionTimeout) {
          message = 'Connection timed out';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          message = 'Receive timed out';
        } else if (e.response != null) {
          message = 'Server error: ${e.response?.statusCode}';
        }
        return handler.next(DioException(
          requestOptions: e.requestOptions,
          error: message,
          type: e.type,
          response: e.response,
        ));
      },
    ));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

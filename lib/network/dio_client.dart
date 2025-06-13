// lib/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:sdsd/config.dart';

class DioClient {
  DioClient._internal() {
    _dio =
        Dio(
            BaseOptions(
              baseUrl: Config.baseUrl,
              // 공통 Accept 헤더만 둠
              headers: {'accept': 'application/json'},
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          )
          // 👉 1) 로그 찍기 (개발용)
          ..interceptors.add(
            LogInterceptor(requestBody: true, responseBody: true),
          )
          // 👉 2) 최신 토큰 주입
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                final token = Config.accessToken;
                if (token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
                return handler.next(options);
              },
              onError: (e, handler) {
                // 401 처리 로직(선택): refresh_token 재발급 시도 → 재요청 등
                return handler.next(e);
              },
            ),
          );
  }

  static final DioClient instance = DioClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;
}

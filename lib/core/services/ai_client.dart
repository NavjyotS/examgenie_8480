// lib/core/services/ai_client.dart
import 'package:dio/dio.dart';

final Dio _dio = Dio()
 ..interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true, // Logs outgoing request headers
      requestBody: true,
      responseHeader: true, // <-- This logs the incoming response headers
      responseBody: true,
      error: true,
      logPrint: (object) => print('🌐 [DioLog]: $object'),
    ),
  );
Future<Map<String, dynamic>> callApiEndpoint(
  String endpoint,
  Map<String, dynamic> payload, {
  required String jwtToken,
}) async {
  try {
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final errorData = response.data;
    if (response.statusCode != 200) {
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    }

    return response.data ?? {};
  } on DioException catch (error) {
    final errorResponseData = error.response?.data;
    if (errorResponseData != null && errorResponseData is Map) {
      print('API Error Response Data: $errorResponseData');
      if (errorResponseData['error'] != null) {
        print('API Error: ${errorResponseData['error']}, message: ${errorResponseData['message']}');
        throw Exception(errorResponseData['error']);
      }
    }
    print('HTTP request error: $error');
    rethrow;
  }
}
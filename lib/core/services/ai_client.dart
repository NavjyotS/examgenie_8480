import 'package:dio/dio.dart';

final Dio _dio = Dio();

Future<Map<String, dynamic>> callLambdaFunction(
  String endpoint,
  Map<String, dynamic> payload, {
  Map<String, String>? headers,
}) async {
  try {
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: Options(headers: {
        'Content-Type': 'application/json',
        ...?headers,
      }),
    );
    return response.data ?? {};
  } on DioException catch (error) {
    if (error.response?.data != null) {
      print('API Error Response Data: ${error.response?.data}');
      if (error.response?.data is Map) {
        final data = error.response?.data as Map<String, dynamic>;
        if (data['error'] != null) {
          print(
            'Lambda Function Error: ${data['error']}, details: ${data['details']}',
          );
          throw Exception(data['error']);
        }
      } else if (error.response?.data is List) {
        final dataList = error.response?.data as List;
        if (dataList.isNotEmpty && dataList.first is Map) {
          final errorObj = dataList.first['error'];
          if (errorObj != null) {
            final message = errorObj['message'] ?? errorObj.toString();
            print('API Error Message: $message');
            throw Exception(message);
          }
        }
      }
    }
    print('Lambda function error: $error');
    rethrow;
  }
}

import 'package:dio/dio.dart';

final Dio _dio = Dio();

Future<Map<String, dynamic>> callSupabaseFunction(
  String endpoint,
  Map<String, dynamic> payload, {
  required String apiKey,
}) async {
  try {
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'apikey': apiKey,
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
            'Supabase Function Error: ${data['error']}, details: ${data['details']}',
          );
          throw Exception(data['error']);
        }
      }
    }
    print('Supabase function error: $error');
    rethrow;
  }
}
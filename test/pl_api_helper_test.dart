import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pl_api_helper/pl_api_helper.dart';

import 'mock_models/mock_categories.dart';

class MockCacherManager extends Mock implements CacherManager {}

void main() {
  const String baseUrl = 'https://uatapi.bgnuat.fun';
  const String bearerToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTY4MTE4MzUsInVzZXJDb250ZXh0Ijp7ImlkIjoiZDBhZmE3NjAtNzEzNC00NDc2LTk0NDgtOWU2YzMxM2QxOGQ1Iiwicm9sZSI6IiJ9fQ.rmtDcH8liq6SgciBbe34Jwt-JgIIuSLedg11qGhIDM8";
  late DioApiHelper apiHelper;

  setUp(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        contentType: Headers.jsonContentType,
        validateStatus: (status) =>
            status! < 500 && status != 403 && status != 401,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      ),
    );
    apiHelper = DioApiHelper.init(dio: dio, baseUrl: baseUrl);
  });

  test('Call API get course categories by DioApiHelper', () async {
    final result = await apiHelper.get(
      url: '/v1/course/category',
      mapper: (data) => CourseCategoryResposne.fromJson(data),
    );
    print(result.categories);
    expect(result.categories.isNotEmpty, true);
  });
}

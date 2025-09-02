import 'package:flutter/material.dart';
import 'package:pl_api_helper/cache/cache.dart';
import 'package:pl_api_helper/helper/helper.dart';
import 'package:dio/dio.dart';
import 'package:pl_api_helper/interceptors/dio/cache_interceptor.dio.dart';
import 'package:pl_api_helper/models/models.dart';
import 'package:pl_api_helper/utils/method.dart';

import 'models/categories.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<CourseCategory> categories = [];

  static String baseUrl = "";
  static String bearerToken = "";
  @override
  void initState() {
    super.initState();
    _initModule();
  }

  void _initModule() {
    // ignore: avoid_single_cascade_in_expression_statements
    DioApiHelper.init(
      dio: Dio(
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
      ),
      baseUrl: baseUrl,
      cacherManager: CacherManager.instance,
    )..addInterceptor(
      CacheInterceptor(
        cachingPaths: {
          ApiMethod.get: {'/v1/course/category'},
        },
      ),
    );
  }

  Future<void> _getCategories() async {
    setState(() {
      categories = [];
    });
    try {
      final result = await DioApiHelper.instance.get(
        url: '/v1/course/category',
        forceGet: true,
        cacheConfig: CacheConfig(duration: const Duration(minutes: 10)),
        mapper: (data) => CourseCategoryResposne.fromJson(data),
      );
      setState(() {
        categories = result.categories;
      });
    } catch (e) {
      // Handle error
      if (e is ApiError) {
        print("Error Type: ${e.type}, Message: ${e.statusCode}");
      }
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        floatingActionButton: InkWell(
          onTap: _getCategories,
          child: const Icon(Icons.refresh),
        ),
        body: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category.name),
              subtitle: Text('ID: ${category.id}'),
            );
          },
        ),
      ),
    );
  }
}

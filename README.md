# pl_api_helper

A Flutter plugin for simplified API calls, caching, and model mapping using Dio.

## Features

- Easy Dio initialization with base URL, headers, and cache manager.
- Built-in cache interceptor for GET requests.
- Simple API call and model mapping.
- Supports custom cache configuration.

---

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  pl_api_helper: ^<latest_version>
```

---

## Usage

### 1. Initialize DioApiHelper

```dart
import 'package:dio/dio.dart';
import 'package:pl_api_helper/pl_api_helper.dart';

void main() {
  DioApiHelper.init(
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://your-api-domain.com',
        contentType: Headers.jsonContentType,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer <your-token>',
        },
      ),
    ),
    baseUrl: 'https://your-api-domain.com',
    cacherManager: CacherManager.instance,
  )..addInterceptor(
      CacheInterceptor(
        cachingPaths: {
          ApiMethod.get: {'/v1/course/category'},
        },
      ),
    );
}
```

---

## 2. Using TokenDelegation and TokenInterceptor (Automatic Token Refresh)

You can use `TokenInterceptor` to automatically attach access tokens to requests and refresh them when expired.

### Step 1: Implement TokenDelegation

Create a class that implements `TokenDelegation`:

```dart
class MyTokenDelegate implements TokenDelegation {
  @override
  Future<String> getAccessToken() async => /* load from storage */;
  @override
  Future<String> getRefreshToken() async => /* load from storage */;
  @override
  Future<void> saveAccessToken(String token) async => /* save to storage */;
  @override
  Future<void> saveRefreshToken(String token) async => /* save to storage */;
  @override
  Future<void> saveTokens(String accessToken, String? refreshToken) async { /* ... */ }
  @override
  Future<void> deleteToken() async => /* clear storage */;
}
```

### Step 2: Add TokenInterceptor to Dio

```dart
import 'package:dio/dio.dart';
import 'package:pl_api_helper/interceptors/dio/token_interceptor.dio.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

dio.interceptors.add(
  TokenInterceptor(
    baseUrl: 'https://api.example.com',
    refreshEndpoint: '/auth/refresh',
    refreshPayloadBuilder: (refreshToken) => {
      'refreshToken': refreshToken,
    },
    tokenDelegate: MyTokenDelegate(),
    onUnauthenticated: () {
      // Handle logout or navigation to login
    },
  ),
);
```

### Step 3: Make API Calls

```dart
final response = await dio.get('/protected/resource');
```

> TokenInterceptor will automatically refresh the token on 401/403 errors and retry the request.

---

### 3. Call API and Parse Model

```dart
final result = await DioApiHelper.instance.get(
  url: '/v1/course/category',
  forceGet: true,
  cacheConfig: CacheConfig(duration: Duration(minutes: 10)),
  mapper: (data) => CourseCategoryResposne.fromJson(data),
);

// Access categories
for (final category in result.categories) {
  print('Category: ${category.name} (ID: ${category.id})');
}
```

---

### 4. Example Widget Integration

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<CourseCategory> categories = [];

  @override
  void initState() {
    super.initState();
    // Initialize DioApiHelper here
  }

  Future<void> _getCategories() async {
    setState(() {
      categories = [];
    });
    try {
      final result = await DioApiHelper.instance.get(
        url: '/v1/course/category',
        forceGet: true,
        cacheConfig: CacheConfig(duration: Duration(minutes: 10)),
        mapper: (data) => CourseCategoryResposne.fromJson(data),
      );
      setState(() {
        categories = result.categories;
      });
    } catch (e) {
      if (e is ApiError) {
        print("Error Type: ${e.type}, Message: ${e.statusCode}");
      }
    }
  }

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
```

---

## Model Example

```dart
class CourseCategory {
  final String id;
  final String name;

  CourseCategory({required this.id, required this.name});

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class CourseCategoryResposne {
  final List<CourseCategory> categories;

  CourseCategoryResposne({required this.categories});

  factory CourseCategoryResposne.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>)
        .map((e) => CourseCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return CourseCategoryResposne(categories: cats);
  }
}
```

---

## License

MIT
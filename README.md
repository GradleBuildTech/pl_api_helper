<div align="center">

# <img src="icon.svg" width="64" height="64" alt="pl_api_helper icon"> 
# pl_api_helper

**A comprehensive Flutter plugin for simplified API calls, caching, and model mapping with support for both Dio and standard HTTP clients.**

[![pub package](https://img.shields.io/pub/v/pl_api_helper.svg)](https://pub.dev/packages/pl_api_helper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)

</div>

---

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [API Reference](#-api-reference)
- [Advanced Usage](#-advanced-usage)
- [Examples](#-examples)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🚀 Features

### 🔥 Core Functionality
- **🔄 Dual HTTP Client Support** - Choose between Dio (advanced) or standard HTTP client
- **🧠 Intelligent Caching** - Memory and disk caching with network awareness
- **🛡️ Generic Type Safety** - Full type safety with generic response mapping
- **⚡ Multi-threading Support** - Background parsing to prevent UI blocking
- **🎯 Comprehensive Error Handling** - Detailed error classification and handling

### 🔧 Advanced Features
- **🔐 Automatic Token Management** - Built-in token refresh and authentication
- **🔗 Request/Response Interceptors** - Customizable request and response processing
- **📡 Network Awareness** - Smart caching based on connectivity status
- **🌊 Stream Support** - Real-time data streaming capabilities
- **📊 GraphQL Integration** - Built-in GraphQL client support

### 👨‍💻 Developer Experience
- **🏗️ Singleton Pattern** - Global access to API helpers
- **⚙️ Flexible Configuration** - Easy setup with sensible defaults
- **📝 Comprehensive Logging** - Built-in logging with release mode optimization
- **🎨 Widget Integration** - Ready-to-use widgets for common scenarios

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  pl_api_helper: ^0.0.1
```

Then run:
```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Initialize DioApiHelper (Recommended)

```dart
import 'package:dio/dio.dart';
import 'package:pl_api_helper/pl_api_helper.dart';

void main() {
  // Initialize DioApiHelper with configuration
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
        connectTimeout: Duration(seconds: 30),
        receiveTimeout: Duration(seconds: 30),
      ),
    ),
    baseUrl: 'https://your-api-domain.com',
  );
}
```

### 2. Alternative: Initialize HttpHelper (Lightweight)

```dart
import 'package:pl_api_helper/pl_api_helper.dart';

void main() {
  // Initialize HttpHelper for simple HTTP requests
  HttpHelper.init(
    baseUrl: 'https://your-api-domain.com',
    apiConfig: ApiConfig(
      baseUrl: 'https://your-api-domain.com',
      defaultHeaders: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      timeout: Duration(seconds: 30),
    ),
  );
}
```

---

## 📡 Making API Calls

### Basic API Calls

```dart
// GET request with caching
final result = await DioApiHelper.instance.get<User>(
  url: '/api/users/123',
  cacheConfig: CacheConfig(duration: Duration(minutes: 5)),
  mapper: (data) => User.fromJson(data),
);

// POST request
final newUser = await DioApiHelper.instance.post<User>(
  url: '/api/users',
  request: {'name': 'John Doe', 'email': 'john@example.com'},
  mapper: (data) => User.fromJson(data),
);

// PUT request
final updatedUser = await DioApiHelper.instance.put<User>(
  url: '/api/users/123',
  request: {'name': 'Jane Doe'},
  mapper: (data) => User.fromJson(data),
);

// DELETE request
await DioApiHelper.instance.delete<void>(
  url: '/api/users/123',
  mapper: (data) => null,
);
```

### Advanced Caching Configuration

```dart
// Custom cache configuration
final cacheConfig = CacheConfig(
  duration: Duration(hours: 1),
  useMemoryCache: true,
  useDiskCache: true,
  maxCacheSize: 50 * 1024 * 1024, // 50MB
  onlyGetWhenDisconnected: false,
);

final result = await DioApiHelper.instance.get<List<Post>>(
  url: '/api/posts',
  cacheConfig: cacheConfig,
  mapper: (data) => (data as List).map((json) => Post.fromJson(json)).toList(),
);
```

---

## 🔐 Authentication & Token Management

### Automatic Token Refresh

```dart
// Step 1: Implement TokenDelegation
class MyTokenDelegate implements TokenDelegation {
  @override
  Future<String> getAccessToken() async {
    // Load from secure storage
    return await SecureStorage.read('access_token') ?? '';
  }
  
  @override
  Future<String> getRefreshToken() async {
    return await SecureStorage.read('refresh_token') ?? '';
  }
  
  @override
  Future<void> saveAccessToken(String token) async {
    await SecureStorage.write('access_token', token);
  }
  
  @override
  Future<void> saveRefreshToken(String token) async {
    await SecureStorage.write('refresh_token', token);
  }
  
  @override
  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) await saveRefreshToken(refreshToken);
  }
  
  @override
  Future<void> deleteToken() async {
    await SecureStorage.delete('access_token');
    await SecureStorage.delete('refresh_token');
  }
}

// Step 2: Add Token Interceptor
DioApiHelper.instance.addInterceptor(
  DioTokenInterceptor(
    baseUrl: 'https://api.example.com',
    refreshEndpoint: '/auth/refresh',
    refreshPayloadBuilder: (refreshToken) => {
      'refreshToken': refreshToken,
    },
    tokenDelegate: MyTokenDelegate(),
    onUnauthenticated: () {
      // Handle logout or navigation to login
      Navigator.pushReplacementNamed(context, '/login');
    },
  ),
);
```

---

## 🎯 Model Examples

### User Model

```dart
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

### Post Model with Comments

```dart
class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final List<Comment> comments;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.comments,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Comment {
  final String id;
  final String content;
  final String authorId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

---

## 🎨 Widget Integration

### Complete Example App

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Post> posts = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await DioApiHelper.instance.get<List<Post>>(
        url: '/api/posts',
        cacheConfig: CacheConfig(duration: Duration(minutes: 10)),
        mapper: (data) => (data as List)
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      
      setState(() {
        posts = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        if (e is ApiError) {
          errorMessage = 'Error: ${e.message} (${e.type})';
        } else {
          errorMessage = 'Unknown error occurred';
        }
      });
    }
  }

  Future<void> _createPost() async {
    try {
      final newPost = await DioApiHelper.instance.post<Post>(
        url: '/api/posts',
        request: {
          'title': 'New Post',
          'content': 'This is a new post created via API',
        },
        mapper: (data) => Post.fromJson(data as Map<String, dynamic>),
      );
      
      setState(() {
        posts = [newPost, ...posts];
      });
    } catch (e) {
      setState(() {
        if (e is ApiError) {
          errorMessage = 'Failed to create post: ${e.message}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Posts App'),
          actions: [
            IconButton(
              onPressed: _loadPosts,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createPost,
          child: const Icon(Icons.add),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return const Center(child: Text('No posts available'));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(post.title),
            subtitle: Text(post.content),
            trailing: Text(post.createdAt.toString().split(' ')[0]),
          ),
        );
      },
    );
  }
}
```

---

## 🛠️ Advanced Features

### Custom Interceptors

```dart
class LoggingInterceptor extends BaseInterceptor {
  @override
  Future<void> onRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    Logger.d('API Request', '$method $url');
    Logger.d('API Headers', headers.toString());
    Logger.d('API Body', body.toString());
  }

  @override
  Future<void> onResponse(http.Response response) async {
    Logger.d('API Response', '${response.statusCode} ${response.body}');
  }
}

// Add to your helper
HttpHelper.instance.addInterceptor(LoggingInterceptor());
```

### Error Handling

```dart
try {
  final result = await DioApiHelper.instance.get<User>('/api/user');
} on ApiError catch (e) {
  switch (e.type) {
    case ApiErrorType.noInternet:
      // Handle no internet
      break;
    case ApiErrorType.unauthorized:
      // Handle unauthorized
      break;
    case ApiErrorType.timeout:
      // Handle timeout
      break;
    default:
      // Handle other errors
      break;
  }
}
```

### Cache Management

```dart
// Clear all cache
await CacherManager.instance.clear();

// Get cache size
final size = await CacherManager.instance.getCacheSize();
print('Cache size: ${size / 1024 / 1024} MB');

// Remove specific cache
await CacherManager.instance.removeData('/api/posts');
```

---

## 📚 API Reference

### DioApiHelper

| Method | Description |
|--------|-------------|
| `get<T>()` | GET request with caching support |
| `post<T>()` | POST request |
| `put<T>()` | PUT request |
| `delete<T>()` | DELETE request |
| `uploadFile<T>()` | File upload (not implemented) |
| `addInterceptor()` | Add Dio interceptors |

### HttpHelper

| Method | Description |
|--------|-------------|
| `get<T>()` | GET request with caching support |
| `post<T>()` | POST request |
| `put<T>()` | PUT request |
| `delete<T>()` | DELETE request |
| `addInterceptor()` | Add HTTP interceptors |

### CacheConfig

| Property | Type | Description |
|----------|------|-------------|
| `duration` | `Duration` | Cache expiration time |
| `useMemoryCache` | `bool` | Enable memory caching |
| `useDiskCache` | `bool` | Enable disk caching |
| `maxCacheSize` | `int` | Maximum cache size in bytes |
| `onlyGetWhenDisconnected` | `bool` | Use cache only when offline |

### ApiError

| Property | Type | Description |
|----------|------|-------------|
| `type` | `ApiErrorType` | Error type (noInternet, timeout, unauthorized, etc.) |
| `message` | `String?` | Human-readable error message |
| `statusCode` | `int?` | HTTP status code |
| `errorCode` | `String?` | Application-specific error code |

---

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

1. **Fork** the repository
2. **Create** your feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add some amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/your-username/pl_api_helper.git

# Navigate to the plugin directory
cd pl_api_helper

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run example app
cd example
flutter run
```

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

We'd like to thank the following projects and contributors:

- **[Dio](https://pub.dev/packages/dio)** - Powerful HTTP client for Dart
- **[HTTP](https://pub.dev/packages/http)** - A composable, multi-platform, Future-based library for making HTTP requests
- **[Shared Preferences](https://pub.dev/packages/shared_preferences)** - Flutter plugin for reading and writing simple key-value pairs
- **[Connectivity Plus](https://pub.dev/packages/connectivity_plus)** - Flutter plugin for discovering the state of the network connectivity

---

<div align="center">

**Made with ❤️ for the Flutter community**

[⭐ Star this repo](https://github.com/your-username/pl_api_helper) • [🐛 Report Bug](https://github.com/your-username/pl_api_helper/issues) • [💡 Request Feature](https://github.com/your-username/pl_api_helper/issues)

</div>

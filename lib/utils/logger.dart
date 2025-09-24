import 'package:flutter/foundation.dart';

/// [LogLevel] - Enumeration of logging levels
///
/// This enum defines the different levels of logging available.
/// Used to categorize log messages by their importance and type.
enum LogLevel {
  /// Informational messages
  info,

  /// Debug messages for development
  debug,

  /// Error messages
  error
}

/// [Logger] - Utility class for logging messages
///
/// This class provides a simple logging interface that automatically
/// handles tag formatting and respects release mode settings.
///
/// Key features:
/// - Automatic tag formatting from objects
/// - Release mode detection (no logging in release builds)
/// - Multiple log levels (info, debug, error)
/// - Convenient static methods for common logging scenarios
final class Logger {
  /// Private constructor to prevent instantiation
  Logger._();

  /// Log a message with specified level
  ///
  /// This method formats the tag and message, then prints it to the console.
  /// In release mode, logging is disabled for performance.
  ///
  /// Parameters:
  /// - [tag]: Object to use as tag (String, Type, or any object)
  /// - [message]: Message to log
  /// - [level]: Log level (default: LogLevel.info)
  static void log(
    Object tag,
    String message, {
    LogLevel level = LogLevel.info,
  }) {
    // Skip logging in release mode for performance
    if (kReleaseMode) return;

    // Format tag based on its type
    String tagStr = switch (tag) {
      String s => s,
      Type t => t.toString(),
      _ => tag.runtimeType.toString(),
    };

    // Print formatted log message
    debugPrint('${level.name.toUpperCase()} $tagStr: $message');
  }

  /// Log an informational message
  ///
  /// Convenience method for logging info-level messages.
  ///
  /// Parameters:
  /// - [tag]: Object to use as tag
  /// - [message]: Message to log
  static void i(Object tag, String message) =>
      log(tag, message, level: LogLevel.info);

  /// Log a debug message
  ///
  /// Convenience method for logging debug-level messages.
  ///
  /// Parameters:
  /// - [tag]: Object to use as tag
  /// - [message]: Message to log
  static void d(Object tag, String message) =>
      log(tag, message, level: LogLevel.debug);

  /// Log an error message
  ///
  /// Convenience method for logging error-level messages.
  ///
  /// Parameters:
  /// - [tag]: Object to use as tag
  /// - [message]: Message to log
  static void e(Object tag, String message) =>
      log(tag, message, level: LogLevel.error);
}

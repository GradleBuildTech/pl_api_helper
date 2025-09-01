import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pl_api_helper_platform_interface.dart';

/// An implementation of [PlApiHelperPlatform] that uses method channels.
class MethodChannelPlApiHelper extends PlApiHelperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pl_api_helper');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

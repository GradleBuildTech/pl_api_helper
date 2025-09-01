import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pl_api_helper_method_channel.dart';

abstract class PlApiHelperPlatform extends PlatformInterface {
  /// Constructs a PlApiHelperPlatform.
  PlApiHelperPlatform() : super(token: _token);

  static final Object _token = Object();

  static PlApiHelperPlatform _instance = MethodChannelPlApiHelper();

  /// The default instance of [PlApiHelperPlatform] to use.
  ///
  /// Defaults to [MethodChannelPlApiHelper].
  static PlApiHelperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PlApiHelperPlatform] when
  /// they register themselves.
  static set instance(PlApiHelperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

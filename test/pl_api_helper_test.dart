import 'package:flutter_test/flutter_test.dart';
import 'package:pl_api_helper/pl_api_helper.dart';
import 'package:pl_api_helper/pl_api_helper_platform_interface.dart';
import 'package:pl_api_helper/pl_api_helper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlApiHelperPlatform
    with MockPlatformInterfaceMixin
    implements PlApiHelperPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PlApiHelperPlatform initialPlatform = PlApiHelperPlatform.instance;

  test('$MethodChannelPlApiHelper is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPlApiHelper>());
  });

  test('getPlatformVersion', () async {
    PlApiHelper plApiHelperPlugin = PlApiHelper();
    MockPlApiHelperPlatform fakePlatform = MockPlApiHelperPlatform();
    PlApiHelperPlatform.instance = fakePlatform;

    expect(await plApiHelperPlugin.getPlatformVersion(), '42');
  });
}

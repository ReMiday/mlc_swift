import 'package:flutter_test/flutter_test.dart';
import 'package:mlc_swift/src/mlc_swift.dart';
import 'package:mlc_swift/src/mlc_swift_platform_interface.dart';
import 'package:mlc_swift/src/mlc_swift_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  final MlcSwiftPlatform initialPlatform = MlcSwiftPlatform.instance;

  test('$MethodChannelMlcSwift is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMlcSwift>());
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mlc_swift/src/mlc_swift_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMlcSwift platform = MethodChannelMlcSwift();
  const MethodChannel channel = MethodChannel('mlc_swift');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {

  });
}

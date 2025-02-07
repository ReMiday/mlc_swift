import 'package:mlc_swift/src/model/app_config.dart';
import 'package:mlc_swift/src/model/model_init_state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mlc_swift_method_channel.dart';

abstract class MlcSwiftPlatform extends PlatformInterface {
  MlcSwiftPlatform() : super(token: _token);

  static final Object _token = Object();

  static MlcSwiftPlatform _instance = MethodChannelMlcSwift();

  /// The default instance of [MlcSwiftPlatform] to use.
  ///
  /// Defaults to [MethodChannelMlcSwift].
  static MlcSwiftPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MlcSwiftPlatform] when
  /// they register themselves.
  static set instance(MlcSwiftPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<ModelInitState> getModelInitState();

  Future<void> downloadModel(
      {void Function(double progress)? onProgress,
        void Function()? onDone,
        void Function(String error)? onError});

  Future<bool> initEngine();

  Future<Stream<String>> requestGenerate(String requestId, String prompt);

  Future<void> resetEngine();

  Future<void> terminateEngine();
}

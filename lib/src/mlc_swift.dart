import 'package:mlc_swift/src/model/model_init_state.dart';

import 'mlc_swift_platform_interface.dart';

class MlcSwift {
  Future<ModelInitState> getModelInitState() =>
      MlcSwiftPlatform.instance.getModelInitState();

  Future<void> downloadModel(
      {void Function(double progress)? onProgress,
        void Function()? onDone,
        void Function(String error)? onError}) =>
      MlcSwiftPlatform.instance.downloadModel(
        onProgress: onProgress,
        onDone: onDone,
        onError: onError,
      );

  Future<bool> initEngine() =>
      MlcSwiftPlatform.instance.initEngine();

  Future<Stream<String>> requestGenerate(String requestId, String prompt) =>
      MlcSwiftPlatform.instance.requestGenerate(requestId, prompt);

  Future<void> resetEngine() => MlcSwiftPlatform.instance.resetEngine();

  Future<void> terminateEngine() => MlcSwiftPlatform.instance.terminateEngine();
}

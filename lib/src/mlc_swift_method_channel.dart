import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mlc_swift/src/mlc_swift_model_state.dart';
import 'package:mlc_swift/src/model/model_init_state.dart';

import 'mlc_swift_platform_interface.dart';

/// An implementation of [MlcSwiftPlatform] that uses method channels.
class MethodChannelMlcSwift extends MlcSwiftPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mlc_swift');

  @override
  Future<ModelInitState> getModelInitState() =>
      MlcSwiftModelState().getModelState();

  @override
  Future<void> downloadModel(
      {void Function(double progress)? onProgress,
        void Function()? onDone,
        void Function(String error)? onError}) =>
      MlcSwiftModelState().downloadModel(
        onProgress: onProgress,
        onDone: onDone,
        onError: onError,
      );

  @override
  Future<bool> initEngine() async {
    try {
      MlcSwiftModelState state = MlcSwiftModelState();
      String? modelPath = await state.getModelPath();
      if (modelPath == null) return false;
      final result = await methodChannel.invokeMethod("init_chat", {
        "model_path": modelPath,
        "model_lib": state.modelLib,
      });
      return result;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Stream<String>> requestGenerate(
      String requestId, String prompt) async {
    await methodChannel.invokeMethod(
      "request_generate",
      {
        "request_id": requestId,
        "prompt": prompt,
      },
    );
    return EventChannel(requestId)
        .receiveBroadcastStream()
        .map(_handlePredictWord);
  }

  String _handlePredictWord(dynamic value) {
    return value.toString();
  }

  @override
  Future<void> resetEngine() async {
    await methodChannel.invokeMethod("reset");
  }

  @override
  Future<void> terminateEngine() async {
    await methodChannel.invokeMethod("terminate");
  }
}

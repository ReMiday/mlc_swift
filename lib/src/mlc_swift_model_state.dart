import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:mlc_swift/mlc_swift.dart';
import 'package:mlc_swift/src/model/app_config.dart';
import 'package:mlc_swift/src/model/model_config.dart';
import 'package:mlc_swift/src/model/model_record.dart';
import 'package:mlc_swift/src/model/params_config.dart';
import 'package:mlc_swift/src/model/params_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retry/retry.dart';
import 'package:uuid/uuid.dart';

const String appConfigFileName = "mlc-app-config.json";
const String modelConfigFileName = "mlc-chat-config.json";
const String paramsConfigFileName = "ndarray-cache.json";
const String modelUrlSuffix = "resolve/main/";

class MlcSwiftModelState {
  final _timeoutDuration = const Duration(seconds: 5);

  final client = Client();

  final _appConfig = AppConfig(
    // modelLib: "qwen2_q4f16_1_3397e1f63839c795ae4289beb07f90f7",
    modelLib: "qwen2_q4f16_1_a5957f0280477f325ed1e1b20f388afa",
    model: ModelRecord(
      modelUrl:
      "https://hf-mirror.com/mlc-ai/Qwen2.5-0.5B-Instruct-q4f16_1-MLC",
      modelId: "Qwen2.5-0.5B-Instruct-q4f16_1-MLC",
      estimatedVramBytes: 3980990464,
      // modelLib: "qwen2_q4f16_1_3397e1f63839c795ae4289beb07f90f7",
      modelLib: "qwen2_q4f16_1_a5957f0280477f325ed1e1b20f388afa",
    ),
  );

  Future<String?> getModelPath() async {
    final appDirFile = await getApplicationSupportDirectory();
    final modelLib = "${appDirFile.path}/${_appConfig.model.modelId}/";
    return modelLib;
  }

  String get modelLib => _appConfig.modelLib;

  Future<ModelInitState> getModelState() async {
    ModelInitState initState = ModelInitState.paused;
    final modelLib = await getModelPath();
    if (modelLib == null) return initState;
    final modelConfigFile = File("$modelLib$modelConfigFileName");
    if (modelConfigFile.existsSync()) {
      final rawModelConfig = await modelConfigFile.readAsString();
      final modelConfig =
      ModelConfig.fromJson(jsonDecode(rawModelConfig), _appConfig.model);
      final paramsConfig =
      await _getParamsConfig("$modelLib$paramsConfigFileName");
      if (paramsConfig != null) {
        int total = modelConfig.tokenizerFiles.length +
            paramsConfig.paramsRecords.length;
        int progress = 0;
        for (String tokenizerFileName in modelConfig.tokenizerFiles) {
          final file = File(modelLib + tokenizerFileName);
          if (file.existsSync()) {
            ++progress;
          }
        }
        for (ParamsRecord e in paramsConfig.paramsRecords) {
          final file = File(modelLib + e.dataPath);
          if (file.existsSync()) {
            ++progress;
          }
        }
        if (progress >= total) {
          initState = ModelInitState.finished;
        }
      }
    }
    return initState;
  }

  Future<ParamsConfig?> _getParamsConfig(String configPath) async {
    final paramsConfigFile = File(configPath);
    if (await paramsConfigFile.exists()) {
      final rawParamsConfig = await paramsConfigFile.readAsString();
      return ParamsConfig.fromJson(jsonDecode(rawParamsConfig));
    } else {
      return null;
    }
  }

  Future<void> downloadModel(
      {Function(double progress)? onProgress,
        Function()? onDone,
        Function(String error)? onError}) async {
    final modelLib = await getModelPath();
    if (modelLib == null) {
      if (onError != null) onError("No Model Dir!");
      return;
    }
    final modelConfigFile = File("$modelLib$modelConfigFileName");
    ModelConfig? modelConfig;
    if (await modelConfigFile.exists()) {
      final rawModelConfig = await modelConfigFile.readAsString();
      modelConfig =
          ModelConfig.fromJson(jsonDecode(rawModelConfig), _appConfig.model);
    } else {
      await _downloadConfigFile(
        _appConfig.model,
        modelLib,
        modelConfigFileName,
        parseResponse: (value) {
          modelConfig =
              ModelConfig.fromJson(jsonDecode(value), _appConfig.model);
        },
      );
    }
    if (modelConfig == null) {
      if (onError != null) onError("download Model Config Failed!");
      return;
    }
    ParamsConfig? paramsConfig =
    await _getParamsConfig("$modelLib$paramsConfigFileName");
    if (paramsConfig == null) {
      await _downloadConfigFile(
        _appConfig.model,
        modelLib,
        paramsConfigFileName,
        parseResponse: (value) {
          paramsConfig = ParamsConfig.fromJson(
            jsonDecode(value),
          );
        },
      );
    }
    if (paramsConfig == null) {
      if (onError != null) onError("download Params Config Failed");
      return;
    }
    int total =
        modelConfig!.tokenizerFiles.length + paramsConfig!.paramsRecords.length;
    int progress = 0;
    bool shouldStop = false;
    for (String tokenizerFileName in modelConfig!.tokenizerFiles) {
      if(shouldStop)break;
      final file = File(modelLib + tokenizerFileName);
      if (file.existsSync()) {
        ++progress;
        if (onProgress != null) onProgress(progress / total);
      } else {
        await _downloadConfigFile(
            _appConfig.model,
            modelLib,
            tokenizerFileName,
            onDone: () {
              ++progress;
              if (onProgress != null) onProgress(progress / total);
            },
            onError: (){
              if(onError != null) onError("download $tokenizerFileName failed!");
              shouldStop = true;
            }
        );
      }
    }
    for (ParamsRecord e in paramsConfig!.paramsRecords) {
      if(shouldStop) break;
      final file = File(modelLib + e.dataPath);
      if (file.existsSync()) {
        ++progress;
        if (onProgress != null) onProgress(progress / total);
      } else {
        await _downloadConfigFile(
            _appConfig.model,
            modelLib,
            e.dataPath,
            onDone: () {
              ++progress;
              if (onProgress != null) onProgress(progress / total);
            },
            onError: () {
              if(onError != null) onError("download ${e.dataPath} failed!");
              shouldStop = true;
            }
        );
      }
    }
    if (progress >= total) {
      if (onDone != null) onDone();
    }
  }

  Future<void> _downloadConfigFile(
      ModelRecord modelRecord,
      String modelLib,
      String fileName, {
        void Function()? onDone,
        void Function(String value)? parseResponse,
        void Function()? onError,
      }) async {
    Completer<void> completer = Completer<void>();
    Uri uri = Uri.parse("${modelRecord.modelUrl}/$modelUrlSuffix$fileName");
    final request = Request('GET', uri);
    final response = await retry(
          () => client.send(request).timeout(_timeoutDuration),
      retryIf: (e) => e is SocketException || e is TimeoutException,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      String tempId = const Uuid().v4();
      File tempFile = File("$modelLib$tempId");
      await tempFile.create(recursive: true);
      final sink = tempFile.openWrite();
      response.stream.listen((value) {
        sink.add(value);
      }, onDone: () async {
        await sink.close();
        final configFile = File("$modelLib$fileName");
        await configFile.create(recursive: true);
        await tempFile.copy(configFile.path);
        if (parseResponse != null) {
          String contents = await configFile.readAsString();
          parseResponse(contents);
        }
        await tempFile.delete();
        if (onDone != null) onDone();
        completer.complete();
      }, onError: (e, strace) async {
        await sink.close();
        await tempFile.delete();
        if (onError != null) onError();
        completer.complete();
      });
    } else {
      if (onError != null) onError();
      completer.complete();
    }
    return completer.future;
  }
}

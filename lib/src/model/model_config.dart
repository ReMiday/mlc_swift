import 'package:mlc_swift/src/model/model_record.dart';

class ModelConfig {
  String modelLib;
  String modelId;
  int estimatedVramBytes;
  List<dynamic> tokenizerFiles;
  int contextWindowSize;
  int prefillChunkSize;

  ModelConfig({
    required this.modelLib,
    required this.modelId,
    required this.estimatedVramBytes,
    required this.tokenizerFiles,
    required this.contextWindowSize,
    required this.prefillChunkSize,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json,ModelRecord record) {
    return ModelConfig(
      modelLib: record.modelLib,
      modelId: record.modelId,
      estimatedVramBytes: record.estimatedVramBytes,
      tokenizerFiles: json["tokenizer_files"],
      contextWindowSize: json["context_window_size"],
      prefillChunkSize: json["prefill_chunk_size"],
    );
  }
}

class ModelRecord {
  final String modelUrl;
  final String modelId;
  final int estimatedVramBytes;
  final String modelLib;

  ModelRecord({
    required this.modelUrl,
    required this.modelId,
    required this.estimatedVramBytes,
    required this.modelLib,
  });

  factory ModelRecord.fromJson(Map<String, dynamic> json) {
    return ModelRecord(
      modelUrl: json["model_url"],
      modelId: json["model_id"],
      estimatedVramBytes: json["estimated_vram_bytes"],
      modelLib: json["modelLib"],
    );
  }
}
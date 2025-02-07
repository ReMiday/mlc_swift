class ParamsRecord {
  final String dataPath;

  ParamsRecord({required this.dataPath});

  factory ParamsRecord.fromJson(Map<String,dynamic> json) {
    return ParamsRecord(dataPath: json["dataPath"]);
  }
}
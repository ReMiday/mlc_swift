import 'dart:convert';

import 'package:mlc_swift/src/model/params_record.dart';

class ParamsConfig {
  final List<ParamsRecord> paramsRecords;

  ParamsConfig({required this.paramsRecords});

  factory ParamsConfig.fromJson(Map<String, dynamic> json) {
    return ParamsConfig(
        paramsRecords: (json["records"] as List<dynamic>)
            .map((e) => ParamsRecord.fromJson(e))
            .toList());
  }
}

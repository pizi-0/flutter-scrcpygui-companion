// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ScrcpyConfig {
  final String id;
  final String configName;

  ScrcpyConfig({required this.id, required this.configName});

  factory ScrcpyConfig.fromMap(Map<String, dynamic> map) {
    return ScrcpyConfig(id: map['id'], configName: map['configName'] as String);
  }

  factory ScrcpyConfig.fromJson(String source) =>
      ScrcpyConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ScrcpyInstance {
  final String pid;
  final String name;
  final String device;
  ScrcpyInstance({required this.pid, required this.name, required this.device});

  ScrcpyInstance copyWith({String? pid, String? name, String? device}) {
    return ScrcpyInstance(
      pid: pid ?? this.pid,
      name: name ?? this.name,
      device: device ?? this.device,
    );
  }

  factory ScrcpyInstance.fromMap(Map<String, dynamic> map) {
    return ScrcpyInstance(
      pid: map['pid'] as String,
      name: map['name'] as String,
      device: map['device'] as String,
    );
  }

  factory ScrcpyInstance.fromJson(String source) =>
      ScrcpyInstance.fromMap(json.decode(source) as Map<String, dynamic>);
}

// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// class ScrcpyRunningInstance {
//   final String pid;
//   final String name;
//   final String device;
//   ScrcpyRunningInstance({
//     required this.pid,
//     required this.name,
//     required this.device,
//   });

//   ScrcpyRunningInstance copyWith({String? pid, String? name, String? device}) {
//     return ScrcpyRunningInstance(
//       pid: pid ?? this.pid,
//       name: name ?? this.name,
//       device: device ?? this.device,
//     );
//   }

//   factory ScrcpyRunningInstance.fromMap(Map<String, dynamic> map) {
//     return ScrcpyRunningInstance(
//       pid: map['pid'] as String,
//       name: map['name'] as String,
//       device: map['device'] as String,
//     );
//   }

//   factory ScrcpyRunningInstance.fromJson(String source) =>
//       ScrcpyRunningInstance.fromMap(
//         json.decode(source) as Map<String, dynamic>,
//       );
// }

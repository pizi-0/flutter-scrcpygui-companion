// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// class AdbDevices {
//   String? name;
//   final String id;
//   String? ip;
//   final String modelName;
//   final String serialNo;

//   AdbDevices({
//     this.name,
//     required this.id,
//     this.ip,
//     required this.modelName,
//     required this.serialNo,
//   }) {
//     name = name ?? modelName;
//     ip = ip ?? id.split(':').first;
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'name': name,
//       'id': id,
//       'modelName': modelName,
//       'serialNo': serialNo,
//       'ip': ip ?? id,
//     };
//   }

//   factory AdbDevices.fromMap(Map<String, dynamic> map) {
//     return AdbDevices(
//       name: map['name'] != null ? map['name'] as String : map['modelName'],
//       id: map['id'] as String,
//       ip: map['ip'] ?? map['id'],
//       modelName: map['modelName'] as String,
//       serialNo: map['serialNo'] as String,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory AdbDevices.fromJson(String source) =>
//       AdbDevices.fromMap(json.decode(source) as Map<String, dynamic>);

//   AdbDevices copyWith({
//     String? name,
//     String? id,
//     String? ip,
//     String? modelName,
//     String? serialNo,
//   }) {
//     return AdbDevices(
//       name: name ?? this.name,
//       id: id ?? this.id,
//       ip: ip ?? this.ip,
//       modelName: modelName ?? this.modelName,
//       serialNo: serialNo ?? this.serialNo,
//     );
//   }

//   @override
//   bool operator ==(covariant AdbDevices other) {
//     if (identical(this, other)) return true;

//     return other.name == name &&
//         other.id == id &&
//         other.ip == ip &&
//         other.modelName == modelName &&
//         other.serialNo == serialNo;
//   }

//   @override
//   int get hashCode {
//     return name.hashCode ^
//         id.hashCode ^
//         ip.hashCode ^
//         modelName.hashCode ^
//         serialNo.hashCode;
//   }

//   @override
//   String toString() {
//     return 'AdbDevices(name: $name, id: $id, ip: $ip, modelName: $modelName, serialNo: $serialNo)';
//   }
// }

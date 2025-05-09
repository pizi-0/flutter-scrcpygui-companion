// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// import 'scrcpy_app.dart';
// import 'scrcpy_config.dart';

// class AppConfigPair {
//   final int hash;
//   final String deviceId;
//   final ScrcpyApp app;
//   final ScrcpyConfig config;
//   AppConfigPair({
//     required this.hash,
//     required this.deviceId,
//     required this.app,
//     required this.config,
//   });

//   factory AppConfigPair.fromMap(Map<String, dynamic> map) {
//     return AppConfigPair(
//       hash: map['hashCode'] as int,
//       deviceId: map['deviceId'] as String,
//       app: ScrcpyApp.fromMap(map['app'] as Map<String, dynamic>),
//       config: ScrcpyConfig.fromMap(map['config'] as Map<String, dynamic>),
//     );
//   }

//   factory AppConfigPair.fromJson(String source) =>
//       AppConfigPair.fromMap(json.decode(source) as Map<String, dynamic>);
// }

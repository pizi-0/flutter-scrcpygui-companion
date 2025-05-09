// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ClientPayload {
  final ClientAction action;
  final String payload;

  ClientPayload({required this.action, required this.payload});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'action': ClientAction.values.indexOf(action).toString(),
      'payload': payload,
    };
  }

  factory ClientPayload.fromMap(Map<String, dynamic> map) {
    return ClientPayload(
      action: ClientAction.values[int.parse(map['action'] as String)],
      payload: map['payload'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ClientPayload.fromJson(String source) =>
      ClientPayload.fromMap(json.decode(source) as Map<String, dynamic>);
}

enum ClientAction {
  startScrcpy,
  startAppConfigPair,
  killScrcpy,
  connectDevice,
  disconnectDevice,
}

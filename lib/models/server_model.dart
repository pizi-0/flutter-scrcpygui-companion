// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ServerModel {
  final String id;
  final String name;
  final String ip;
  final String secret;
  final int port;

  ServerModel({
    required this.id,
    required this.name,
    required this.ip,
    required this.secret,
    required this.port,
  });

  ServerModel copyWith({
    String? name,
    String? ip,
    String? secret,
    int? port,
    bool? startOnLaunch,
    String? id,
  }) {
    return ServerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      secret: secret ?? this.secret,
      port: port ?? this.port,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'ip': ip,
      'secret': secret,
      'port': port,
    };
  }

  factory ServerModel.fromMap(Map<String, dynamic> map) {
    return ServerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      ip: map['ip'] as String,
      secret: map['secret'] as String,
      port: map['port'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServerModel.fromJson(String source) =>
      ServerModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ServerModel(name: $name, ip: $ip, secret: $secret, port: $port)';
  }

  @override
  bool operator ==(covariant ServerModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.ip == ip &&
        other.secret == secret &&
        other.port == port;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        ip.hashCode ^
        secret.hashCode ^
        port.hashCode;
  }
}

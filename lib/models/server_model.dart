// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ServerModel {
  final String name;
  final String endpoint;
  final String secret;
  final String port;

  ServerModel({
    required this.name,
    required this.endpoint,
    required this.secret,
    required this.port,
  });

  ServerModel copyWith({
    String? name,
    String? endpoint,
    String? secret,
    String? port,
    bool? startOnLaunch,
  }) {
    return ServerModel(
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      secret: secret ?? this.secret,
      port: port ?? this.port,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'endpoint': endpoint,
      'secret': secret,
      'port': port,
    };
  }

  factory ServerModel.fromMap(Map<String, dynamic> map) {
    return ServerModel(
      name: map['name'] as String,
      endpoint: map['endpoint'] as String,
      secret: map['secret'] as String,
      port: map['port'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServerModel.fromJson(String source) =>
      ServerModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ServerModel(name: $name, endpoint: $endpoint, secret: $secret, port: $port)';
  }

  @override
  bool operator ==(covariant ServerModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.endpoint == endpoint &&
        other.secret == secret &&
        other.port == port;
  }

  @override
  int get hashCode {
    return name.hashCode ^ endpoint.hashCode ^ secret.hashCode ^ port.hashCode;
  }
}

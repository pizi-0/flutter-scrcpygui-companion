import 'dart:io';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt_decrypt_plus/encrypt_decrypt/xor.dart';
import 'package:scrcpygui_companion/models/companion_server/client_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/auth_payload.dart';
import 'package:scrcpygui_companion/models/server_model.dart';

class ServerUtils {
  static final ServerUtils _instance = ServerUtils._internal();

  factory ServerUtils() {
    return _instance;
  }

  ServerUtils._internal();

  late Socket socket;

  connect(ServerModel server) async {
    socket = await Socket.connect(server.ip, server.port, timeout: 5.seconds);
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final deviceName = androidInfo.name;
    final deviceModel = androidInfo.model;

    socket.write(
      '${AuthPayload(deviceName: deviceName, deviceModel: deviceModel, apikey: XOR().xorEncode(server.secret)).toJson()}\n',
    );
  }

  disconnect() async {
    await socket.close();
  }

  sendMessage(ClientPayload message) {
    socket.write(message.toJson());
  }
}

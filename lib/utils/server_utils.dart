import 'dart:io';

import 'package:encrypt_decrypt_plus/encrypt_decrypt/xor.dart';
import 'package:scrcpygui_companion/models/companion_server/client_payload.dart';
import 'package:scrcpygui_companion/models/server_model.dart';

class ServerUtils {
  static final ServerUtils _instance = ServerUtils._internal();

  factory ServerUtils() {
    return _instance;
  }

  ServerUtils._internal();

  late Socket socket;

  connect(ServerModel server) async {
    socket = await Socket.connect(server.ip, server.port);

    socket.write(XOR().xorEncode(server.secret));
  }

  disconnect() async {
    await socket.close();
  }

  sendMessage(ClientPayload message) {
    socket.write(message.toJson());
  }
}

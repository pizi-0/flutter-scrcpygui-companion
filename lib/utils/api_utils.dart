import 'dart:convert';

import 'package:encrypt_decrypt_plus/encrypt_decrypt/xor.dart';
import 'package:scrcpygui_companion/models/adb_devices.dart';
import 'package:scrcpygui_companion/models/app_config_pair.dart';
import 'package:scrcpygui_companion/models/scrcpy_instance.dart';
import 'package:scrcpygui_companion/models/server_model.dart';
import 'package:http/http.dart';

import '../models/scrcpy_config.dart';

class ApiUtils {
  static Future<List<AdbDevices>> getDevices(ServerModel server) async {
    List<AdbDevices> devices = [];

    final endpoint = 'http://${server.endpoint}:${server.port}/devices';

    final res = await get(
      Uri.parse(endpoint),
      headers: {'x-api-key': XOR().xorEncode(server.secret)},
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body);

    for (final d in json) {
      devices.add(AdbDevices.fromJson(d));
    }

    return devices;
  }

  static Future<void> disconnectDevice(
    ServerModel server,
    AdbDevices device,
  ) async {
    final devices = await getDevices(server);

    if (devices.contains(device)) {
      final endpoint =
          'http://${server.endpoint}:${server.port}/devices/disconnect?deviceId=${device.id}';
      final res = await post(
        Uri.parse(endpoint),
        headers: {'x-api-key': XOR().xorEncode(server.secret)},
      );

      if (res.statusCode != 200) {
        throw Exception('${res.statusCode} ${res.body}');
      }
    }
  }

  static Future<List<ScrcpyConfig>> getConfigs(ServerModel server) async {
    List<ScrcpyConfig> configs = [];

    final endpoint = 'http://${server.endpoint}:${server.port}/configs';
    final res = await get(
      Uri.parse(endpoint),
      headers: {'x-api-key': XOR().xorEncode(server.secret)},
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body);

    for (final d in json) {
      configs.add(ScrcpyConfig.fromJson(d));
    }

    return configs;
  }

  static Future<List<AppConfigPair>> getPinnedApps(
    ServerModel server,
    AdbDevices device,
  ) async {
    List<AppConfigPair> pairs = [];

    final endpoint =
        'http://${server.endpoint}:${server.port}/pinned-apps?deviceId=${device.id}';
    final res = await get(
      Uri.parse(endpoint),
      headers: {'x-api-key': XOR().xorEncode(server.secret)},
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body);

    for (final p in json) {
      pairs.add(AppConfigPair.fromMap(p));
    }

    return pairs;
  }

  static Future<List<ScrcpyInstance>> getInstances(
    ServerModel server, {
    AdbDevices? device,
  }) async {
    List<ScrcpyInstance> instances = [];

    var endpoint = 'http://${server.endpoint}:${server.port}/running';

    if (device != null) {
      endpoint += '?deviceId=${device.id}';
    }

    final res = await get(
      Uri.parse(endpoint),
      headers: {'x-api-key': XOR().xorEncode(server.secret)},
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body);

    for (final d in json) {
      instances.add(ScrcpyInstance.fromMap(d));
    }

    return instances;
  }

  static Future<void> startConfig(
    ServerModel server,
    AdbDevices device,
    ScrcpyConfig config,
  ) async {
    final url =
        'http://${server.endpoint}:${server.port}/scrcpy/start?deviceId=${device.id}&configId=${config.id}';

    final res = await post(
      Uri.parse(url),
      headers: {'x-api-key': XOR().xorEncode(server.secret)},
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> stopConfig(ServerModel server, String pid) async {
    final url = 'http://${server.endpoint}:${server.port}/scrcpy/stop?pid=$pid';

    final res = await post(
      Uri.parse(url),
      headers: {'x-api-key': XOR().xorEncode(server.secret)},
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> startPinnedApp(
    ServerModel server,
    AppConfigPair pair,
  ) async {
    final url =
        'http://${server.endpoint}:${server.port}/scrcpy/start/pinned-app?pair=${pair.hash}';

    final res = await post(
      Uri.parse(url),
      headers: {'x-api-key': XOR().xorEncode(server.secret)},
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }
  }
}

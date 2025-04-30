import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:scrcpygui_companion/models/adb_devices.dart';
import 'package:scrcpygui_companion/models/scrcpy_instance.dart';
import 'package:scrcpygui_companion/models/server_model.dart';
import 'package:http/http.dart';

import '../models/scrcpy_config.dart';

class ApiUtils {
  static Future<List<AdbDevices>> getDevices(ServerModel server) async {
    try {
      List<AdbDevices> devices = [];

      final endpoint = 'http://${server.endpoint}:${server.port}/devices';
      final res = await get(
        Uri.parse(endpoint),
        headers: {'x-api-key': server.secret},
      );

      final json = jsonDecode(res.body);

      for (final d in json) {
        devices.add(AdbDevices.fromJson(d));
      }

      return devices;
    } catch (e) {
      debugPrint(e.toString());

      return [];
    }
  }

  static Future<List<ScrcpyConfig>> getConfigs(ServerModel server) async {
    try {
      List<ScrcpyConfig> configs = [];

      final endpoint = 'http://${server.endpoint}:${server.port}/configs';
      final res = await get(
        Uri.parse(endpoint),
        headers: {'x-api-key': server.secret},
      );

      final json = jsonDecode(res.body);

      for (final d in json) {
        configs.add(ScrcpyConfig.fromJson(d));
      }

      return configs;
    } catch (e) {
      debugPrint(e.toString());

      return [];
    }
  }

  static Future<List<ScrcpyInstance>> getInstances(ServerModel server) async {
    try {
      List<ScrcpyInstance> instances = [];

      final endpoint = 'http://${server.endpoint}:${server.port}/running';
      final res = await get(
        Uri.parse(endpoint),
        headers: {'x-api-key': server.secret},
      );

      final json = jsonDecode(res.body);

      for (final d in json) {
        instances.add(ScrcpyInstance.fromMap(d));
      }

      return instances;
    } catch (e) {
      debugPrint(e.toString());

      return [];
    }
  }

  static Future<void> startConfig(
    ServerModel server,
    AdbDevices device,
    ScrcpyConfig config,
  ) async {
    try {
      final url =
          'http://${server.endpoint}:${server.port}/scrcpy/start?deviceId=${device.id}&configId=${config.id}';
      await post(Uri.parse(url), headers: {'x-api-key': server.secret});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> stopConfig(ServerModel server, String pid) async {
    try {
      final url =
          'http://${server.endpoint}:${server.port}/scrcpy/stop?pid=$pid';

      await post(Uri.parse(url), headers: {'x-api-key': server.secret});
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

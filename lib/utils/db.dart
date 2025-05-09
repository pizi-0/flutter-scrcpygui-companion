import 'package:scrcpygui_companion/utils/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_model.dart';

class Db {
  static clearPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<List<ServerModel>> getServerList() async {
    final prefs = await SharedPreferences.getInstance();
    final servers =
        (prefs.getStringList(PKEY_SERVER_LIST) ?? [])
            .map((server) => ServerModel.fromJson(server))
            .toList();

    return servers;
  }

  static Future<void> saveServers(List<ServerModel> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final serverList = servers.map((server) => server.toJson()).toList();
    await prefs.setStringList(PKEY_SERVER_LIST, serverList);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/server_model.dart';
import 'package:scrcpygui_companion/provider/data_provider.dart';

class ServerNotifier extends Notifier<ServerModel?> {
  @override
  build() {
    return null;
  }

  setServer(ServerModel? server) {
    ref.read(devicesProvider.notifier).state = [];
    state = server;
  }
}

final serverProvider = NotifierProvider<ServerNotifier, ServerModel?>(
  () => ServerNotifier(),
);

class ServerListNotifier extends Notifier<List<ServerModel>> {
  @override
  build() {
    return [];
  }

  setServerList(List<ServerModel> servers) {
    state = servers;
  }

  addServer(ServerModel server) {
    state = [...state.where((s) => s.ip != server.ip), server];
  }

  removeServer(ServerModel server) {
    state = state.where((element) => element.ip != server.ip).toList();
  }

  updateServer(ServerModel server) {
    state = state.map((e) => e.ip == server.ip ? server : e).toList();
  }
}

final serverListProvider =
    NotifierProvider<ServerListNotifier, List<ServerModel>>(
      () => ServerListNotifier(),
    );

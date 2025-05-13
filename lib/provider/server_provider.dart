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
    state = [...state.where((s) => s.id != server.id), server];
  }

  removeServer(ServerModel server) {
    state = state.where((element) => element.id != server.id).toList();
  }

  updateServer(ServerModel server) {
    state = state.map((e) => e.id == server.id ? server : e).toList();
  }
}

final serverListProvider =
    NotifierProvider<ServerListNotifier, List<ServerModel>>(
      () => ServerListNotifier(),
    );

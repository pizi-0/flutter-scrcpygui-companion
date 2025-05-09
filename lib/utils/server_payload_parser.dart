import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/companion_server/data/device_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/instance_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/pairs_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/server_payload.dart';
import 'package:scrcpygui_companion/provider/data_provider.dart';

import '../models/companion_server/data/config_payload.dart';

class ServerParser {
  static parse(WidgetRef ref, {required ServerPayload serverPayload}) {
    switch (serverPayload.type) {
      case ServerPayloadType.initialData:
        final List<ServerPayload> payloads =
            (jsonDecode(serverPayload.payload) as List)
                .map((p) => ServerPayload.fromJson(p))
                .toList();

        for (final payload in payloads) {
          parse(ref, serverPayload: payload);
        }
        break;

      case ServerPayloadType.devices:
        final jsonList = jsonDecode(serverPayload.payload);
        final deviceList = <DevicePayload>[];
        for (final device in jsonList) {
          deviceList.add(DevicePayload.fromJson(device));
        }

        ref.read(devicesProvider.notifier).update((state) => deviceList);
        break;
      case ServerPayloadType.configs:
        final jsonList = jsonDecode(serverPayload.payload);
        final configList = <ConfigPayload>[];
        for (final config in jsonList) {
          configList.add(ConfigPayload.fromJson(config));
        }

        ref.read(configsProvider.notifier).update((state) => configList);
        break;
      case ServerPayloadType.runnings:
        final jsonList = jsonDecode(serverPayload.payload);
        final runningList = <InstancePayload>[];
        for (final running in jsonList) {
          runningList.add(InstancePayload.fromJson(running));
        }

        ref.read(instancesProvider.notifier).update((state) => runningList);
        break;

      case ServerPayloadType.pairs:
        final jsonList = jsonDecode(serverPayload.payload);
        final pairList = <PairsPayload>[];
        for (final pair in jsonList) {
          pairList.add(PairsPayload.fromJson(pair));
        }

        ref.read(pinnedAppProvider.notifier).update((state) => pairList);
        break;
    }
  }
}

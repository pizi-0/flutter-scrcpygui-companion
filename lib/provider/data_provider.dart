import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/companion_server/data/config_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/device_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/instance_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/pairs_payload.dart';

final devicesProvider = StateProvider<List<DevicePayload>>((ref) => []);

final configsProvider = StateProvider<List<ConfigPayload>>((ref) => []);

final instancesProvider = StateProvider<List<InstancePayload>>((ref) => []);

final pinnedAppProvider = StateProvider<List<PairsPayload>>((ref) => []);

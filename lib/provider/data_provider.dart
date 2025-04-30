import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config_pair.dart';

final devicesProvider = StateProvider((ref) => []);

final configsProvider = StateProvider((ref) => []);

final instancesProvider = StateProvider((ref) => []);

final pinnedAppProvider = StateProvider<List<AppConfigPair>>((ref) => []);

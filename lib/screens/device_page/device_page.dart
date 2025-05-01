import 'dart:async';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/adb_devices.dart';
import 'package:scrcpygui_companion/models/app_config_pair.dart';
import 'package:scrcpygui_companion/models/scrcpy_config.dart';
import 'package:scrcpygui_companion/models/scrcpy_instance.dart';
import 'package:scrcpygui_companion/models/server_model.dart';
import 'package:scrcpygui_companion/provider/data_provider.dart';
import 'package:scrcpygui_companion/utils/api_utils.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../provider/server_provider.dart';

const String _adbMdns = '_adb-tls-connect._tcp';

class DevicePage extends ConsumerStatefulWidget {
  final AdbDevices device;
  const DevicePage({super.key, required this.device});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DevicePageState();
}

class _DevicePageState extends ConsumerState<DevicePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = false;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  _refreshData() async {
    try {
      setState(() => loading = true);
      final server = ref.read(serverProvider)!;
      final device = widget.device;

      switch (_tabController.index) {
        case 0:
          ref
              .read(pinnedAppProvider.notifier)
              .state = await ApiUtils.getPinnedApps(server, device);
          break;
        case 1:
          ref.read(configsProvider.notifier).state = await ApiUtils.getConfigs(
            server,
          );
          break;

        default:
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final isWireless = device.id.contains(_adbMdns) || device.id.isIpv4;

    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Row(
            spacing: 8,
            children: [
              Icon(
                isWireless ? Icons.wifi_rounded : Icons.usb_rounded,
                size: 18,
              ),
              Expanded(
                child: Text(
                  device.name ?? device.modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Text(
            device.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ).fontSize(12),
          contentPadding: EdgeInsets.zero,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Pinned apps'),
            ),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Configs')),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Running')),
          ],
        ),

        actions: [
          IgnorePointer(
            ignoring: _tabController.index == 2,
            child: AnimatedOpacity(
              duration: 200.milliseconds,
              opacity: _tabController.index < 2 ? 1 : 0,
              child: IconButton(
                onPressed: loading ? null : _refreshData,
                icon:
                    loading
                        ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(),
                        )
                        : Icon(Icons.refresh_rounded),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,

        children: [
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: PinnedAppsTab(device: device),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: ConfigTab(device: device),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: InstanceTab(device: device),
          ),
        ],
      ),
    );
  }
}

class ConfigTab extends ConsumerStatefulWidget {
  final AdbDevices device;
  const ConfigTab({super.key, required this.device});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  bool loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getConfigs();
    });
  }

  _getConfigs() async {
    setState(() => loading = true);
    ref.read(configsProvider.notifier).state = await ApiUtils.getConfigs(
      ref.read(serverProvider)!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverProvider)!;
    final configs = ref.watch(configsProvider);

    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];

        return ConfigListTile(
          config: config,
          server: server,
          device: widget.device,
        );
      },
    );
  }
}

class PinnedAppsTab extends ConsumerStatefulWidget {
  final AdbDevices device;
  const PinnedAppsTab({super.key, required this.device});

  @override
  ConsumerState<PinnedAppsTab> createState() => _PinnedAppsTabState();
}

class _PinnedAppsTabState extends ConsumerState<PinnedAppsTab> {
  bool loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getPinnedApps();
    });
  }

  _getPinnedApps() async {
    setState(() => loading = true);
    ref.read(pinnedAppProvider.notifier).state = await ApiUtils.getPinnedApps(
      ref.read(serverProvider)!,
      widget.device,
    );
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverProvider);
    final List<AppConfigPair> pinnedApps = ref.watch(pinnedAppProvider);

    if (loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (pinnedApps.isEmpty) {
      return Center(child: Text('No pinned apps.'));
    }

    return ListView.builder(
      itemCount: pinnedApps.length,
      itemBuilder: (context, index) {
        final pinned = pinnedApps[index];

        return PinnedAppsListTile(server: server!, pinned: pinned);
      },
    );
  }
}

class PinnedAppsListTile extends StatefulWidget {
  final ServerModel server;
  final AppConfigPair pinned;
  const PinnedAppsListTile({
    super.key,
    required this.pinned,
    required this.server,
  });

  @override
  State<PinnedAppsListTile> createState() => _PinnedAppsListTileState();
}

class _PinnedAppsListTileState extends State<PinnedAppsListTile> {
  bool loading = false;

  _start() async {
    setState(() => loading = true);
    try {
      await ApiUtils.startPinnedApp(widget.server, widget.pinned);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(widget.pinned.app.name),
        subtitle: Text('On: ${widget.pinned.config.configName}').fontSize(12),
        trailing: IconButton(
          onPressed: _start,
          icon:
              loading
                  ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(),
                  )
                  : Icon(Icons.play_arrow_rounded),
        ),
      ),
    );
  }
}

class ConfigListTile extends StatefulWidget {
  const ConfigListTile({
    super.key,
    required this.config,
    required this.server,
    required this.device,
  });

  final ScrcpyConfig config;
  final ServerModel server;
  final AdbDevices device;

  @override
  State<ConfigListTile> createState() => _ConfigListTileState();
}

class _ConfigListTileState extends State<ConfigListTile> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ListTile(
          title: Text(widget.config.configName),
          trailing: IconButton(
            onPressed: () async {
              try {
                setState(() => loading = true);
                await ApiUtils.startConfig(
                  widget.server,
                  widget.device,
                  widget.config,
                );
              } catch (e) {
                debugPrint(e.toString());
              } finally {
                if (mounted) {
                  setState(() => loading = false);
                }
              }
            },
            icon:
                loading
                    ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(),
                    )
                    : Icon(Icons.play_arrow_rounded),
          ),
        ),
      ),
    );
  }
}

class InstanceTab extends ConsumerStatefulWidget {
  final AdbDevices device;
  const InstanceTab({super.key, required this.device});

  @override
  ConsumerState<InstanceTab> createState() => _InstanceTabState();
}

class _InstanceTabState extends ConsumerState<InstanceTab> {
  bool loading = false;
  List<ScrcpyInstance> instances = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getRunning();
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _getRunning(noLoading: true);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverProvider)!;

    return CustomScrollView(
      slivers: [
        if (loading)
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),

        if (instances.isEmpty && !loading)
          SliverFillRemaining(child: Center(child: Text('No running scrcpy.'))),

        if (instances.isNotEmpty)
          SliverList.builder(
            itemCount: instances.length,
            itemBuilder: (context, index) {
              final instance = instances[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ListTile(
                    title: Text(instance.name),
                    trailing: IconButton(
                      onPressed:
                          () => ApiUtils.stopConfig(server, instance.pid),
                      icon: Icon(Icons.stop_rounded),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  _getRunning({bool noLoading = false}) async {
    if (!noLoading) {
      setState(() => loading = true);
    }
    try {
      final inst = await ApiUtils.getInstances(ref.read(serverProvider)!);

      instances = inst.where((i) => i.device == widget.device.id).toList();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }
}

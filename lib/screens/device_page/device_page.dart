import 'dart:async';
import 'dart:convert';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/companion_server/client_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/config_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/device_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/pairs_payload.dart';
import 'package:scrcpygui_companion/provider/data_provider.dart';
import 'package:scrcpygui_companion/utils/server_utils.dart';
import 'package:string_extensions/string_extensions.dart';

const String _adbMdns = '_adb-tls-connect._tcp';

class DevicePage extends ConsumerStatefulWidget {
  final DevicePayload device;
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
                  device.name,
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
  final DevicePayload device;
  const ConfigTab({super.key, required this.device});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final configs = ref.watch(configsProvider);

    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];

        return ConfigListTile(config: config, device: widget.device);
      },
    );
  }
}

class PinnedAppsTab extends ConsumerStatefulWidget {
  final DevicePayload device;
  const PinnedAppsTab({super.key, required this.device});

  @override
  ConsumerState<PinnedAppsTab> createState() => _PinnedAppsTabState();
}

class _PinnedAppsTabState extends ConsumerState<PinnedAppsTab> {
  bool loading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<PairsPayload> pinnedApps =
        ref
            .watch(pinnedAppProvider)
            .where((p) => p.deviceId == widget.device.id)
            .toList();

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

        return PinnedAppsListTile(pinned: pinned);
      },
    );
  }
}

class PinnedAppsListTile extends StatefulWidget {
  final PairsPayload pinned;
  const PinnedAppsListTile({super.key, required this.pinned});

  @override
  State<PinnedAppsListTile> createState() => _PinnedAppsListTileState();
}

class _PinnedAppsListTileState extends State<PinnedAppsListTile> {
  bool loading = false;

  _start() async {
    setState(() => loading = true);
    try {
      final server = ServerUtils();
      await server.sendMessage(
        ClientPayload(
          action: ClientAction.startAppConfigPair,
          payload: jsonEncode({'hash': widget.pinned.hash}),
        ),
      );
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
        title: Text(widget.pinned.name),
        subtitle: Text('On: ${widget.pinned.config.name}').fontSize(12),
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
  const ConfigListTile({super.key, required this.config, required this.device});

  final ConfigPayload config;
  final DevicePayload device;

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
          title: Text(widget.config.name),
          trailing: IconButton(
            onPressed: () async {
              try {
                setState(() => loading = true);
                final server = ServerUtils();
                await server.sendMessage(
                  ClientPayload(
                    action: ClientAction.startScrcpy,
                    payload: jsonEncode({
                      'deviceId': widget.device.id,
                      'configId': widget.config.id,
                    }),
                  ),
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
  final DevicePayload device;
  const InstanceTab({super.key, required this.device});

  @override
  ConsumerState<InstanceTab> createState() => _InstanceTabState();
}

class _InstanceTabState extends ConsumerState<InstanceTab> {
  bool loading = false;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final instances =
        ref
            .watch(instancesProvider)
            .where((i) => i.deviceId == widget.device.id)
            .toList();

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
                      onPressed: () async {
                        final server = ServerUtils();
                        await server.sendMessage(
                          ClientPayload(
                            action: ClientAction.killScrcpy,
                            payload: jsonEncode({'pid': instance.pid}),
                          ),
                        );
                      },
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
}

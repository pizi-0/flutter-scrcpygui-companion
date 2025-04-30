import 'dart:async';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/adb_devices.dart';
import 'package:scrcpygui_companion/models/scrcpy_config.dart';
import 'package:scrcpygui_companion/models/scrcpy_instance.dart';
import 'package:scrcpygui_companion/models/server_model.dart';
import 'package:scrcpygui_companion/utils/api_utils.dart';

import '../../provider/server_provider.dart';

class DevicePage extends ConsumerStatefulWidget {
  final AdbDevices device;
  const DevicePage({super.key, required this.device});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DevicePageState();
}

class _DevicePageState extends ConsumerState<DevicePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name ?? device.modelName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Configs')),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Running')),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.refresh_rounded)),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
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

class ConfigTab extends ConsumerWidget {
  final AdbDevices device;
  const ConfigTab({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(serverProvider)!;

    return FutureBuilder(
      future: ApiUtils.getConfigs(server),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final configs = snapshot.data!;

        return ListView.builder(
          itemCount: configs.length,
          itemBuilder: (context, index) {
            final config = configs[index];

            return ConfigListTile(
              config: config,
              server: server,
              device: device,
            );
          },
        );
      },
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
                await Future.delayed(500.milliseconds);
                setState(() => loading = false);
              } catch (e) {
                debugPrint(e.toString());
                setState(() => loading = false);
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

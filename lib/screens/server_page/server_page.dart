import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/adb_devices.dart';
import 'package:scrcpygui_companion/models/scrcpy_config.dart';
import 'package:scrcpygui_companion/utils/api_utils.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../provider/server_provider.dart';
import '../device_page/device_page.dart';

const String _adbMdns = '_adb-tls-connect._tcp';

class ServerPage extends ConsumerStatefulWidget {
  const ServerPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  bool loading = false;
  List<AdbDevices> devices = [];
  List<ScrcpyConfig> configs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(server?.name ?? ''),
        actions: [
          IconButton(onPressed: _getData, icon: Icon(Icons.refresh_rounded)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (devices.isEmpty && !loading)
            const SliverFillRemaining(
              child: Center(child: Text('No devices found')),
            ),

          if (devices.isNotEmpty)
            SliverList.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];

                return DeviceListTile(d: d);
              },
            ),
        ],
      ),
    );
  }

  _getData() async {
    final server = ref.read(serverProvider)!;

    setState(() => loading = true);

    try {
      devices = await ApiUtils.getDevices(server);
      configs = await ApiUtils.getConfigs(server);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }
}

class DeviceListTile extends StatelessWidget {
  const DeviceListTile({super.key, required this.d});

  final AdbDevices d;

  @override
  Widget build(BuildContext context) {
    final isWireless = d.id.contains(_adbMdns) || d.id.isIpv4;
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DevicePage(device: d)),
            ),
        leading:
            isWireless ? Icon(Icons.wifi_rounded) : Icon(Icons.usb_rounded),
        title: Text(d.name ?? d.modelName),
        subtitle: Text(d.id, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

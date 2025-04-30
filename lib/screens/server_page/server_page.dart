// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/models/adb_devices.dart';
import 'package:scrcpygui_companion/utils/api_utils.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../provider/data_provider.dart';
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
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text(server!.name),
          subtitle: Text('${server.endpoint}:${server.port}').fontSize(12),
          contentPadding: EdgeInsets.zero,
        ),
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
      ref.read(devicesProvider.notifier).state = await ApiUtils.getDevices(
        server,
      );
    } on SocketException catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text('Make sure companion server is started on Scrcpy GUI'),
                  Text('Error: ${e.message}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
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
        subtitle: Text(
          d.id,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).fontSize(12),
      ),
    );
  }
}

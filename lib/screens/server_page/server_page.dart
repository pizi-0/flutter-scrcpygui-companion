// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scrcpygui_companion/models/adb_devices.dart';
import 'package:scrcpygui_companion/models/scrcpy_instance.dart';
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
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getData();
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _getData(noLoading: true);
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
    final server = ref.watch(serverProvider);
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text(server!.name),
          subtitle: Text('${server.endpoint}:${server.port}').fontSize(12),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          if (loading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          if (devices.isEmpty && !loading) const SliverFillRemaining(child: Center(child: Text('No devices found'))),

          if (devices.isNotEmpty)
            SliverList.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];

                if (index == devices.length - 1) {
                  return Column(
                    children: [
                      DeviceListTile(device: d),
                      Divider(endIndent: 10, indent: 10),
                      Text(
                        'Swipe left/right to disconnect device.',
                      ).textColor(Theme.of(context).colorScheme.onSurface.withAlpha(100)),
                    ],
                  );
                }

                return DeviceListTile(device: d);
              },
            ),
        ],
      ),
    );
  }

  _getData({bool noLoading = false}) async {
    final server = ref.read(serverProvider)!;

    if (!noLoading) {
      setState(() => loading = true);
    }

    try {
      ref.read(devicesProvider.notifier).state = await ApiUtils.getDevices(server);
    } on SocketException catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [Text('Message: ${e.message}'), Text('Make sure companion server is started on Scrcpy GUI')],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: Text('OK')),
              ],
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: Text('Error'),
              content: Text(e.toString()),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
            ),
      );
    } finally {
      if (mounted) {
        if (!noLoading) {
          setState(() => loading = false);
        }
      }
    }
  }
}

class DeviceListTile extends ConsumerStatefulWidget {
  final AdbDevices device;
  const DeviceListTile({super.key, required this.device});

  @override
  ConsumerState<DeviceListTile> createState() => _DeviceListTileState();
}

class _DeviceListTileState extends ConsumerState<DeviceListTile> with SingleTickerProviderStateMixin {
  bool loading = false;
  SlidableController? slidableController;

  @override
  void initState() {
    slidableController = SlidableController(this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    slidableController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWireless = widget.device.id.contains(_adbMdns) || widget.device.id.isIpv4;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Slidable(
        controller: slidableController,
        key: ValueKey(widget.device),
        enabled: isWireless,
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (a) => _disconnect(),
              backgroundColor: theme.colorScheme.errorContainer,
              icon: Icons.link_off_rounded,
              label: 'Disconnect',
            ),
          ],
        ),
        startActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (a) => _disconnect(),
              backgroundColor: theme.colorScheme.errorContainer,
              icon: Icons.link_off_rounded,
              label: 'Disconnect',
            ),
          ],
        ),
        child: ListTile(
          onTap: () {
            if (slidableController!.ratio != 0.0) {
              slidableController!.close();
              return;
            }

            Navigator.push(context, MaterialPageRoute(builder: (context) => DevicePage(device: widget.device)));
          },
          leading: isWireless ? Icon(Icons.wifi_rounded) : Icon(Icons.usb_rounded),
          title: Text(widget.device.name ?? widget.device.modelName),
          subtitle: Text(widget.device.id, maxLines: 1, overflow: TextOverflow.ellipsis).fontSize(12),
        ),
      ),
    );
  }

  _disconnect() async {
    setState(() => loading = true);
    final server = ref.read(serverProvider)!;

    final List<ScrcpyInstance> instances = await ApiUtils.getInstances(server, device: widget.device);

    final bool res =
        (await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                title: Text('Disconnect ${widget.device.name ?? widget.device.modelName}?'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (instances.isNotEmpty)
                      Text(
                        '${widget.device.name ?? widget.device.modelName} has running scrcpy.\n\nDisconnecting will kill the running scrcpy.',
                      ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Disconnect')),
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                ],
              ),
        )) ??
        false;

    if (!res) {
      setState(() => loading = false);
      return;
    }

    try {
      await ApiUtils.disconnectDevice(server, widget.device);
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Error'),
              content: Text(e.toString()),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
            ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}

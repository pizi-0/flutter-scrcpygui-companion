// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scrcpygui_companion/models/companion_server/client_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/device_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/error_payload.dart';
import 'package:scrcpygui_companion/models/companion_server/data/instance_payload.dart';
import 'package:scrcpygui_companion/utils/server_payload_parser.dart';
import 'package:scrcpygui_companion/utils/server_utils.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../models/companion_server/server_payload.dart';
import '../../models/server_model.dart';
import '../../provider/data_provider.dart';
import '../device_page/device_page.dart';

const String _adbMdns = '_adb-tls-connect._tcp';

class ServerPage extends ConsumerStatefulWidget {
  final ServerModel server;
  const ServerPage({super.key, required this.server});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  bool loading = false;

  ServerUtils server = ServerUtils();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServer();
    });
  }

  @override
  void dispose() {
    server.socket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
    final devices = ref.watch(devicesProvider).reversed.toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text(server.name),
          subtitle: Text(
            '${server.ip}:${server.port}',
            style: theme.textTheme.bodySmall,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.add_link_rounded),
            label: Text('Connect Device'),
            onPressed: _showConnectDialog,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: 12,
              ), // Adjust padding for better look
              textStyle: theme.textTheme.titleMedium, // Make text a bit larger
            ),
          ),
        ),
      ),

      body: CustomScrollView(
        reverse: true,
        slivers: [
          if (loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (devices.isEmpty && !loading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phonelink_off_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                    SizedBox(height: 16),
                    Text('No devices found'),
                  ],
                ),
              ),
            ),

          if (devices.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.only(bottom: 8)),
            ),
            SliverList.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                return DeviceListTile(device: d);
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 24.0,
                ),
                child: Center(
                  child: Text(
                    'Swipe left/right to disconnect wireless devices.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _initServer() async {
    bool isBlocked = false;
    bool isUnAuthd = false;
    late ErrorPayload errorPayload;

    server.socket.listen(
      (data) {
        final decoded = utf8.decode(data);
        final decodedLines = decoded.splitLines();

        decodedLines.removeWhere((element) => element.isEmpty);

        final serverPayload = ServerPayload.fromJson(decodedLines.last);

        final res = ServerParser.parse(ref, serverPayload: serverPayload);

        if (res is ErrorPayload) {
          isBlocked = res.type == ErrorType.blocked;
          isUnAuthd = res.type == ErrorType.invalidAuth;
          errorPayload = res;

          if (isBlocked || isUnAuthd) {
            return;
          }

          showDialog(
            context: context,
            builder:
                (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  title: Text('Error'),
                  content: Text(res.message),
                  actions: [
                    TextButton(
                      onPressed:
                          () =>
                              res.type != ErrorType.blocked
                                  ? Navigator.popUntil(
                                    context,
                                    (route) => route.isFirst,
                                  )
                                  : Navigator.pop(dialogContext),
                      child: Text('Ok'),
                    ),
                  ],
                ),
          );
        }
      },
      onDone: () {
        ref.read(devicesProvider.notifier).update((state) => []);
        Navigator.popUntil(context, (route) => route.isFirst);

        if (isUnAuthd || isBlocked) {
          showDialog(
            context: context,
            builder:
                (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  title: Text('Error'),
                  content: Text(errorPayload.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),

                      child: Text('Ok'),
                    ),
                  ],
                ),
          );
        }
      },
      onError: (e, t) {
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      cancelOnError: true,
    );
  }

  _showConnectDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ConnectWithIpDialog(),
    );
  }
}

class ConnectWithIpDialog extends ConsumerStatefulWidget {
  const ConnectWithIpDialog({super.key});

  @override
  ConsumerState<ConnectWithIpDialog> createState() =>
      _ConnectWithIpDialogState();
}

class _ConnectWithIpDialogState extends ConsumerState<ConnectWithIpDialog> {
  final TextEditingController ipController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          TextField(
            autofocus: true,
            controller: ipController,
            onChanged: (value) {
              if (value.isIpv4) {
                setState(() {});
              }
            },
            onSubmitted: (value) => _connect(),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text('ip:port'),
              isDense: true,
            ),
          ),
          Row(
            spacing: 8,
            children: [
              Icon(Icons.info_rounded, size: 15),
              Expanded(
                // Added Expanded for long text
                child: Text(
                  'Port defaults to 5555 if unspecified.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(200),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      title: Text('Connect device'),
      actions: [
        if (ipController.text.isIpv4)
          TextButton(onPressed: _connect, child: Text('Connect')),
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  _connect() async {
    setState(() => loading = true);

    try {
      final server = ServerUtils();

      await server.sendMessage(
        ClientPayload(
          action: ClientAction.connectDevice,
          payload: jsonEncode({'ip': ipController.text.trim()}),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}

class DeviceListTile extends ConsumerStatefulWidget {
  final DevicePayload device;
  const DeviceListTile({super.key, required this.device});

  @override
  ConsumerState<DeviceListTile> createState() => _DeviceListTileState();
}

class _DeviceListTileState extends ConsumerState<DeviceListTile>
    with SingleTickerProviderStateMixin {
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
    final isWireless =
        widget.device.id.contains(_adbMdns) || widget.device.id.isIpv4;
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

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DevicePage(device: widget.device),
              ),
            );
          },
          leading:
              isWireless ? Icon(Icons.wifi_rounded) : Icon(Icons.usb_rounded),
          title: Text(widget.device.name),
          subtitle: Text(
            widget.device.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Keep this
            style: Theme.of(context).textTheme.bodySmall, // Use theme style
          ),
        ),
      ),
    );
  }

  _disconnect() async {
    setState(() => loading = true);

    final List<InstancePayload> instances =
        ref
            .read(instancesProvider)
            .where((i) => i.deviceId == widget.device.id)
            .toList();

    final bool res =
        (await showDialog(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                title: Text('Disconnect ${widget.device.name}?'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (instances.isNotEmpty)
                      Text(
                        '${widget.device.name} has running scrcpy.\n\nDisconnecting will kill the running scrcpy.',
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text('Disconnect'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text('Cancel'),
                  ),
                ],
              ),
        )) ??
        false;

    if (!res) {
      setState(() => loading = false);
      return;
    }

    try {
      final server = ServerUtils();

      await server.sendMessage(
        ClientPayload(
          action: ClientAction.disconnectDevice,
          payload: jsonEncode({'deviceId': widget.device.id}),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                // Added for consistency
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}

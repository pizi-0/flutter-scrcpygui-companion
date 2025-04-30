// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/screens/server_page/server_page.dart';
import 'package:scrcpygui_companion/utils/db.dart';

import '../../../models/server_model.dart';
import '../../../provider/server_provider.dart';

class ConnectDialog extends ConsumerStatefulWidget {
  const ConnectDialog({super.key, required this.server});

  final ServerModel server;

  @override
  ConsumerState<ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends ConsumerState<ConnectDialog> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text('Connect'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400, minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server name: ${widget.server.name}'),
            Text('Endpoint: ${widget.server.endpoint}:${widget.server.port}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : _connect,
          child: Text('Connect'),
        ),
      ],
    );
  }

  _connect() async {
    setState(() => _loading = true);

    try {
      ref.read(serverProvider.notifier).setServer(widget.server);
      ref.read(serverListProvider.notifier).addServer(widget.server);

      await Db.saveServers(ref.read(serverListProvider));

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ServerPage()),
      );
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context);
      }
    }
  }
}

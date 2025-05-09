// ignore_for_file: use_build_context_synchronously

import 'package:awesome_extensions/awesome_extensions_flutter.dart';
import 'package:encrypt_decrypt_plus/encrypt_decrypt/xor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrcpygui_companion/provider/server_provider.dart';
import 'package:scrcpygui_companion/screens/server_page/server_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scrcpygui_companion/utils/server_utils.dart';

import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../models/server_model.dart';
import '../../utils/db.dart';
import 'widgets/connect_dialog.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  bool loading = false;
  final ServerUtils server = ServerUtils();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getServerList();
      // final prefs = await SharedPreferences.getInstance();
      // prefs.remove(PKEY_SERVER_LIST);
    });
  }

  @override
  Widget build(BuildContext context) {
    final servers = ref.watch(serverListProvider);
    final theme = Theme.of(context);

    servers.reversed;

    return Scaffold(
      appBar: AppBar(title: Text('Scrcpy GUI Companion')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServer,
        child: Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          if (servers.isEmpty && !loading)
            SliverFillRemaining(
              child: Center(child: Text('No servers found.')),
            ),
          if (loading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (servers.isNotEmpty)
            SliverList.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final serv = servers[index];
                if (index == servers.length - 1) {
                  return Column(
                    children: [
                      ServerListTile(serv: serv, ref: ref),
                      Divider(endIndent: 10, indent: 10),
                      Text(
                        'Swipe left/right to delete server.',
                      ).textColor(theme.colorScheme.onSurface.withAlpha(100)),
                    ],
                  );
                }

                return ServerListTile(
                  key: ValueKey(serv),
                  serv: serv,
                  ref: ref,
                );
              },
            ),
        ],
      ),
    );
  }

  _getServerList() async {
    setState(() => loading = true);
    final servers = await Db.getServerList();
    ref.read(serverListProvider.notifier).setServerList(servers);
    setState(() => loading = false);
  }

  _addServer() async {
    try {
      setState(() => loading = true);

      String? res = await SimpleBarcodeScanner.scanBarcode(context);

      if (res != null) {
        if (res == '-1') {
          return;
        }

        final decode = XOR().xorDecode(res);

        final server = ServerModel.fromJson(decode);

        showDialog(
          context: context,
          builder: (context) => ConnectDialog(server: server),
        );
      }
    } catch (e) {
      debugPrint(e.toString());

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text('Error'),
                content: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400, minWidth: 400),
                  child: Text('Not a valid Scrcpy GUI server.'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}

class ServerListTile extends ConsumerStatefulWidget {
  const ServerListTile({super.key, required this.serv, required this.ref});

  final ServerModel serv;
  final WidgetRef ref;

  @override
  ConsumerState<ServerListTile> createState() => _ServerListTileState();
}

class _ServerListTileState extends ConsumerState<ServerListTile>
    with SingleTickerProviderStateMixin {
  late SlidableController slidableController;

  @override
  void initState() {
    slidableController = SlidableController(this);
    super.initState();
  }

  @override
  void dispose() {
    slidableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Slidable(
        controller: slidableController,
        key: ValueKey(widget.serv),
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              backgroundColor: theme.colorScheme.errorContainer,
              onPressed: (context) {
                ref.read(serverListProvider.notifier).removeServer(widget.serv);

                Db.saveServers(ref.read(serverListProvider));
              },
              icon: Icons.delete_rounded,
              label: 'Delete',
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
          ],
        ),
        startActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              backgroundColor: theme.colorScheme.errorContainer,
              onPressed: (context) {
                ref.read(serverListProvider.notifier).removeServer(widget.serv);

                Db.saveServers(ref.read(serverListProvider));
              },
              label: 'Delete',
              icon: Icons.delete_rounded,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
          ],
        ),
        child: ListTile(
          title: Text(widget.serv.name),
          subtitle: Text('${widget.serv.ip}:${widget.serv.port}').fontSize(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          trailing: Icon(Icons.chevron_right_rounded),
          onTap: () async {
            try {
              final server = ServerUtils();
              if (slidableController.ratio != 0.0) {
                slidableController.close();
                return;
              }

              await server.connect(widget.serv);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServerPage(server: widget.serv),
                ),
              );
            } on Exception catch (e) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
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
            }
          },
        ),
      ),
    );
  }
}

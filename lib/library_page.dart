import 'package:flutter/material.dart';
import 'package:usb_capture/usb_capture.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.plugin,
    required this.television,
    this.mergeEnabled,
    this.renameEnabled,
  });

  final UsbCapture plugin;
  final bool television;
  final bool? mergeEnabled;
  final bool? renameEnabled;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<SavedRecording> _items = const [];
  bool _loading = true;
  bool _merging = false;
  String? _error;

  bool get _tv => widget.television;

  bool get _mergeSupported => widget.mergeEnabled ?? true;

  bool get _renameSupported => widget.renameEnabled ?? true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.plugin.listRecordings();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on CaptureError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  bool _canMerge(SavedRecording recording) {
    if (!_mergeSupported) {
      return false;
    }
    return SegmentPolicy.canMergeSession(
      _items.map((item) => item.name),
      recording.name,
    );
  }

  Future<void> _play(SavedRecording recording) async {
    try {
      await widget.plugin.openRecording(recording.id);
    } on CaptureError catch (error) {
      if (!mounted) return;
      _snack(error.message);
    }
  }

  Future<void> _share(SavedRecording recording) async {
    if (!recording.shareAvailable) {
      _snack(LibraryCopy.shareUnavailable);
      return;
    }
    try {
      await widget.plugin.shareRecording(recording.id);
    } on CaptureError {
      if (!mounted) return;
      _snack(LibraryCopy.shareFailed);
    }
  }

  Future<void> _merge(SavedRecording recording) async {
    if (_merging) {
      return;
    }
    final parsed = SegmentPolicy.parseSegmentName(recording.name);
    if (parsed == null) {
      return;
    }
    final segments =
        SegmentPolicy.groupBySession(
          _items,
          (item) => item.name,
        )[parsed.stamp] ??
        const <SavedRecording>[];
    if (segments.length < 2) {
      return;
    }
    setState(() => _merging = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    LibraryCopy.mergeProgress,
                    style: TextStyle(fontSize: _tv ? 20 : 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    try {
      await widget.plugin.concatSession(
        sessionStamp: parsed.stamp,
        uris: segments.map((item) => item.uri).toList(),
        displayName: SegmentPolicy.mergedFileName(
          parsed.stamp,
          _items.map((item) => item.name),
        ),
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _reload();
    } on CaptureError catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack(error.message);
    } finally {
      if (mounted) {
        setState(() => _merging = false);
      }
    }
  }

  Future<void> _rename(SavedRecording recording) async {
    final controller = TextEditingController(text: recording.name);
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            LibraryCopy.renameTitle,
            style: TextStyle(fontSize: _tv ? 24 : 18),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(fontSize: _tv ? 20 : 16),
          ),
          actions: [
            TextButton(
              autofocus: _tv,
              onPressed: () => Navigator.pop(context),
              child: Text(
                LibraryCopy.cancelAction,
                style: TextStyle(fontSize: _tv ? 20 : 16),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(
                LibraryCopy.confirmAction,
                style: TextStyle(fontSize: _tv ? 20 : 16),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (submitted == null) {
      return;
    }
    final next = LibraryName.normalize(submitted);
    if (next == null) {
      if (!mounted) return;
      _snack(
        const CaptureError(
          CaptureErrorCode.unknown,
          details: 'renameInvalid',
        ).message,
      );
      return;
    }
    if (LibraryName.same(next, recording.name)) {
      return;
    }
    if (LibraryName.taken(
      _items.map((item) => item.name),
      current: recording.name,
      next: next,
    )) {
      if (!mounted) return;
      _snack(
        const CaptureError(
          CaptureErrorCode.unknown,
          details: 'renameTaken',
        ).message,
      );
      return;
    }
    try {
      await widget.plugin.renameRecording(recording.id, next);
      await _reload();
    } on CaptureError catch (error) {
      if (!mounted) return;
      _snack(error.message);
    }
  }

  Future<void> _delete(SavedRecording recording) async {
    if (!recording.deleteAvailable) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            LibraryCopy.deleteTitle,
            style: TextStyle(fontSize: _tv ? 24 : 18),
          ),
          content: Text(
            LibraryCopy.deleteConfirm,
            style: TextStyle(fontSize: _tv ? 20 : 16),
          ),
          actions: [
            TextButton(
              autofocus: _tv,
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                LibraryCopy.cancelAction,
                style: TextStyle(fontSize: _tv ? 20 : 16),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                LibraryCopy.deleteAction,
                style: TextStyle(fontSize: _tv ? 20 : 16),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await widget.plugin.deleteRecording(recording.id);
      await _reload();
    } on CaptureError catch (error) {
      if (!mounted) return;
      _snack(error.message);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final padding = _tv ? 48.0 : 16.0;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          LibraryCopy.title,
          style: TextStyle(fontSize: _tv ? 24 : 18),
        ),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 8, padding, padding),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(fontSize: _tv ? 22 : 16, color: Colors.white70),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          LibraryCopy.empty,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: _tv ? 24 : 16, color: Colors.white70),
        ),
      );
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(color: Colors.white12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          autofocus: _tv && index == 0,
          onTap: () => _play(item),
          title: Text(
            item.name,
            style: TextStyle(fontSize: _tv ? 22 : 16, color: Colors.white),
          ),
          subtitle: item.subtitle.isEmpty
              ? null
              : Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: _tv ? 18 : 13,
                    color: Colors.white70,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canMerge(item))
                IconButton(
                  tooltip: LibraryCopy.mergeAction,
                  onPressed: () => _merge(item),
                  icon: Icon(Icons.merge_type, size: _tv ? 32 : 22),
                ),
              if (_renameSupported)
                IconButton(
                  tooltip: LibraryCopy.renameAction,
                  onPressed: () => _rename(item),
                  icon: Icon(
                    Icons.drive_file_rename_outline,
                    size: _tv ? 32 : 22,
                  ),
                ),
              if (item.shareAvailable)
                IconButton(
                  tooltip: '分享',
                  onPressed: () => _share(item),
                  icon: Icon(Icons.share, size: _tv ? 32 : 22),
                )
              else
                Tooltip(
                  message: LibraryCopy.shareUnavailable,
                  child: Icon(
                    Icons.share,
                    size: _tv ? 32 : 22,
                    color: Colors.white24,
                  ),
                ),
              if (item.deleteAvailable)
                IconButton(
                  tooltip: '删除',
                  onPressed: () => _delete(item),
                  icon: Icon(Icons.delete_outline, size: _tv ? 32 : 22),
                ),
            ],
          ),
        );
      },
    );
  }
}

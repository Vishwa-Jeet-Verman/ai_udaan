import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/download_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/download_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<DownloadItem> _downloads = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await DownloadService.getDownloads();
      setState(() { _downloads = items; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _openFile(DownloadItem item) async {
    final uri = Uri.parse(item.fileurl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenFile)),
        );
      }
    }
  }

  IconData _iconForMimetype(String mimetype) {
    if (mimetype.contains('pdf')) return Icons.picture_as_pdf;
    if (mimetype.contains('word') || mimetype.contains('document')) return Icons.description;
    if (mimetype.contains('presentation') || mimetype.contains('powerpoint')) return Icons.slideshow;
    if (mimetype.contains('spreadsheet') || mimetype.contains('excel')) return Icons.table_chart;
    if (mimetype.contains('zip')) return Icons.folder_zip;
    if (mimetype.contains('image')) return Icons.image;
    if (mimetype.contains('text')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  Color _colorForMimetype(String mimetype) {
    if (mimetype.contains('pdf')) return Colors.red;
    if (mimetype.contains('word') || mimetype.contains('document')) return Colors.blue;
    if (mimetype.contains('presentation') || mimetype.contains('powerpoint')) return Colors.orange;
    if (mimetype.contains('spreadsheet') || mimetype.contains('excel')) return const Color(0xFF1F7A63);
    if (mimetype.contains('zip')) return Colors.brown;
    if (mimetype.contains('image')) return Colors.purple;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.downloads)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.loginRequiredToDownload,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.pleaseLoginToDownload,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.downloads),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.failedToLoadDownloads, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)!.retry)),
          ],
        ),
      );
    }

    if (_downloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noFilesAvailable,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.documentsWillAppearHere,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group by course
    final Map<String, List<DownloadItem>> byCourse = {};
    for (final item in _downloads) {
      byCourse.putIfAbsent(item.courseTitle, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: byCourse.entries.map((entry) {
          return _CourseSection(
            courseTitle: entry.key,
            items: entry.value,
            onOpen: _openFile,
            iconFor: _iconForMimetype,
            colorFor: _colorForMimetype,
          );
        }).toList(),
      ),
    );
  }
}

class _CourseSection extends StatelessWidget {
  final String courseTitle;
  final List<DownloadItem> items;
  final Future<void> Function(DownloadItem) onOpen;
  final IconData Function(String) iconFor;
  final Color Function(String) colorFor;

  const _CourseSection({
    required this.courseTitle,
    required this.items,
    required this.onOpen,
    required this.iconFor,
    required this.colorFor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            courseTitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
        ),
        ...items.map((item) => ListTile(
          leading: CircleAvatar(
            backgroundColor: colorFor(item.mimetype).withValues(alpha: 0.12),
            child: Icon(iconFor(item.mimetype), color: colorFor(item.mimetype), size: 22),
          ),
          title: Text(item.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.moduleName != item.filename ? '${item.moduleName} · ' : ''}${item.filesizeFormatted}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new, size: 20),
            onPressed: () => onOpen(item),
            tooltip: 'Open file',
          ),
          onTap: () => onOpen(item),
        )),
        const Divider(height: 1),
      ],
    );
  }
}

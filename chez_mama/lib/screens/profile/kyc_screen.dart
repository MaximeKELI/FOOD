import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/platform_api.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_media_picker.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  List<KycDocument> _docs = [];
  bool _loading = true;
  String? _error;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await PlatformApi.instance.fetchKycDocuments();
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _upload() async {
    final idCtrl = TextEditingController();
    var subject = 'seller';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(tr('kyc.upload')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: subject,
                decoration: InputDecoration(labelText: tr('kyc.subject')),
                items: [
                  DropdownMenuItem(
                    value: 'seller',
                    child: Text(tr('kyc.subjectSeller')),
                  ),
                  DropdownMenuItem(
                    value: 'driver',
                    child: Text(tr('kyc.subjectDriver')),
                  ),
                ],
                onChanged: (v) => setLocal(() => subject = v ?? 'seller'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: idCtrl,
                decoration: InputDecoration(labelText: tr('kyc.idNumber')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('action.cancel')),
            ),
            Semantics(
              label: tr('kyc.upload'),
              button: true,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('action.save')),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final path = await AppMediaPicker.instance.pickPhotoFromGallery();
    if (path == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await PlatformApi.instance.uploadKyc(
        filePath: path.path,
        subject: subject,
        idNumber: idCtrl.text.trim(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('kyc.title'))),
      floatingActionButton: Semantics(
        label: tr('kyc.upload'),
        button: true,
        child: FloatingActionButton(
          onPressed: _uploading ? null : _upload,
          child: _uploading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.upload_file_rounded),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListLoadingSkeleton();
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(tr('kyc.hint'), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (_docs.isEmpty)
            Text(tr('kyc.empty'))
          else
            ..._docs.map(
              (d) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: ChezMamaTheme.cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.subject} · ${d.status}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (d.idNumber.isNotEmpty) Text(d.idNumber),
                    if (d.reviewNote.isNotEmpty)
                      Text(
                        d.reviewNote,
                        style: TextStyle(color: ChezMamaTheme.mutedInk(context)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
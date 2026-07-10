import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../l10n/app_strings.dart';

/// Bottom sheet to report a post or user.
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required int targetId,
  String? title,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(
      targetType: targetType,
      targetId: targetId,
      title: title,
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    this.title,
  });

  final String targetType;
  final int targetId;
  final String? title;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _reason = TextEditingController();
  final _details = TextEditingController();
  bool _submitting = false;
  bool _alsoBlock = false;

  @override
  void dispose() {
    _reason.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await SupportApi.instance.reportContent(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _reason.text.trim(),
        details: _details.text.trim(),
      );
      if (_alsoBlock && widget.targetType == 'user') {
        await SupportApi.instance.blockUser(widget.targetId);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('report.sent'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title ?? tr('report.title'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            decoration: InputDecoration(labelText: tr('report.reason')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _details,
            decoration: InputDecoration(labelText: tr('report.details')),
            maxLines: 3,
          ),
          if (widget.targetType == 'user')
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('report.alsoBlock')),
              value: _alsoBlock,
              onChanged: (v) => setState(() => _alsoBlock = v),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(
              _submitting ? tr('checkout.submitting') : tr('report.submit'),
            ),
          ),
        ],
      ),
    );
  }
}

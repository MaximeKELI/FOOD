import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../auth/auth_scope.dart';
import '../l10n/app_strings.dart';
import '../ui/chezmama_theme.dart';
import '../widgets/food_card.dart';

/// GDPR-style account deletion flow (UI; backend endpoint may be stubbed).
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _busy = false;
  bool _confirmed = false;

  Future<void> _delete() async {
    if (!_confirmed || _busy) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.dio.delete('/accounts/me/');
      if (!mounted) return;
      await AuthScope.of(context).signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('account.deleteSuccess'))),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 404 || code == 405
                ? tr('account.deletePendingBackend')
                : apiErrorMessage(e),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('account.deleteTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(ChezMamaTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FoodCard(
              padding: const EdgeInsets.all(ChezMamaTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 40, color: ChezMamaTheme.promoRed),
                  const SizedBox(height: ChezMamaTheme.spaceMd),
                  Text(
                    tr('account.deleteWarning'),
                    style: t.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('account.deleteBody'),
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: ChezMamaTheme.mutedInk(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ChezMamaTheme.spaceLg),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: Text(tr('account.deleteConfirm')),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy || !_confirmed ? null : _delete,
                style: FilledButton.styleFrom(
                  backgroundColor: ChezMamaTheme.promoRed,
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_forever_rounded),
                label: Text(tr('account.deleteAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  ReferralInfo? _info;
  bool _loading = true;
  String? _error;
  final _codeCtrl = TextEditingController();
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await SupportApi.instance.fetchReferral();
      if (!mounted) return;
      setState(() {
        _info = info;
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

  Future<void> _redeem() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _redeeming = true);
    try {
      await SupportApi.instance.redeemReferral(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('referral.redeemOk'))),
      );
      _codeCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('referral.title'))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListLoadingSkeleton(itemCount: 2);
    if (_error != null || _info == null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error ?? tr('action.unavailable'),
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    final info = _info!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: ChezMamaTheme.headerGradient(context),
            borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('referral.yourCode'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.code,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: info.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('referral.copied'))),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                trf('referral.reward', {'points': info.rewardPoints}),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tr('referral.redeemTitle'),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeCtrl,
          decoration: InputDecoration(
            labelText: tr('referral.friendCode'),
            hintText: tr('referral.friendCodeHint'),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _redeeming ? null : _redeem,
          child: Text(
            _redeeming ? tr('checkout.submitting') : tr('referral.redeem'),
          ),
        ),
      ],
    );
  }
}

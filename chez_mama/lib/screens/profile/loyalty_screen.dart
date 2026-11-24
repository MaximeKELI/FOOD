import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/platform_api.dart';
import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  LoyaltySummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthScope.of(context).refreshMe();
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await PlatformApi.instance.fetchLoyaltySummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  Future<void> _redeem(LoyaltyReward reward) async {
    try {
      await PlatformApi.instance.redeemLoyaltyReward(reward.id);
      await AuthScope.of(context).refreshMe();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('loyalty.redeemed'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final t = Theme.of(context);
    final points = _summary?.points ?? auth.loyaltyPoints;
    final progress = _summary?.progressToNext;
    final toNext = progress?['remaining'] ?? 100;

    return Scaffold(
      appBar: AppBar(title: Text(tr('loyalty.programTitle'))),
      body: _loading && _summary == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _summary == null
              ? EmptyStateView(
                  icon: Icons.cloud_off_rounded,
                  title: tr('home.connectionFailed'),
                  subtitle: _error!,
                  actionLabel: tr('action.retry'),
                  onAction: _load,
                )
              : AnimatedBuilder(
                  animation: auth,
                  builder: (context, _) {
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: ChezMamaTheme.headerGradient(context),
                              borderRadius:
                                  BorderRadius.circular(ChezMamaTheme.rCard),
                              boxShadow: ChezMamaTheme.softShadow(opacity: 0.12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.workspace_premium_rounded,
                                    color: Colors.white, size: 32),
                                const SizedBox(height: 10),
                                Text(
                                  trf('loyalty.points', {'points': points}),
                                  style: t.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (_summary?.currentTier != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    trf('loyalty.tierCurrent', {
                                      'name': _summary!.currentTier!.name,
                                    }),
                                    style: t.textTheme.bodyMedium?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                                if (_summary?.nextTier != null) ...[
                                  Text(
                                    trf('loyalty.tierNext', {
                                      'name': _summary!.nextTier!.name,
                                    }),
                                    style: t.textTheme.bodySmall?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress != null && progress['need']! > 0
                                  ? (progress['have']! / progress['need']!)
                                      .clamp(0.0, 1.0)
                                  : 0.3,
                              minHeight: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trf('loyalty.pointsToUnlock', {'points': toNext}),
                            style: t.textTheme.bodyMedium?.copyWith(
                              color: ChezMamaTheme.mutedInk(context),
                            ),
                          ),
                          if (_summary != null &&
                              _summary!.rewards.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              tr('loyalty.rewardTitle'),
                              style: t.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            for (final r in _summary!.rewards)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(r.title),
                                subtitle: Text(
                                  '${r.description} · ${r.pointsCost} pts',
                                ),
                                trailing: Semantics(
                                  label: tr('loyalty.redeem'),
                                  button: true,
                                  child: FilledButton(
                                    onPressed: points >= r.pointsCost
                                        ? () => _redeem(r)
                                        : null,
                                    child: Text(tr('loyalty.redeem')),
                                  ),
                                ),
                              ),
                          ],
                          if (_summary != null &&
                              _summary!.ledger.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              tr('loyalty.ledgerTitle'),
                              style: t.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            for (final e in _summary!.ledger)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  e.points >= 0
                                      ? Icons.add_circle_outline
                                      : Icons.remove_circle_outline,
                                  color: ChezMamaTheme.brandOrange,
                                ),
                                title: Text(e.note.isNotEmpty ? e.note : e.kind),
                                subtitle: Text(e.createdAt),
                                trailing: Text(
                                  '${e.points >= 0 ? '+' : ''}${e.points}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                          _InfoTile(
                            icon: Icons.receipt_long_rounded,
                            title: tr('loyalty.howToEarn'),
                            body: tr('loyalty.howToEarnBody'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChezMamaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.06),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ChezMamaTheme.brandOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: t.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: t.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
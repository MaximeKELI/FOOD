import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthScope.of(context).refreshMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final t = Theme.of(context);
    final points = auth.loyaltyPoints;
    const goal = 100;
    final progress = (points % goal) / goal;
    final toNext = goal - (points % goal);

    return Scaffold(
      appBar: AppBar(title: Text(tr('loyalty.programTitle'))),
      body: AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: ChezMamaTheme.headerGradient(context),
                  borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                  boxShadow: ChezMamaTheme.softShadow(opacity: 0.12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      trf('loyalty.points', {'points': auth.loyaltyPoints}),
                      style: t.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('loyalty.earnHint'),
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('loyalty.nextReward'),
                style:
                    t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
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
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.receipt_long_rounded,
                title: tr('loyalty.howToEarn'),
                body: tr('loyalty.howToEarnBody'),
              ),
              _InfoTile(
                icon: Icons.card_giftcard_rounded,
                title: tr('loyalty.rewardTitle'),
                body: tr('loyalty.rewardBody'),
              ),
            ],
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

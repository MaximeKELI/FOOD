import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../ui/chezmama_theme.dart';
import '../home/home_screen.dart';
import '../social/social_feed_screen.dart';
import '../cart/cart_screen.dart';
import '../tracking/tracking_screen.dart';
import '../auth/login_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    SocialFeedScreen(),
    TrackingScreen(),
    CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () async {
              await AuthScope.of(context).signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, a) {
          final fade = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(index),
          child: pages[index],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_cart',
        onPressed: () => setState(() => index = 3),
        backgroundColor: ChezMamaTheme.brandOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.shopping_bag_rounded),
        label: const Text('Panier'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (v) => setState(() => index = v),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.play_circle_rounded),
                  label: 'Shorts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.delivery_dining_rounded),
                  label: 'Suivi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_rounded),
                  label: 'Panier',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


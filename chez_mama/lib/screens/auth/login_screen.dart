import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../auth/auth_scope.dart';
import '../../ui/african_pattern_painter.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (busy) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseigne ton email et ton mot de passe.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await AuthScope.of(context).signIn(
        email: email.text,
        password: password.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: ChezMamaTheme.headerGradient(context),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: AfricanPatternPainter(
                a: ChezMamaTheme.brandOrange,
                b: ChezMamaTheme.brandAmber,
                c: ChezMamaTheme.brandBrown,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) {
                      return Transform.translate(
                        offset: Offset(0, 12 * (1 - v)),
                        child: Opacity(opacity: v, child: child),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: ChezMamaTheme.softShadow(opacity: 0.12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: ChezMamaTheme.brandOrange
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: ChezMamaTheme.brandOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Food',
                                  style: t.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Connexion vendeur',
                            style: t.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Publie tes produits et reçois des commandes.',
                            style: t.textTheme.bodyMedium?.copyWith(
                              color: ChezMamaTheme.ink.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: true,
                            onSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: AbsorbPointer(
                              absorbing: busy,
                              child: PrimaryButton(
                                label: busy ? 'Connexion…' : 'Se connecter',
                                icon: Icons.login_rounded,
                                onPressed: _submit,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pas de compte ? ',
                                style: t.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration:
                                          const Duration(milliseconds: 260),
                                      pageBuilder: (_, __, ___) =>
                                          const RegisterScreen(),
                                      transitionsBuilder: (_, a, __, child) {
                                        final c = CurvedAnimation(
                                          parent: a,
                                          curve: Curves.easeOutCubic,
                                        );
                                        return FadeTransition(
                                          opacity: c,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.04),
                                              end: Offset.zero,
                                            ).animate(c),
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: const Text('Créer un compte'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


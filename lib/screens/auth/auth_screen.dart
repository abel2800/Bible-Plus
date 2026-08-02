import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/design/bp_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      if (_register) {
        await auth.register(_email.text, _password.text);
      } else {
        await auth.signIn(_email.text, _password.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Authentication failed. Check your details.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.colors;

    return Scaffold(
      backgroundColor: t.appBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    BpIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8C766),
                          Color(0xFFC08A28),
                          Color(0xFFA83232),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'B',
                      style: AppTheme.brandTitle(
                        fontSize: 26,
                        weight: FontWeight.w700,
                        color: AppBrand.onGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _register ? 'Create account' : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: AppText.display(context, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  _register
                      ? 'Sign up to sync your study across devices'
                      : 'Sign in to sync highlights, notes, and bookmarks',
                  textAlign: TextAlign.center,
                  style: AppText.ui(context, size: 13.5, color: t.inkSoft),
                ),
                const SizedBox(height: 28),
                BpCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: AppText.ui(context, size: 14),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: AppText.ui(
                        context,
                        size: 12,
                        w: FontWeight.w600,
                        color: t.inkSoft,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                BpCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: _register
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    style: AppText.ui(context, size: 14),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: AppText.ui(
                        context,
                        size: 12,
                        w: FontWeight.w600,
                        color: t.inkSoft,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) {
                      if (!_busy) _submit();
                    },
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.ui(
                      context,
                      size: 13,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                BpPrimaryButton(
                  label: _register ? 'Create account' : 'Sign in',
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (_register) {
                            setState(() => _register = false);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                  child: Text(
                    _register ? 'Sign in instead' : 'Continue without account',
                  ),
                ),
                if (!_register) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              final auth = context.read<AuthService>();
                              final messenger = ScaffoldMessenger.of(context);
                              await auth.sendPasswordReset(_email.text);
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password reset email requested.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Text(
                        'Forgot password?',
                        style: AppText.ui(context, size: 13, color: t.inkFaint),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _busy
                        ? null
                        : () => setState(() => _register = !_register),
                    child: RichText(
                      text: TextSpan(
                        style: AppText.ui(context, size: 13, color: t.inkSoft),
                        children: [
                          TextSpan(
                            text: _register
                                ? 'Already have an account? '
                                : "Don't have an account? ",
                          ),
                          TextSpan(
                            text: _register ? 'Sign in' : 'Create account',
                            style: AppText.ui(
                              context,
                              size: 13,
                              w: FontWeight.w600,
                              color: AppBrand.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

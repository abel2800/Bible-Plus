import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'time_of_day_greeting.dart';

class UserDisplayName {
  UserDisplayName._();

  static String? firstName(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final display = user?.displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return display.split(RegExp(r'\s+')).first;
    }
    final email = user?.email?.trim();
    if (email != null && email.contains('@')) {
      final local = email.split('@').first;
      if (local.isNotEmpty) return local;
    }
    return null;
  }

  static String greeting(AppLocalizations l10n, BuildContext context) {
    final base = TimeOfDayGreeting.now(l10n);
    final name = firstName(context);
    if (name == null || name.isEmpty) return base;
    return '$base, $name';
  }

  static String avatarInitial(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return '';
    final display = user.displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return display.characters.first.toUpperCase();
    }
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.characters.first.toUpperCase();
    }
    return '';
  }
}

import 'package:flutter/material.dart';
import '../models/devotional.dart';
import '../services/devotional_service.dart';

class DevotionalProvider with ChangeNotifier {
  final DevotionalService _devotionalService = DevotionalService();

  Devotional? _todayDevotional;
  bool _isLoading = false;

  Devotional? get todayDevotional => _todayDevotional;
  bool get isLoading => _isLoading;

  DevotionalProvider() {
    loadTodayDevotional();
  }

  Future<void> loadTodayDevotional() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todayDevotional = await _devotionalService.getTodayDevotional();
    } catch (e) {
      debugPrint('Error loading devotional: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshDevotional() async {
    await loadTodayDevotional();
  }
}

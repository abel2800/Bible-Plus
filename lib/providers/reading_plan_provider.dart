import 'package:flutter/material.dart';
import '../models/reading_plan.dart';
import '../services/database_service.dart';
import '../services/licensed_catalog_service.dart';
import 'package:uuid/uuid.dart';

class ReadingPlanProvider extends ChangeNotifier {
  ReadingPlanProvider({LicensedCatalogService? catalogs})
      : _catalogs = catalogs ?? LicensedCatalogService();

  final DatabaseService _db = DatabaseService();
  final LicensedCatalogService _catalogs;
  final Uuid _uuid = const Uuid();

  List<ReadingPlan> _availablePlans = [];
  List<UserReadingPlan> _userPlans = [];

  bool _isLoading = false;
  String? _error;

  List<ReadingPlan> get availablePlans => _availablePlans;
  List<UserReadingPlan> get userPlans => _userPlans;
  List<ReadingPlan> get activePlans {
    final activePlanIds = _userPlans
        .where((up) => !up.isCompleted)
        .map((up) => up.planId)
        .toSet();
    return _availablePlans.where((p) => activePlanIds.contains(p.id)).toList();
  }

  List<ReadingPlan> get completedPlans {
    final completedPlanIds =
        _userPlans.where((up) => up.isCompleted).map((up) => up.planId).toSet();
    return _availablePlans
        .where((p) => completedPlanIds.contains(p.id))
        .toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final catalogs =
          await _catalogs.loadFeature('readingPlans', ReadingPlan.fromJson);
      _availablePlans =
          catalogs.expand((catalog) => catalog.items).toList(growable: false);
      _userPlans = await _db.getUserReadingPlans();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load reading plans: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startPlan(ReadingPlan plan) async {
    try {
      final existing = await _db.getUserReadingPlanByPlanId(plan.id);
      if (existing != null) {
        _error = 'You have already started this plan';
        notifyListeners();
        return;
      }

      final daysCompleted = <int, bool>{};
      for (int i = 1; i <= plan.duration; i++) {
        daysCompleted[i] = false;
      }

      final userPlan = UserReadingPlan(
        id: _uuid.v4(),
        planId: plan.id,
        startDate: DateTime.now(),
        currentDay: 1,
        daysCompleted: daysCompleted,
      );

      await _db.insertUserReadingPlan(userPlan);
      _userPlans.add(userPlan);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start plan: $e';
      notifyListeners();
    }
  }

  Future<void> markDayComplete(String userPlanId, int day) async {
    try {
      final index = _userPlans.indexWhere((p) => p.id == userPlanId);
      if (index == -1) return;

      final userPlan = _userPlans[index];
      final updatedDaysCompleted = Map<int, bool>.from(userPlan.daysCompleted);
      updatedDaysCompleted[day] = true;

      final allCompleted = updatedDaysCompleted.values.every((v) => v);

      final updated = UserReadingPlan(
        id: userPlan.id,
        planId: userPlan.planId,
        startDate: userPlan.startDate,
        currentDay: day < userPlan.daysCompleted.length ? day + 1 : day,
        isCompleted: allCompleted,
        completedDate: allCompleted ? DateTime.now() : null,
        daysCompleted: updatedDaysCompleted,
      );

      await _db.updateUserReadingPlan(updated);
      _userPlans[index] = updated;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update plan: $e';
      notifyListeners();
    }
  }

  Future<void> removePlan(String userPlanId) async {
    try {
      await _db.deleteUserReadingPlan(userPlanId);
      _userPlans.removeWhere((p) => p.id == userPlanId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove plan: $e';
      notifyListeners();
    }
  }

  UserReadingPlan? getUserPlanByPlanId(String planId) {
    try {
      return _userPlans.firstWhere((p) => p.planId == planId);
    } catch (e) {
      return null;
    }
  }

  ReadingPlan? getPlanById(String planId) {
    try {
      return _availablePlans.firstWhere((p) => p.id == planId);
    } catch (e) {
      return null;
    }
  }

  List<ReadingPlan> searchPlans(String query) {
    final lowerQuery = query.toLowerCase();
    return _availablePlans.where((plan) {
      return plan.name.toLowerCase().contains(lowerQuery) ||
          plan.title.values
              .any((title) => title.toLowerCase().contains(lowerQuery)) ||
          plan.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<ReadingPlan> getPlansByTag(String tag) {
    return _availablePlans.where((plan) => plan.tags.contains(tag)).toList();
  }

  List<String> getAllTags() {
    final tags = <String>{};
    for (var plan in _availablePlans) {
      tags.addAll(plan.tags);
    }
    return tags.toList()..sort();
  }
}

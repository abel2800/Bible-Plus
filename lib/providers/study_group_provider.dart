import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/study_group.dart';
import '../services/study_group_service.dart';

class StudyGroupProvider extends ChangeNotifier {
  StudyGroupProvider(this.gateway);

  final StudyGroupGateway gateway;
  StreamSubscription<List<StudyGroup>>? _subscription;
  List<StudyGroup> _groups = const [];
  String? _error;

  List<StudyGroup> get groups => _groups;
  String? get error => _error;

  void watch(String userId) {
    _subscription?.cancel();
    _subscription = gateway.watchForUser(userId).listen(
      (groups) {
        _groups = groups;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _error = 'Unable to load private groups.';
        notifyListeners();
      },
    );
  }

  Future<void> create({
    required String ownerId,
    required String name,
    required String planId,
    required List<String> invitedUserIds,
  }) {
    return gateway.create(
      ownerId: ownerId,
      name: name,
      planId: planId,
      invitedUserIds: invitedUserIds,
    );
  }

  Future<void> updateProgress(
    String groupId,
    String userId,
    int completedDay,
  ) {
    return gateway.updateProgress(
      groupId: groupId,
      userId: userId,
      completedDay: completedDay,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

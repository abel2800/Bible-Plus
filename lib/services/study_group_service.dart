import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/study_group.dart';

abstract interface class StudyGroupGateway {
  Stream<List<StudyGroup>> watchForUser(String userId);
  Future<void> create({
    required String ownerId,
    required String name,
    required String planId,
    required List<String> invitedUserIds,
  });
  Future<void> updateProgress({
    required String groupId,
    required String userId,
    required int completedDay,
  });
}

class FirestoreStudyGroupService implements StudyGroupGateway {
  FirestoreStudyGroupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<StudyGroup>> watchForUser(String userId) {
    return _firestore
        .collection('studyGroups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudyGroup.fromJson(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Future<void> create({
    required String ownerId,
    required String name,
    required String planId,
    required List<String> invitedUserIds,
  }) async {
    final members = <String>{ownerId, ...invitedUserIds}.toList();
    await _firestore.collection('studyGroups').add({
      'name': name.trim(),
      'planId': planId,
      'ownerId': ownerId,
      'memberIds': members,
      'progressByUser': {for (final id in members) id: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateProgress({
    required String groupId,
    required String userId,
    required int completedDay,
  }) {
    return _firestore.collection('studyGroups').doc(groupId).update({
      'progressByUser.$userId': completedDay,
    });
  }
}

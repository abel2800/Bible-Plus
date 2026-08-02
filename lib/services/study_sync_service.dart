import 'package:cloud_firestore/cloud_firestore.dart';

class SyncRecord {
  const SyncRecord({
    required this.kind,
    required this.id,
    required this.updatedAt,
    required this.data,
    this.deletedAt,
  });

  final String kind;
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic> data;

  String get documentId => '${kind}_$id';

  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      kind: json['kind'] as String,
      id: json['id'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  Map<String, dynamic> toJson(String ownerId) => {
        'kind': kind,
        'id': id,
        'ownerId': ownerId,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deletedAt': deletedAt?.toUtc().toIso8601String(),
        'data': data,
      };
}

abstract interface class StudySyncGateway {
  Future<List<SyncRecord>> synchronize(
    String userId,
    Iterable<SyncRecord> localRecords,
  );
  Future<void> deleteUserData(String userId);
}

class FirestoreStudySyncService implements StudySyncGateway {
  FirestoreStudySyncService({
    required bool enabled,
    FirebaseFirestore? firestore,
  }) : _firestore = enabled ? (firestore ?? FirebaseFirestore.instance) : null;

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> _records(String userId) {
    final firestore = _firestore;
    if (firestore == null) {
      throw StateError('Cloud synchronization is not configured.');
    }
    return firestore.collection('users').doc(userId).collection('study');
  }

  @override
  Future<List<SyncRecord>> synchronize(
    String userId,
    Iterable<SyncRecord> localRecords,
  ) async {
    final collection = _records(userId);
    final remoteSnapshot = await collection.get();
    final merged = <String, SyncRecord>{
      for (final document in remoteSnapshot.docs)
        document.id: SyncRecord.fromJson(document.data()),
    };

    for (final local in localRecords) {
      final remote = merged[local.documentId];
      if (remote == null || !remote.updatedAt.isAfter(local.updatedAt)) {
        await collection.doc(local.documentId).set(local.toJson(userId));
        merged[local.documentId] = local;
      }
    }
    return merged.values.toList(growable: false);
  }

  @override
  Future<void> deleteUserData(String userId) async {
    final snapshot = await _records(userId).get();
    final firestore = _firestore!;
    for (var offset = 0; offset < snapshot.docs.length; offset += 400) {
      final batch = firestore.batch();
      for (final document in snapshot.docs.skip(offset).take(400)) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}

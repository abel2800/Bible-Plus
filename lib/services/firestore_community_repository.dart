import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community.dart';
import '../repositories/community_repository.dart';

class FirestoreCommunityRepository implements CommunityRepository {
  FirestoreCommunityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<CommunityPost>> watchFeed(
    String viewerId, {
    CommunityFeedSort sort = CommunityFeedSort.newest,
  }) async* {
    final blocked = await blockedUsers(viewerId);
    final following = sort == CommunityFeedSort.following
        ? await followingIds(viewerId)
        : <String>{};

    Query<Map<String, dynamic>> query = _firestore
        .collection('communityPosts')
        .where('status', isEqualTo: CommunityPostStatus.visible.name)
        .orderBy('createdAt', descending: true)
        .limit(120);

    yield* query.snapshots().map((snapshot) {
      var posts = snapshot.docs
          .map((doc) => CommunityPost.fromJson(doc.id, doc.data()))
          .where((post) => !blocked.contains(post.authorId))
          .toList(growable: true);

      if (sort == CommunityFeedSort.following) {
        posts = posts
            .where((post) => following.contains(post.authorId))
            .toList(growable: true);
      }

      if (sort == CommunityFeedSort.trending) {
        posts.sort((a, b) {
          final scoreA = a.likeCount * 3 + a.downloadCount;
          final scoreB = b.likeCount * 3 + b.downloadCount;
          return scoreB.compareTo(scoreA);
        });
      }

      return List<CommunityPost>.unmodifiable(posts);
    });
  }

  @override
  Future<void> createPost(CommunityPost post) async {
    final rateLimit = _firestore
        .collection('users')
        .doc(post.authorId)
        .collection('rateLimits')
        .doc('communityPost');
    final target = _firestore.collection('communityPosts').doc(post.id);
    await _firestore.runTransaction((transaction) async {
      final previous = await transaction.get(rateLimit);
      final last = previous.data()?['lastCreatedAt'] as Timestamp?;
      if (last != null &&
          DateTime.now().difference(last.toDate()) <
              const Duration(seconds: 30)) {
        throw StateError('Please wait before posting again.');
      }
      transaction.set(target, post.toJson());
      transaction.set(
        rateLimit,
        {'lastCreatedAt': FieldValue.serverTimestamp()},
      );
    });
  }

  @override
  Future<void> deletePost(String userId, String postId) {
    return _firestore.collection('communityPosts').doc(postId).update({
      'status': CommunityPostStatus.removed.name,
      'body': '',
      'designJson': null,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> report(CommunityReport report) {
    return _firestore.collection('communityReports').doc(report.id).set(
          report.toJson(),
        );
  }

  @override
  Future<void> blockUser(String userId, String blockedUserId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('blocks')
        .doc(blockedUserId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<Set<String>> blockedUsers(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('blocks')
        .get();
    return snapshot.docs.map((document) => document.id).toSet();
  }

  @override
  Future<void> likePost(String userId, String postId) async {
    final likeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('likes')
        .doc(postId);
    final postRef = _firestore.collection('communityPosts').doc(postId);
    await _firestore.runTransaction((tx) async {
      final like = await tx.get(likeRef);
      if (like.exists) return;
      tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
      tx.update(postRef, {'likeCount': FieldValue.increment(1)});
    });
  }

  @override
  Future<void> unlikePost(String userId, String postId) async {
    final likeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('likes')
        .doc(postId);
    final postRef = _firestore.collection('communityPosts').doc(postId);
    await _firestore.runTransaction((tx) async {
      final like = await tx.get(likeRef);
      if (!like.exists) return;
      tx.delete(likeRef);
      tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
    });
  }

  @override
  Future<Set<String>> likedPostIds(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('likes')
        .get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  @override
  Future<void> followUser(String userId, String targetUserId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(targetUserId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> unfollowUser(String userId, String targetUserId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(targetUserId)
        .delete();
  }

  @override
  Future<Set<String>> followingIds(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  @override
  Future<void> incrementDownload(String postId) {
    return _firestore.collection('communityPosts').doc(postId).update({
      'downloadCount': FieldValue.increment(1),
    });
  }
}

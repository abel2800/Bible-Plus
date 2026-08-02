import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/community.dart';
import '../repositories/community_repository.dart';

class CommunityProvider extends ChangeNotifier {
  CommunityProvider(this._repository);

  final CommunityRepository _repository;
  final _uuid = const Uuid();
  StreamSubscription<List<CommunityPost>>? _subscription;
  List<CommunityPost> _posts = const [];
  Set<String> _likedIds = {};
  Set<String> _followingIds = {};
  CommunityFeedSort _sort = CommunityFeedSort.newest;
  String? _viewerId;
  String? _error;
  bool _loading = false;

  List<CommunityPost> get posts => _posts;
  Set<String> get likedIds => _likedIds;
  Set<String> get followingIds => _followingIds;
  CommunityFeedSort get sort => _sort;
  String? get error => _error;
  bool get loading => _loading;

  void watch(String userId, {CommunityFeedSort? sort}) {
    _viewerId = userId;
    if (sort != null) _sort = sort;
    _subscription?.cancel();
    _loading = true;
    notifyListeners();
    _loadSocial(userId);
    _subscription = _repository.watchFeed(userId, sort: _sort).listen(
      (posts) {
        _posts = posts;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _error = 'Unable to load the community.';
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> setSort(CommunityFeedSort sort) async {
    if (_sort == sort || _viewerId == null) return;
    _sort = sort;
    watch(_viewerId!, sort: sort);
  }

  Future<void> _loadSocial(String userId) async {
    try {
      _likedIds = await _repository.likedPostIds(userId);
      _followingIds = await _repository.followingIds(userId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> create(String userId, String body, {String? authorName}) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 2000) {
      throw ArgumentError('Posts must contain 1–2000 characters.');
    }
    final now = DateTime.now().toUtc();
    await _repository.createPost(
      CommunityPost(
        id: _uuid.v4(),
        authorId: userId,
        body: text,
        createdAt: now,
        updatedAt: now,
        authorName: authorName,
      ),
    );
  }

  Future<void> publishVerseDesign({
    required String userId,
    required String verseText,
    required String reference,
    required Map<String, dynamic> designJson,
    String? authorName,
  }) async {
    final now = DateTime.now().toUtc();
    await _repository.createPost(
      CommunityPost(
        id: _uuid.v4(),
        authorId: userId,
        body: verseText.trim().isEmpty ? reference : verseText.trim(),
        createdAt: now,
        updatedAt: now,
        kind: CommunityPostKind.verseDesign,
        reference: reference,
        designJson: designJson,
        authorName: authorName,
      ),
    );
  }

  Future<void> toggleLike(String userId, String postId) async {
    if (_likedIds.contains(postId)) {
      await _repository.unlikePost(userId, postId);
      _likedIds = {..._likedIds}..remove(postId);
      _posts = _posts
          .map(
            (p) => p.id == postId
                ? p.copyWith(likeCount: (p.likeCount - 1).clamp(0, 1 << 30))
                : p,
          )
          .toList(growable: false);
    } else {
      await _repository.likePost(userId, postId);
      _likedIds = {..._likedIds, postId};
      _posts = _posts
          .map(
            (p) => p.id == postId ? p.copyWith(likeCount: p.likeCount + 1) : p,
          )
          .toList(growable: false);
    }
    notifyListeners();
  }

  Future<void> toggleFollow(String userId, String authorId) async {
    if (userId == authorId) return;
    if (_followingIds.contains(authorId)) {
      await _repository.unfollowUser(userId, authorId);
      _followingIds = {..._followingIds}..remove(authorId);
    } else {
      await _repository.followUser(userId, authorId);
      _followingIds = {..._followingIds, authorId};
    }
    notifyListeners();
    if (_sort == CommunityFeedSort.following) {
      watch(userId, sort: _sort);
    }
  }

  Future<void> markDownload(String postId) {
    return _repository.incrementDownload(postId);
  }

  Future<void> report(String userId, String postId, String reason) {
    return _repository.report(
      CommunityReport(
        id: _uuid.v4(),
        postId: postId,
        reporterId: userId,
        reason: reason,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> block(String userId, String authorId) async {
    await _repository.blockUser(userId, authorId);
    _posts = _posts.where((post) => post.authorId != authorId).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

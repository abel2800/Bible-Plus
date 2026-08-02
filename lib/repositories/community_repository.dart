import '../models/community.dart';

abstract interface class CommunityRepository {
  Stream<List<CommunityPost>> watchFeed(
    String viewerId, {
    CommunityFeedSort sort = CommunityFeedSort.newest,
  });
  Future<void> createPost(CommunityPost post);
  Future<void> deletePost(String userId, String postId);
  Future<void> report(CommunityReport report);
  Future<void> blockUser(String userId, String blockedUserId);
  Future<Set<String>> blockedUsers(String userId);
  Future<void> likePost(String userId, String postId);
  Future<void> unlikePost(String userId, String postId);
  Future<Set<String>> likedPostIds(String userId);
  Future<void> followUser(String userId, String targetUserId);
  Future<void> unfollowUser(String userId, String targetUserId);
  Future<Set<String>> followingIds(String userId);
  Future<void> incrementDownload(String postId);
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/community.dart';
import '../../providers/community_provider.dart';
import '../../services/auth_service.dart';
import '../../studio/studio_canvas.dart';
import '../../studio/verse_design.dart';
import '../../utils/app_theme.dart';
import '../../widgets/design/bp_widgets.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final _controller = TextEditingController();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final user = context.read<AuthService>().currentUser;
    if (user != null) context.read<CommunityProvider>().watch(user.uid);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final community = context.watch<CommunityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  BpIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Community',
                    style: AppTheme.brandTitle(fontSize: 22, color: ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: user == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Sign in to access the community.',
                          textAlign: TextAlign.center,
                          style: AppTheme.scripture(
                            fontSize: 15,
                            height: 1.55,
                            color: soft,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              for (final sort in CommunityFeedSort.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(sort.name),
                                    selected: community.sort == sort,
                                    onSelected: (_) => community.setSort(sort),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: BpCard(
                            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                            child: TextField(
                              controller: _controller,
                              maxLength: 2000,
                              minLines: 2,
                              maxLines: 5,
                              style:
                                  AppTheme.scripture(fontSize: 15, color: ink),
                              decoration: InputDecoration(
                                labelText: 'Share an encouragement',
                                labelStyle: AppTheme.ui(
                                  fontSize: 11,
                                  weight: FontWeight.w600,
                                  color: soft,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                counterStyle: AppTheme.ui(
                                  fontSize: 11,
                                  color: faint,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: 'Post',
                                  onPressed: () async {
                                    await community.create(
                                      user.uid,
                                      _controller.text,
                                      authorName: user.email ??
                                          user.uid.substring(0, 6),
                                    );
                                    _controller.clear();
                                  },
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    color: AppTheme.teal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (community.loading)
                          const LinearProgressIndicator(color: AppTheme.gold),
                        if (community.error != null)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              community.error!,
                              style: AppTheme.ui(
                                fontSize: 13,
                                color: AppTheme.vermilion,
                              ),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            itemCount: community.posts.length,
                            itemBuilder: (context, index) {
                              final post = community.posts[index];
                              final liked =
                                  community.likedIds.contains(post.id);
                              final following = community.followingIds
                                  .contains(post.authorId);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: BpCard(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    8,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (post.isVerseDesign &&
                                          post.designJson != null)
                                        AspectRatio(
                                          aspectRatio: 9 / 16,
                                          child: StudioCanvas(
                                            design: VerseDesign.fromJson(
                                              post.designJson!,
                                            ),
                                            editable: false,
                                            animateMotion: false,
                                          ),
                                        ),
                                      if (post.isVerseDesign)
                                        const SizedBox(height: 10),
                                      Text(
                                        post.body,
                                        style: AppTheme.scripture(
                                          fontSize: 15,
                                          height: 1.6,
                                          color: ink,
                                        ),
                                      ),
                                      if (post.reference != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          post.reference!,
                                          style: AppTheme.ui(
                                            fontSize: 12,
                                            weight: FontWeight.w700,
                                            color: AppTheme.gold,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        post.authorName ??
                                            post.authorId.substring(0, 8),
                                        style: AppTheme.ui(
                                          fontSize: 11,
                                          color: faint,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Like',
                                            onPressed: () => community
                                                .toggleLike(user.uid, post.id),
                                            icon: Icon(
                                              liked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: liked
                                                  ? AppTheme.vermilion
                                                  : soft,
                                              size: 20,
                                            ),
                                          ),
                                          Text(
                                            '${post.likeCount}',
                                            style: AppTheme.ui(fontSize: 12),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.download_outlined,
                                            size: 18,
                                            color: soft,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${post.downloadCount}',
                                            style: AppTheme.ui(fontSize: 12),
                                          ),
                                          const Spacer(),
                                          if (post.authorId != user.uid)
                                            TextButton(
                                              onPressed: () =>
                                                  community.toggleFollow(
                                                user.uid,
                                                post.authorId,
                                              ),
                                              child: Text(
                                                following
                                                    ? 'Following'
                                                    : 'Follow',
                                              ),
                                            ),
                                          if (post.isVerseDesign)
                                            IconButton(
                                              tooltip: 'Open in Verse Studio',
                                              onPressed: () async {
                                                await community
                                                    .markDownload(post.id);
                                                if (!context.mounted) return;
                                                Navigator.pushNamed(
                                                  context,
                                                  '/wallpaper',
                                                  arguments: {
                                                    'text': post.body,
                                                    'reference':
                                                        post.reference ?? '',
                                                    'designJson':
                                                        post.designJson,
                                                  },
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.auto_awesome,
                                                color: AppTheme.gold,
                                              ),
                                            ),
                                          PopupMenuButton<String>(
                                            tooltip: 'Post actions',
                                            icon: Icon(
                                              Icons.more_vert_rounded,
                                              color: soft,
                                              size: 20,
                                            ),
                                            onSelected: (action) async {
                                              if (action == 'report') {
                                                await community.report(
                                                  user.uid,
                                                  post.id,
                                                  'user_report',
                                                );
                                              } else if (action == 'block') {
                                                await community.block(
                                                  user.uid,
                                                  post.authorId,
                                                );
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              PopupMenuItem(
                                                value: 'report',
                                                child: Text(
                                                  'Report',
                                                  style: AppTheme.ui(
                                                    fontSize: 13,
                                                    color: AppTheme.vermilion,
                                                  ),
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'block',
                                                child: Text(
                                                  'Block author',
                                                  style: AppTheme.ui(
                                                    fontSize: 13,
                                                    color: AppTheme.vermilion,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum CommunityPostStatus { visible, underReview, removed }

enum CommunityFeedSort { newest, trending, following }

enum CommunityPostKind { text, verseDesign }

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.status = CommunityPostStatus.visible,
    this.reportCount = 0,
    this.kind = CommunityPostKind.text,
    this.reference,
    this.designJson,
    this.likeCount = 0,
    this.downloadCount = 0,
    this.authorName,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommunityPostStatus status;
  final int reportCount;
  final CommunityPostKind kind;
  final String? reference;
  final Map<String, dynamic>? designJson;
  final int likeCount;
  final int downloadCount;
  final String? authorName;

  bool get isVerseDesign => kind == CommunityPostKind.verseDesign;

  factory CommunityPost.fromJson(String id, Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'text';
    return CommunityPost(
      id: id,
      authorId: json['authorId'] as String,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: CommunityPostStatus.values.byName(
        json['status'] as String? ?? 'visible',
      ),
      reportCount: json['reportCount'] as int? ?? 0,
      kind: CommunityPostKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => CommunityPostKind.text,
      ),
      reference: json['reference'] as String?,
      designJson: json['designJson'] is Map
          ? Map<String, dynamic>.from(json['designJson'] as Map)
          : null,
      likeCount: json['likeCount'] as int? ?? 0,
      downloadCount: json['downloadCount'] as int? ?? 0,
      authorName: json['authorName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'body': body,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'status': status.name,
        'reportCount': reportCount,
        'kind': kind.name,
        'reference': reference,
        'designJson': designJson,
        'likeCount': likeCount,
        'downloadCount': downloadCount,
        'authorName': authorName,
      };

  CommunityPost copyWith({
    int? likeCount,
    int? downloadCount,
    CommunityPostStatus? status,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      body: body,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status ?? this.status,
      reportCount: reportCount,
      kind: kind,
      reference: reference,
      designJson: designJson,
      likeCount: likeCount ?? this.likeCount,
      downloadCount: downloadCount ?? this.downloadCount,
      authorName: authorName,
    );
  }
}

class CommunityReport {
  const CommunityReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'reporterId': reporterId,
        'reason': reason,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'status': 'open',
      };
}

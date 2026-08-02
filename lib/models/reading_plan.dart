class ReadingPlan {
  final String id;
  final String name;
  final Map<String, String> title;
  final Map<String, String> description;
  final int duration;
  final String imageUrl;
  final String thumbnailUrl;
  final List<String> tags;
  final String language;
  final int completedCount;
  final int startCount;
  final String createTime;
  final String publisherInfo;
  final String publisherLink;
  final int feature;
  final int sect;

  ReadingPlan({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.duration,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.tags,
    required this.language,
    this.completedCount = 0,
    this.startCount = 0,
    required this.createTime,
    this.publisherInfo = '',
    this.publisherLink = '',
    this.feature = 0,
    this.sect = 0,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['name'] ?? '',
      name: json['name'] ?? '',
      title: Map<String, String>.from(json['title'] ?? {}),
      description: Map<String, String>.from(json['desc'] ?? {}),
      duration: json['duration'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      tags: List<String>.from(json['tag'] ?? []),
      language: json['language'] ?? 'en',
      completedCount: json['completedCount'] ?? 0,
      startCount: json['startCount'] ?? 0,
      createTime: json['createTime'] ?? '',
      publisherInfo: json['publisherInfo'] ?? '',
      publisherLink: json['publisherLink'] ?? '',
      feature: json['feature'] ?? 0,
      sect: json['sect'] ?? 0,
    );
  }
}

class UserReadingPlan {
  final String id;
  final String planId;
  final DateTime startDate;
  final int currentDay;
  final bool isCompleted;
  final DateTime? completedDate;
  final Map<int, bool> daysCompleted;

  UserReadingPlan({
    required this.id,
    required this.planId,
    required this.startDate,
    this.currentDay = 1,
    this.isCompleted = false,
    this.completedDate,
    Map<int, bool>? daysCompleted,
  }) : daysCompleted = daysCompleted ?? {};

  factory UserReadingPlan.fromJson(Map<String, dynamic> json) {
    return UserReadingPlan(
      id: json['id'],
      planId: json['planId'],
      startDate: DateTime.parse(json['startDate']),
      currentDay: json['currentDay'] ?? 1,
      isCompleted: json['isCompleted'] == 1,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
      daysCompleted: json['daysCompleted'] != null
          ? Map<int, bool>.from(
              (json['daysCompleted'] as Map).map(
                (k, v) => MapEntry(int.parse(k.toString()), v == 1),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'currentDay': currentDay,
      'isCompleted': isCompleted ? 1 : 0,
      'completedDate': completedDate?.toIso8601String(),
      'daysCompleted': daysCompleted.map(
        (k, v) => MapEntry(k.toString(), v ? 1 : 0),
      ),
    };
  }

  double get progress {
    if (daysCompleted.isEmpty) return 0.0;
    final completed = daysCompleted.values.where((v) => v).length;
    return completed / daysCompleted.length;
  }
}

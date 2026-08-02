class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.planId,
    required this.ownerId,
    required this.memberIds,
    required this.progressByUser,
  });

  final String id;
  final String name;
  final String planId;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, int> progressByUser;

  factory StudyGroup.fromJson(String id, Map<String, dynamic> json) {
    return StudyGroup(
      id: id,
      name: json['name'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      memberIds: List<String>.from(json['memberIds'] as List? ?? const []),
      progressByUser: Map<String, int>.from(
        json['progressByUser'] as Map? ?? const {},
      ),
    );
  }
}

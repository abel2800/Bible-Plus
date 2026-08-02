class CrossReference {
  const CrossReference({
    required this.fromReference,
    required this.toReference,
    required this.relationshipType,
    this.description,
  });

  final String fromReference;
  final String toReference;
  final String relationshipType;
  final String? description;
}

class PhotoCard {
  final String id;
  final String imagePath;
  final String? description;

  const PhotoCard({
    required this.id,
    required this.imagePath,
    this.description,
  });

  factory PhotoCard.fromJson(Map<String, dynamic> json) {
    return PhotoCard(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'imagePath': imagePath, 'description': description};
  }
}

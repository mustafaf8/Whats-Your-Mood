class MoodCard {
  final String id;
  final String text;
  final String? category;

  const MoodCard({required this.id, required this.text, this.category});

  factory MoodCard.fromJson(Map<String, dynamic> json) {
    return MoodCard(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'category': category};
  }
}

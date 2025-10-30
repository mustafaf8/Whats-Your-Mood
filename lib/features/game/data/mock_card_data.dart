import '../models/mood_card.dart';
import '../models/photo_card.dart';

// Tüm mood kartları (ID + metin)
const List<MoodCard> allMockMoodCards = [
  MoodCard(id: 'mood_id_1', text: 'Ne zaman mutlu hissediyorum?'),
  MoodCard(id: 'mood_id_2', text: 'Nerede en rahat hissediyorum?'),
  MoodCard(id: 'mood_id_3', text: 'Hangi müzik beni mutlu eder?'),
  MoodCard(id: 'mood_id_4', text: 'En sevdiğim yemek nedir?'),
  MoodCard(id: 'mood_id_5', text: 'En eğlendiğim zaman?'),
];

// Tüm photo kartları (ID + placeholder görsel)
final List<PhotoCard> allMockPhotoCards = List.generate(
  20,
  (i) => PhotoCard(
    id: 'photo_id_${i + 1}',
    imagePath: 'assets/placeholder.png',
    description: 'Photo ${i + 1}',
  ),
);

MoodCard? findMoodCardById(String id) {
  try {
    return allMockMoodCards.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}

PhotoCard? findPhotoCardById(String id) {
  try {
    return allMockPhotoCards.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}



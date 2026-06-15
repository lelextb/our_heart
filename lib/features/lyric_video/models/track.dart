class Track {
  final String id; // YouTube video ID
  final String title;
  final String artist;
  final String thumbnailUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });

  @override
  String toString() => '$title - $artist';
}
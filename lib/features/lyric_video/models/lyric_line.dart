class LyricLine {
  final int milliseconds; // absolute time in ms
  final String text;

  const LyricLine({required this.milliseconds, required this.text});

  @override
  String toString() => '[$milliseconds ms] $text';
}
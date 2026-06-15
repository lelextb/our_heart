import 'package:flutter/material.dart';

/// Replaces every 'O' (upper and lower case) with a filled heart icon
/// inside a [RichText] widget, preserving the original style.
///
/// Usage: `HeartText('Love you')` will render "L❤️ve y❤️u".
class HeartText extends StatelessWidget {
  const HeartText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = <InlineSpan>[];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == 'O' || char == 'o') {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Icon(
              Icons.favorite,
              size: (defaultStyle.fontSize ?? 14) * 0.9,
              color: defaultStyle.color ?? Colors.red,
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: char, style: defaultStyle));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }
}
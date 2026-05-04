import 'package:flutter/material.dart';

class InlineEmbedPlayer extends StatelessWidget {
  final String url;
  final double aspectRatio;
  final bool forceInteraction;

  const InlineEmbedPlayer({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
    this.forceInteraction = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const SizedBox.shrink(),
    );
  }
}
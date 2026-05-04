import 'package:flutter/material.dart';

class MobileYouTubePlayer extends StatelessWidget {
  final String url;
  final double aspectRatio;
  final bool autoPlay;

  const MobileYouTubePlayer({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
    this.autoPlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const SizedBox.shrink(),
    );
  }
}
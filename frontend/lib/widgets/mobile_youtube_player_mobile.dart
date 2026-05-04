import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class _QualityOption {
  final String label;
  final String value;

  const _QualityOption({required this.label, required this.value});
}

class MobileYouTubePlayer extends StatefulWidget {
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
  State<MobileYouTubePlayer> createState() => _MobileYouTubePlayerState();
}

class _MobileYouTubePlayerState extends State<MobileYouTubePlayer> {
  static const List<double> _playbackSpeedOptions = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  static const _QualityOption _autoQualityOption = _QualityOption(
    label: 'Auto',
    value: 'auto',
  );

  static const List<_QualityOption> _allQualityOptions = [
    _autoQualityOption,
    _QualityOption(label: '144p', value: 'tiny'),
    _QualityOption(label: '240p', value: 'small'),
    _QualityOption(label: '360p', value: 'medium'),
    _QualityOption(label: '480p', value: 'large'),
    _QualityOption(label: '720p HD', value: 'hd720'),
    _QualityOption(label: '1080p HD', value: 'hd1080'),
    _QualityOption(label: 'Highres', value: 'highres'),
  ];

  YoutubePlayerController? _controller;
  late bool _isMuted;
  String _preferredQuality = 'auto';
  List<_QualityOption> _availableQualityOptions = [_autoQualityOption];

  @override
  void initState() {
    super.initState();
    _isMuted = widget.autoPlay;
    _createController();
  }

  @override
  void didUpdateWidget(covariant MobileYouTubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.autoPlay != widget.autoPlay) {
      _isMuted = widget.autoPlay;
      _disposeController();
      _createController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _createController() {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      _controller = null;
      return;
    }

    final videoId = _extractYouTubeVideoId(uri);
    if (videoId == null || videoId.isEmpty) {
      _controller = null;
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: _isMuted,
        controlsVisibleAtStart: true,
        hideThumbnail: true,
        startAt: _extractYouTubeStartSeconds(uri),
        useHybridComposition: true,
      ),
    );
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  String? _extractYouTubeVideoId(Uri uri) {
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) {
      return v;
    }

    if (uri.pathSegments.isEmpty) {
      return YoutubePlayer.convertUrlToId(uri.toString());
    }

    final segments = uri.pathSegments;
    final embedIndex = segments.indexOf('embed');
    if (embedIndex >= 0 && segments.length > embedIndex + 1) {
      return segments[embedIndex + 1];
    }

    final shortsIndex = segments.indexOf('shorts');
    if (shortsIndex >= 0 && segments.length > shortsIndex + 1) {
      return segments[shortsIndex + 1];
    }

    final liveIndex = segments.indexOf('live');
    if (liveIndex >= 0 && segments.length > liveIndex + 1) {
      return segments[liveIndex + 1];
    }

    return YoutubePlayer.convertUrlToId(uri.toString());
  }

  int _extractYouTubeStartSeconds(Uri uri) {
    final raw =
        uri.queryParameters['start'] ??
        uri.queryParameters['t'] ??
        uri.queryParameters['time_continue'];
    if (raw == null || raw.isEmpty) {
      return 0;
    }

    final direct = int.tryParse(raw);
    if (direct != null && direct > 0) {
      return direct;
    }

    final match = RegExp(
      r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$',
    ).firstMatch(raw);
    if (match == null) {
      return 0;
    }

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final mins = int.tryParse(match.group(2) ?? '0') ?? 0;
    final secs = int.tryParse(match.group(3) ?? '0') ?? 0;
    return (hours * 3600) + (mins * 60) + secs;
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    if (_isMuted) {
      controller.unMute();
      controller.setVolume(100);
    } else {
      controller.mute();
    }

    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isReady) {
      return;
    }

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  Widget _buildPlayPauseAction(YoutubePlayerController controller) {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return IconButton(
          onPressed: value.isReady ? _togglePlayPause : null,
          tooltip: value.isPlaying ? 'Pause' : 'Play',
          icon: Icon(
            value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildMuteAction() {
    return IconButton(
      onPressed: _toggleMute,
      tooltip: _isMuted ? 'Unmute' : 'Mute',
      icon: Icon(
        _isMuted ? Icons.volume_off : Icons.volume_up,
        color: Colors.white,
      ),
    );
  }

  String _formatSpeedLabel(double speed) {
    if (speed == 1.0) {
      return 'Normal';
    }
    if (speed == speed.roundToDouble()) {
      return '${speed.toStringAsFixed(0)}x';
    }
    return '${speed.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}x';
  }

  int _speedIndexForRate(double playbackRate) {
    var selectedIndex = 0;
    var selectedDiff = double.infinity;

    for (var i = 0; i < _playbackSpeedOptions.length; i++) {
      final diff = (_playbackSpeedOptions[i] - playbackRate).abs();
      if (diff < selectedDiff) {
        selectedDiff = diff;
        selectedIndex = i;
      }
    }

    return selectedIndex;
  }

  String _normalizeQuality(String? quality) {
    final raw = (quality ?? '').trim().toLowerCase();
    final supportedValues = _allQualityOptions
        .map((option) => option.value)
        .toSet();
    if (raw == 'default') {
      return 'auto';
    }
    if (supportedValues.contains(raw)) {
      return raw;
    }
    return 'auto';
  }

  String _qualityLabel(String qualityValue) {
    for (final option in _allQualityOptions) {
      if (option.value == qualityValue) {
        return option.label;
      }
    }
    return 'Auto';
  }

  String? _parseStringPayload(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is String) {
      final rawText = payload.trim();
      if (rawText.isEmpty) {
        return null;
      }

      try {
        final decoded = jsonDecode(rawText);
        if (decoded is String) {
          return decoded.trim();
        }
      } catch (_) {
        // Ignore and fallback to raw string.
      }

      return rawText;
    }

    return payload.toString().trim();
  }

  List<String> _parseQualityLevelPayload(dynamic payload) {
    List<dynamic>? decodedList;

    if (payload is List) {
      decodedList = payload;
    } else if (payload != null) {
      final rawText = _parseStringPayload(payload) ?? '';
      if (rawText.isNotEmpty) {
        try {
          final firstDecode = jsonDecode(rawText);
          if (firstDecode is List) {
            decodedList = firstDecode;
          } else if (firstDecode is String) {
            final secondDecode = jsonDecode(firstDecode);
            if (secondDecode is List) {
              decodedList = secondDecode;
            }
          }
        } catch (_) {
          decodedList = null;
        }
      }
    }

    if (decodedList == null || decodedList.isEmpty) {
      return const [];
    }

    final allowedValues = _allQualityOptions
        .map((option) => option.value)
        .where((value) => value != 'auto')
        .toSet();

    final normalizedValues = <String>{};
    for (final level in decodedList) {
      final value = level.toString().trim().toLowerCase();
      if (allowedValues.contains(value)) {
        normalizedValues.add(value);
      }
    }

    return normalizedValues.toList();
  }

  List<_QualityOption> _resolveAvailableQualityOptions(
    List<String> qualityValues,
  ) {
    final available = qualityValues.toSet();
    final options = _allQualityOptions.where((option) {
      return option.value == 'auto' || available.contains(option.value);
    }).toList();

    if (options.isEmpty) {
      return [_autoQualityOption];
    }

    return options;
  }

  Future<void> _refreshAvailableQualityOptions(
    YoutubePlayerController controller,
  ) async {
    final webController = controller.value.webViewController;
    if (!controller.value.isReady || webController == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableQualityOptions = [_autoQualityOption];
        _preferredQuality = 'auto';
      });
      return;
    }

    try {
      final payload = await webController.evaluateJavascript(
        source:
            "(() => {"
            "  if (typeof player === 'undefined' || !player || !player.getAvailableQualityLevels) return '[]';"
            "  const levels = player.getAvailableQualityLevels();"
            "  return JSON.stringify(levels || []);"
            "})();",
      );

      final qualityValues = _parseQualityLevelPayload(payload);
      if (!mounted) {
        return;
      }

      final options = _resolveAvailableQualityOptions(qualityValues);
      setState(() {
        _availableQualityOptions = options;
        if (!options.any((option) => option.value == _preferredQuality)) {
          _preferredQuality = 'auto';
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableQualityOptions = [_autoQualityOption];
        _preferredQuality = 'auto';
      });
    }
  }

  Future<String?> _readCurrentPlaybackQuality(
    YoutubePlayerController controller,
  ) async {
    final webController = controller.value.webViewController;
    if (!controller.value.isReady || webController == null) {
      return null;
    }

    final payload = await webController.evaluateJavascript(
      source:
          "(() => {"
          "  if (typeof player === 'undefined' || !player || !player.getPlaybackQuality) return 'auto';"
          "  return player.getPlaybackQuality() || 'auto';"
          "})();",
    );

    final quality = _parseStringPayload(payload);
    if (quality == null || quality.isEmpty) {
      return null;
    }

    return _normalizeQuality(quality);
  }

  Future<void> _setPlaybackQuality(
    YoutubePlayerController controller,
    String qualityValue,
  ) async {
    final webController = controller.value.webViewController;
    if (!controller.value.isReady || webController == null) {
      return;
    }

    if (!_availableQualityOptions.any(
      (option) => option.value == qualityValue,
    )) {
      return;
    }

    await webController.evaluateJavascript(
      source:
          "if (typeof player !== 'undefined' && player && player.setPlaybackQuality) { player.setPlaybackQuality('$qualityValue'); }",
    );

    final actualQuality = await _readCurrentPlaybackQuality(controller);

    if (!mounted) {
      return;
    }

    setState(() {
      _preferredQuality = actualQuality ?? qualityValue;
    });
  }

  Future<void> _openSettingsSheet(YoutubePlayerController controller) async {
    await _refreshAvailableQualityOptions(controller);
    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return ValueListenableBuilder<YoutubePlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final selectedSpeedIndex = _speedIndexForRate(value.playbackRate);
            final selectedSpeed = _playbackSpeedOptions[selectedSpeedIndex];
            final resolvedQuality = _normalizeQuality(value.playbackQuality);
            final preferredQuality = _normalizeQuality(_preferredQuality);
            final currentQuality =
                _availableQualityOptions.any(
                  (option) => option.value == resolvedQuality,
                )
                ? resolvedQuality
                : _availableQualityOptions.any(
                    (option) => option.value == preferredQuality,
                  )
                ? preferredQuality
                : 'auto';

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Player settings'),
                    subtitle: Text(
                      'Quality: ${_qualityLabel(currentQuality)} • Speed: ${_formatSpeedLabel(selectedSpeed)}',
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose quality',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableQualityOptions.map((option) {
                          return ChoiceChip(
                            label: Text(option.label),
                            selected: option.value == currentQuality,
                            onSelected: (_) {
                              _setPlaybackQuality(controller, option.value);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (_availableQualityOptions.length == 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Only Auto is available for this video.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Playback speed',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          '0.25x',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          'Normal',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '2x',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Slider(
                      value: selectedSpeedIndex.toDouble(),
                      min: 0,
                      max: (_playbackSpeedOptions.length - 1).toDouble(),
                      divisions: _playbackSpeedOptions.length - 1,
                      label: _formatSpeedLabel(selectedSpeed),
                      onChanged: (index) {
                        final selectedRate =
                            _playbackSpeedOptions[index.round()];
                        controller.setPlaybackRate(selectedRate);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Selected: ${_formatSpeedLabel(selectedSpeed)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                    ),
                    title: Text(_isMuted ? 'Unmute audio' : 'Mute audio'),
                    onTap: () {
                      _toggleMute();
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsAction(YoutubePlayerController controller) {
    return IconButton(
      onPressed: () => _openSettingsSheet(controller),
      tooltip: 'Player settings',
      icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
    );
  }

  List<Widget> _buildBottomActions(YoutubePlayerController controller) {
    return [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xB3000000),
          ),
          child: Row(
            children: [
              _buildPlayPauseAction(controller),
              CurrentPosition(controller: controller),
              const SizedBox(width: 8),
              ProgressBar(
                controller: controller,
                isExpanded: true,
                colors: const ProgressBarColors(
                  playedColor: Colors.redAccent,
                  handleColor: Colors.red,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 8),
              RemainingDuration(controller: controller),
              const SizedBox(width: 4),
              _buildSettingsAction(controller),
              _buildMuteAction(),
              FullScreenButton(controller: controller),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const Text(
            'Video unavailable',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller,
        aspectRatio: widget.aspectRatio,
        controlsTimeOut: const Duration(seconds: 4),
        actionsPadding: EdgeInsets.zero,
        bottomActions: _buildBottomActions(controller),
        onReady: () {
          _refreshAvailableQualityOptions(controller);
        },
      ),
      builder: (context, player) => player,
    );
  }
}

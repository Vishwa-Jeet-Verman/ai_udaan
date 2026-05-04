import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/lesson.dart';
import '../../services/lesson_service.dart';
import '../../services/api_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/inline_embed_player.dart';
import '../../widgets/mobile_youtube_player.dart';
import '../../l10n/app_localizations.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Lesson? _lesson;
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _videoSourceUrl;
  bool _useInlineEmbed = false;
  bool _useExternalVideoPlayer = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    _disposePlayer();

    setState(() {
      _isLoading = true;
      _error = null;
      _videoSourceUrl = null;
      _useInlineEmbed = false;
      _useExternalVideoPlayer = false;
      _webViewController = null;
    });

    try {
      _lesson = await LessonService.getLesson(widget.lessonId);

      // Initialize inline player only for direct stream-like URLs.
      if (_lesson!.isVideo) {
        _videoSourceUrl = _resolvePrimaryContentUrl(_lesson!);

        final sourceUrl = _videoSourceUrl;
        if (sourceUrl != null && sourceUrl.isNotEmpty) {
          if (!kIsWeb && _isYouTubeUrl(sourceUrl)) {
            // Mobile YouTube uses a dedicated player widget so seek works.
          } else if (_isLikelyStreamableVideoUrl(sourceUrl)) {
            try {
              _videoController = VideoPlayerController.networkUrl(
                Uri.parse(sourceUrl),
              );
              await _videoController!.initialize();
              final videoAspectRatio = _videoController!.value.aspectRatio;
              final enterFullScreenOrientations = videoAspectRatio >= 1
                  ? const [
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]
                  : const [
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown,
                    ];
              _chewieController = ChewieController(
                videoPlayerController: _videoController!,
                autoPlay: true,
                looping: false,
                allowFullScreen: true,
                allowMuting: true,
                showControls: true,
                aspectRatio: videoAspectRatio,
                deviceOrientationsOnEnterFullScreen:
                    enterFullScreenOrientations,
                deviceOrientationsAfterFullScreen: DeviceOrientation.values,
                systemOverlaysOnEnterFullScreen: const [],
                systemOverlaysAfterFullScreen: SystemUiOverlay.values,
                errorBuilder: (context, errorMessage) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 42),
                        const SizedBox(height: 8),
                        Text(
                          'Error playing video',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      ],
                    ),
                  );
                },
              );
            } catch (_) {
              _disposePlayer();
              if (kIsWeb && _canInlineEmbed(sourceUrl)) {
                _useInlineEmbed = true;
              } else {
                _useExternalVideoPlayer = true;
              }
            }
          } else {
            if (kIsWeb && _canInlineEmbed(sourceUrl)) {
              _useInlineEmbed = true;
            } else if (kIsWeb) {
              // Unknown non-streamable URLs still need the external fallback.
              _useExternalVideoPlayer = true;
            } else {
              _webViewController = _buildWebViewController(sourceUrl);
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load lesson.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _webViewController = null;
  }

  bool _canInlineEmbed(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) return false;

    final host = uri.host.toLowerCase();
    return host.contains('drive.google.com') ||
        host.contains('youtube.com') ||
        host.contains('youtube-nocookie.com') ||
        host.contains('youtu.be') ||
        host.contains('vimeo.com');
  }

  bool _isYouTubeUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtube-nocookie.com') ||
        host.contains('youtu.be');
  }

  String _toExternalPlayableUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    if (!_isYouTubeUrl(rawUrl)) return rawUrl;

    String? videoId;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      videoId = uri.pathSegments.first;
    }
    videoId ??= uri.queryParameters['v'];

    if ((videoId == null || videoId.isEmpty) && uri.pathSegments.isNotEmpty) {
      final segments = uri.pathSegments;
      final embedIndex = segments.indexOf('embed');
      if (embedIndex >= 0 && segments.length > embedIndex + 1) {
        videoId = segments[embedIndex + 1];
      }
    }

    if (videoId == null || videoId.isEmpty) {
      return rawUrl;
    }

    final params = <String, String>{'v': videoId};
    final t = uri.queryParameters['t'] ?? uri.queryParameters['start'];
    if (t != null && t.isNotEmpty) {
      params['t'] = t;
    }

    return Uri.https('www.youtube.com', '/watch', params).toString();
  }

  /// Convert a raw lesson URL into an embeddable URL for the inline WebView.
  String _toEmbedUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;

    final host = uri.host.toLowerCase();

    // YouTube: watch?v=ID → embed/ID
    if (host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
      final videoId = uri.queryParameters['v']!;
      return 'https://www.youtube.com/embed/$videoId?playsinline=1&rel=0';
    }

    // YouTube short link: youtu.be/ID
    if (host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      final videoId = uri.pathSegments.first;
      return 'https://www.youtube.com/embed/$videoId?playsinline=1&rel=0';
    }

    // Google Drive: /view → /preview
    if (host.contains('drive.google.com') && rawUrl.contains('/view')) {
      return rawUrl.replaceAll('/view', '/preview');
    }

    return rawUrl;
  }

  WebViewController _buildWebViewController(String rawUrl) {
    final isMobileYouTube = !kIsWeb && _isYouTubeUrl(rawUrl);
    final embedUrl = isMobileYouTube
        ? _toExternalPlayableUrl(
            rawUrl,
          ).replaceFirst('https://www.youtube.com/', 'https://m.youtube.com/')
        : _toEmbedUrl(rawUrl);
    final embedUri = Uri.tryParse(embedUrl);
    final fallbackHtml =
        '<!DOCTYPE html><html><body style="margin:0;background:#000;'
        'display:flex;align-items:center;justify-content:center;color:#fff;">'
        'Unable to load video.</body></html>';

    if (embedUri == null) {
      return WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(fallbackHtml);
    }

    final baseHost = embedUri.host.toLowerCase();
    final isYouTube =
        baseHost.contains('youtube.com') ||
        baseHost.contains('youtu.be') ||
        baseHost.contains('youtube-nocookie.com');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    if (isMobileYouTube) {
      controller
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final requestUri = Uri.tryParse(request.url);
              if (requestUri == null) {
                return NavigationDecision.prevent;
              }
              final scheme = requestUri.scheme.toLowerCase();
              if (scheme == 'http' || scheme == 'https') {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(
          embedUri,
          headers: const {'Referer': 'https://www.youtube.com/'},
        );
      return controller;
    }

    return controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final requestUri = Uri.tryParse(request.url);
            if (requestUri == null) {
              return NavigationDecision.prevent;
            }

            final host = requestUri.host.toLowerCase();
            final allowedHost =
                host == baseHost ||
                host.endsWith('.youtube.com') ||
                host == 'youtube.com' ||
                host == 'youtu.be' ||
                host.endsWith('youtube-nocookie.com') ||
                host.endsWith('googlevideo.com') ||
                host.endsWith('ytimg.com') ||
                host.endsWith('gstatic.com') ||
                host.endsWith('google.com') ||
                host.endsWith('googleusercontent.com') ||
                host.endsWith('vimeo.com') ||
                host.endsWith('vimeocdn.com');

            if (!allowedHost) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        embedUri,
        headers: isYouTube
            ? const {'Referer': 'https://www.youtube.com/'}
            : const <String, String>{},
      );
  }

  String? _resolvePrimaryContentUrl(Lesson lesson) {
    final signedUrl = (lesson.signedUrl ?? '').trim();
    if (signedUrl.isNotEmpty) return signedUrl;

    final fileUrl = lesson.fileUrl.trim();
    if (fileUrl.isNotEmpty) return fileUrl;

    return null;
  }

  bool _isLikelyStreamableVideoUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) return false;

    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    const knownVideoExtensions = [
      '.mp4',
      '.m3u8',
      '.webm',
      '.mov',
      '.m4v',
      '.mpd',
    ];

    if (knownVideoExtensions.any(path.endsWith)) return true;

    // Moodle pluginfile links are typically direct media/file streams.
    if (path.contains('/webservice/pluginfile.php')) return true;

    // Google Drive and YouTube links are document pages, not direct media streams.
    if (host.contains('drive.google.com') || host.contains('youtube.com')) {
      return false;
    }

    return false;
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid media URL.')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this media link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 980,
      desktop: 1180,
    );
    final hideAppBar = _lesson?.isVideo == true;

    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadLesson,
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          )
        : _buildContent(contentMaxWidth);

    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: Text(
                _lesson != null && _lesson!.title.length > 35
                    ? '${_lesson!.title.substring(0, 35)}...'
                    : _lesson?.title ?? 'Lesson',
              ),
            ),
      body: SafeArea(top: hideAppBar, bottom: false, child: body),
    );
  }

  Widget _buildContent(double contentMaxWidth) {
    if (_lesson == null) return const SizedBox.shrink();

    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video player
              if (_lesson!.isVideo && _chewieController != null)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
              else if (_lesson!.isVideo &&
                  !kIsWeb &&
                  _videoSourceUrl != null &&
                  _isYouTubeUrl(_videoSourceUrl!))
                MobileYouTubePlayer(
                  key: ValueKey(_videoSourceUrl!),
                  url: _videoSourceUrl!,
                  autoPlay: true,
                )
              else if (_lesson!.isVideo && _webViewController != null)
                // Inline WebView for YouTube / Google Drive / Vimeo links.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final videoHeight = (constraints.maxWidth * 9 / 16).clamp(
                      220.0,
                      560.0,
                    );
                    return SizedBox(
                      height: videoHeight,
                      child: WebViewWidget(controller: _webViewController!),
                    );
                  },
                )
              else if (_lesson!.isVideo &&
                  _useInlineEmbed &&
                  _videoSourceUrl != null)
                InlineEmbedPlayer(
                  key: ValueKey(_toEmbedUrl(_videoSourceUrl!)),
                  url: _toEmbedUrl(_videoSourceUrl!),
                )
              else if (_lesson!.isVideo && _useExternalVideoPlayer)
                // Web-platform fallback (WebViewWidget not available on web).
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: Colors.black,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.open_in_new,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap below to watch this video',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _videoSourceUrl == null
                            ? null
                            : () => _openExternalUrl(_videoSourceUrl!),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(AppLocalizations.of(context)!.openVideo),
                      ),
                    ],
                  ),
                )
              else if (_lesson!.isVideo)
                Container(
                  height: 250,
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_off,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.videoUnavailable,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),

              // PDF notice
              if (_lesson!.isPdf)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${AppLocalizations.of(context)!.pdf} Document',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This lesson is a PDF document.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (_resolvePrimaryContentUrl(_lesson!) != null)
                        ElevatedButton.icon(
                          onPressed: () => _openExternalUrl(
                            _resolvePrimaryContentUrl(_lesson!)!,
                          ),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(AppLocalizations.of(context)!.openFile),
                        ),
                    ],
                  ),
                ),

              // Lesson info
              Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lesson!.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_lesson!.sectionName != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _lesson!.sectionName!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_lesson!.courseTitle != null)
                      Row(
                        children: [
                          const Icon(Icons.book, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _lesson!.courseTitle!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _lesson!.isVideo
                              ? Icons.videocam
                              : Icons.picture_as_pdf,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _lesson!.isVideo ? '${AppLocalizations.of(context)!.video} Lesson' : '${AppLocalizations.of(context)!.pdf} Lesson',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (_lesson!.description != null &&
                        _lesson!.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lesson!.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

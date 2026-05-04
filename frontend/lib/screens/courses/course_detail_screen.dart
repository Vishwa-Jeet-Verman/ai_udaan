import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../services/course_service.dart';
import '../../services/lesson_service.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/inline_embed_player.dart';
import '../../widgets/mobile_youtube_player.dart';
import '../../l10n/app_localizations.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  List<Lesson> _lessons = [];
  bool _isEnrolled = false;
  int _lessonCount = 0;
  bool _isLoading = true;
  bool _isEnrolling = false;
  String? _error;

  // ── Inline video player state ──────────────────────────────────────────────
  Lesson? _selectedLesson;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;
  String? _selectedVideoUrl;
  bool _videoLoading = false;
  bool _useInlineEmbed = false;
  bool _useExternalFallback = false;
  bool _showLessonsPanel = true;

  Razorpay? _razorpay;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCourseDetail();
    _initializeRazorpay();
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    _scrollController.dispose();
    _razorpay?.clear();
    super.dispose();
  }

  void _initializeRazorpay() {
    if (kIsWeb) return; // Razorpay Flutter SDK doesn't support web
    
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadCourseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await CourseService.getCourse(widget.courseId);
      _course = result['course'] as Course;
      _isEnrolled = result['isEnrolled'] as bool;
      _lessonCount = result['lessonCount'] as int;

      // Also check local enrollment provider
      if (!mounted) return;
      final enrollProv = context.read<EnrollmentProvider>();
      if (enrollProv.isEnrolledIn(widget.courseId)) {
        _isEnrolled = true;
      }

      // If enrolled, load lessons
      if (_isEnrolled) {
        try {
          _lessons = await LessonService.listLessons(widget.courseId);
        } catch (_) {}
      }

      setState(() => _isLoading = false);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load course details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEnroll() async {
    final authProvider = context.read<AuthProvider>();

    // If not logged in, redirect to login with return route
    if (!authProvider.isLoggedIn) {
      Navigator.pushNamed(
        context,
        '/login',
        arguments: {
          'returnRoute': '/course-detail',
          'returnArg': widget.courseId,
        },
      );
      return;
    }

    // Check if course is free or paid
    if (_course!.isFree) {
      // Free course - enroll directly
      await _enrollDirectly();
    } else {
      // Paid course - initiate payment
      await _initiatePayment();
    }
  }

  Future<void> _enrollDirectly() async {
    setState(() => _isEnrolling = true);

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final success = await enrollmentProvider.enroll(widget.courseId);

    if (mounted) {
      if (success) {
        setState(() {
          _isEnrolled = true;
          _isEnrolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.enrolledSuccessfully),
            backgroundColor: const Color(0xFF1F7A63),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/my-courses');
        }
      } else {
        setState(() => _isEnrolling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enrollmentProvider.error ??
                  AppLocalizations.of(context)!.failedToEnroll,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initiatePayment() async {
    if (kIsWeb) {
      // Web doesn't support Razorpay Flutter SDK
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment is not supported on web. Please use the mobile app.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isEnrolling = true);

    try {
      // Get user email before async call
      final userEmail = context.read<AuthProvider>().user?.email ?? '';
      
      // Create order
      final orderData = await PaymentService.createOrder(widget.courseId);
      
      if (!mounted) return;
      
      final razorpayKeyId = dotenv.env['NEXT_PUBLIC_RAZORPAY_KEY_ID'] ?? '';
      
      var options = {
        'key': razorpayKeyId,
        'amount': orderData['amount'],
        'currency': orderData['currency'],
        'name': 'AI UDAAN',
        'description': _course!.title,
        'order_id': orderData['orderId'],
        'prefill': {
          'contact': '',
          'email': userEmail,
        },
        'theme': {
          'color': '#1E3A5F',
        }
      };

      _razorpay?.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEnrolling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : 'Failed to initiate payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('[Payment] ✅ Payment successful: ${response.paymentId}');
    
    try {
      // Verify payment on backend
      await PaymentService.verifyPayment(
        widget.courseId,
        response.orderId ?? '',
        response.paymentId ?? '',
        response.signature ?? '',
      );

      if (!mounted) return;
      
      // Refresh enrollments
      await context.read<EnrollmentProvider>().fetchEnrollments();
      
      if (!mounted) return;
      
      setState(() {
        _isEnrolled = true;
        _isEnrolling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! You are now enrolled.'),
          backgroundColor: Color(0xFF1F7A63),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/my-courses');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEnrolling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : 'Payment verification failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[Payment] ❌ Payment failed: ${response.message}');
    setState(() => _isEnrolling = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[Payment] 💳 External wallet: ${response.walletName}');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
      ),
    );
  }

  // ── Video player helpers ────────────────────────────────────────────────────

  void _disposeVideoPlayer() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _webViewController = null;
  }

  bool _isStreamableVideoUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    const videoExts = ['.mp4', '.m3u8', '.webm', '.mov', '.m4v', '.mpd'];
    if (videoExts.any(path.endsWith)) {
      return true;
    }
    if (path.contains('/webservice/pluginfile.php')) {
      return true;
    }
    if (host.contains('drive.google.com') ||
        host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('youtube-nocookie.com')) {
      return false;
    }
    return false;
  }

  bool _canInlineEmbed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    final host = uri.host.toLowerCase();
    return host.contains('drive.google.com') ||
        host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('youtube-nocookie.com') ||
        host.contains('vimeo.com');
  }

  bool _isYouTubeHost(String host) {
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('youtube-nocookie.com');
  }

  bool _isLikelyPortraitYouTubeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return false;
    }

    if (!_isYouTubeHost(uri.host.toLowerCase())) {
      return false;
    }

    final path = uri.path.toLowerCase();
    if (path.contains('/shorts/')) {
      return true;
    }

    final feature = (uri.queryParameters['feature'] ?? '').toLowerCase();
    return feature.contains('share') && path.contains('/shorts');
  }

  bool _isYouTubeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return false;
    }
    return _isYouTubeHost(uri.host.toLowerCase());
  }

  bool _isHttpPlayableUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  bool _isMoodleNonPlayableUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) return false;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    // Check if it's a Moodle domain
    final isMoodleUrl = host.contains('moodle') || host.contains('nighwantech');

    if (!isMoodleUrl) return false;

    // If it's a Moodle pluginfile, it's playable
    if (path.contains('/webservice/pluginfile.php')) return false;

    // Other Moodle URLs that don't have playable file extensions are not playable
    const knownVideoExtensions = ['.mp4', '.m3u8', '.webm', '.mov', '.m4v'];
    final hasVideoExtension = knownVideoExtensions.any(path.endsWith);

    return !hasVideoExtension;
  }

  String _toExternalPlayableUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;

    if (!_isYouTubeHost(uri.host.toLowerCase())) {
      return rawUrl;
    }

    final videoId = _extractYouTubeVideoId(uri);
    if (videoId == null || videoId.isEmpty) {
      return rawUrl;
    }

    final params = <String, String>{'v': videoId};
    final startSeconds = _extractYouTubeStartSeconds(uri);
    if (startSeconds != null) {
      params['t'] = '${startSeconds}s';
    }

    return Uri.https('www.youtube.com', '/watch', params).toString();
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
      return null;
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

    return null;
  }

  int? _extractYouTubeStartSeconds(Uri uri) {
    final raw =
        uri.queryParameters['start'] ??
        uri.queryParameters['t'] ??
        uri.queryParameters['time_continue'];
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final direct = int.tryParse(raw);
    if (direct != null && direct > 0) {
      return direct;
    }

    final match = RegExp(
      r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$',
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final mins = int.tryParse(match.group(2) ?? '0') ?? 0;
    final secs = int.tryParse(match.group(3) ?? '0') ?? 0;
    final total = (hours * 3600) + (mins * 60) + secs;
    return total > 0 ? total : null;
  }

  String _toEmbedUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    final host = uri.host.toLowerCase();

    if (_isYouTubeHost(host)) {
      final videoId = _extractYouTubeVideoId(uri);
      if (videoId != null && videoId.isNotEmpty) {
        final params = <String, String>{
          'controls': '1',
          'fs': '1',
          'modestbranding': '1',
          'rel': '0',
          // playsinline=1 keeps YouTube in contain-fit mode so landscape
          // videos fill without cropping when the player enters fullscreen.
          'playsinline': '1',
          'iv_load_policy': '3',
        };
        final startSeconds = _extractYouTubeStartSeconds(uri);
        if (startSeconds != null) {
          params['start'] = '$startSeconds';
        }
        final embedHost = kIsWeb
            ? 'www.youtube-nocookie.com'
            : 'www.youtube.com';
        if (!kIsWeb) {
          params['origin'] = 'https://www.youtube.com';
        }
        return Uri.https(embedHost, '/embed/$videoId', params).toString();
      }
    }

    if (host.contains('drive.google.com') && rawUrl.contains('/view')) {
      return rawUrl.replaceAll('/view', '/preview');
    }
    return rawUrl;
  }

  WebViewController _buildVideoWebController(String rawUrl) {
    final isMobileYouTube = !kIsWeb && _isYouTubeUrl(rawUrl);
    final webViewUrl = isMobileYouTube
        ? _toExternalPlayableUrl(
            rawUrl,
          ).replaceFirst('https://www.youtube.com/', 'https://m.youtube.com/')
        : _toEmbedUrl(rawUrl);
    final embedUri = Uri.tryParse(webViewUrl);
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
    final isYouTube = _isYouTubeHost(baseHost);

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
              // Allow full in-page YouTube flows (seek, fullscreen, ads, API
              // redirects) while blocking non-web deep-link schemes.
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

  Future<void> _loadLessonVideo(Lesson lesson) async {
    // Tapping the same lesson again closes the player.
    if (_selectedLesson?.id == lesson.id) {
      _disposeVideoPlayer();
      setState(() {
        _selectedLesson = null;
        _selectedVideoUrl = null;
        _useInlineEmbed = false;
        _useExternalFallback = false;
        _showLessonsPanel = true;
      });
      return;
    }

    _disposeVideoPlayer();
    setState(() {
      _selectedLesson = lesson;
      _videoLoading = true;
      _selectedVideoUrl = null;
      _useInlineEmbed = false;
      _useExternalFallback = false;
      _webViewController = null;
    });

    // Scroll to top so the player is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });

    final rawUrl =
        ((lesson.signedUrl ?? '').trim().isNotEmpty
                ? lesson.signedUrl!
                : lesson.fileUrl)
            .trim();

    if (rawUrl.isEmpty) {
      setState(() => _videoLoading = false);
      return;
    }

    setState(() {
      _selectedVideoUrl = rawUrl;
    });

    if (!kIsWeb && _isYouTubeUrl(rawUrl)) {
      setState(() => _videoLoading = false);
      return;
    }

    if (lesson.isVideo && _isStreamableVideoUrl(rawUrl)) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(rawUrl));
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
          deviceOrientationsOnEnterFullScreen: enterFullScreenOrientations,
          deviceOrientationsAfterFullScreen: DeviceOrientation.values,
          systemOverlaysOnEnterFullScreen: const [],
          systemOverlaysAfterFullScreen: SystemUiOverlay.values,
          errorBuilder: (ctx, msg) => Center(
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
          ),
        );
      } catch (_) {
        _disposeVideoPlayer();
        if (kIsWeb && (_canInlineEmbed(rawUrl) || _isHttpPlayableUrl(rawUrl))) {
          _useInlineEmbed = true;
        } else if (!kIsWeb) {
          _webViewController = _buildVideoWebController(rawUrl);
        } else {
          _useExternalFallback = true;
        }
      }
    } else if (_canInlineEmbed(rawUrl)) {
      // Only use inline embed for known embeddable sources
      _useInlineEmbed = true;
    } else if (_isMoodleNonPlayableUrl(rawUrl)) {
      // Moodle URLs that are not playable files - show "no video"
      // Don't set _webViewController or _useExternalFallback
    } else if (kIsWeb) {
      // Web platform fallback for other URLs
      _useExternalFallback = true;
    } else {
      // Mobile platform - try WebViewController
      _webViewController = _buildVideoWebController(rawUrl);
    }

    setState(() => _videoLoading = false);
  }

  double _mediaAspectRatioForWidth(double width) {
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      final aspectRatio = controller.value.aspectRatio;
      if (aspectRatio > 0) {
        return aspectRatio;
      }
    }

    if (_isYouTubeUrl(_selectedVideoUrl)) {
      if (_isLikelyPortraitYouTubeUrl(_selectedVideoUrl)) {
        return 9 / 16;
      }
      return 16 / 9;
    }

    return 16 / 9;
  }

  double _mediaHeightForWidth(double width, double aspectRatio) {
    final safeWidth = width.isFinite
        ? width
        : MediaQuery.of(context).size.width;
    return (safeWidth / aspectRatio).clamp(210.0, 520.0).toDouble();
  }

  double _horizontalPaddingForWidth(double width) {
    if (width >= 1200) {
      return 24;
    }
    if (width >= 700) {
      return 20;
    }
    return 12;
  }

  double _lessonsPanelHeightForSize({
    required double width,
    required double viewportHeight,
  }) {
    final factor = width >= 1100 ? 0.44 : (width >= 700 ? 0.40 : 0.34);
    return (viewportHeight * factor).clamp(220.0, 480.0).toDouble();
  }

  Widget _buildInlinePlayer({
    required double mediaHeight,
    required double mediaAspectRatio,
  }) {
    return Container(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_videoLoading)
            SizedBox(
              height: mediaHeight,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_chewieController != null)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            )
          else if (!kIsWeb &&
              _selectedVideoUrl != null &&
              _isYouTubeUrl(_selectedVideoUrl))
            MobileYouTubePlayer(
              key: ValueKey(_selectedVideoUrl!),
              url: _selectedVideoUrl!,
              aspectRatio: mediaAspectRatio,
              autoPlay: true,
            )
          else if (_webViewController != null)
            SizedBox(
              height: mediaHeight,
              child: WebViewWidget(controller: _webViewController!),
            )
          else if (_useInlineEmbed && _selectedVideoUrl != null)
            InlineEmbedPlayer(
              key: ValueKey(_toEmbedUrl(_selectedVideoUrl!)),
              url: _toEmbedUrl(_selectedVideoUrl!),
              aspectRatio: mediaAspectRatio,
            )
          else if (_useExternalFallback)
            SizedBox(
              height: mediaHeight,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _selectedVideoUrl == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(_selectedVideoUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context)!.openVideo),
                ),
              ),
            )
          else
            SizedBox(
              height: mediaHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: mediaHeight >= 320 ? 54 : 46,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.videoUnavailable,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasLessons => _isEnrolled && _lessons.isNotEmpty;

  Widget _buildLessonsList({VoidCallback? onLessonSelected}) {
    final Map<String, List<Lesson>> lessonsBySection = {};
    final List<String> sectionOrder = [];

    for (final lesson in _lessons) {
      final sectionKey = lesson.sectionName ?? 'Other';
      if (!lessonsBySection.containsKey(sectionKey)) {
        lessonsBySection[sectionKey] = [];
        sectionOrder.add(sectionKey);
      }
      lessonsBySection[sectionKey]!.add(lesson);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionOrder.map((sectionName) {
        final sectionLessons = lessonsBySection[sectionName]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionName != 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  sectionName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: null,
              itemCount: sectionLessons.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final lesson = sectionLessons[index];
                final isSelected = _selectedLesson?.id == lesson.id;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(20),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary.withAlpha(60)
                        : Theme.of(context).colorScheme.primary.withAlpha(30),
                    child: Icon(
                      isSelected
                          ? Icons.pause_circle_outline
                          : (lesson.isVideo
                                ? Icons.play_circle_outline
                                : Icons.picture_as_pdf),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(lesson.title),
                  subtitle: Text(
                    lesson.isVideo
                        ? AppLocalizations.of(context)!.video
                        : AppLocalizations.of(context)!.pdf,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Icon(
                    isSelected ? Icons.keyboard_arrow_up : Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: () async {
                    await _loadLessonVideo(lesson);
                    onLessonSelected?.call();
                  },
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _course!.isFree
            ? const Color(0xFF1F7A63)
            : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _course!.isFree
            ? AppLocalizations.of(context)!.free
            : '₹${_course!.price.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrimaryMedia({
    required double mediaHeight,
    required double mediaAspectRatio,
  }) {
    if (_selectedLesson != null) {
      return _buildInlinePlayer(
        mediaHeight: mediaHeight,
        mediaAspectRatio: mediaAspectRatio,
      );
    }

    if (_course?.thumbnailUrl != null && _course!.thumbnailUrl!.isNotEmpty) {
      return Image.network(
        _course!.thumbnailUrl!,
        height: mediaHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(height: mediaHeight, color: Colors.grey[300]);
        },
        errorBuilder: (_, _, _) => Container(
          height: mediaHeight,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 64, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: mediaHeight,
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary.withAlpha(30),
      child: Icon(
        Icons.school,
        size: mediaHeight >= 320 ? 90 : 72,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildLessonsStatusCard() {
    final l10n = AppLocalizations.of(context)!;
    final message = _showLessonsPanel
        ? l10n.lessonsShownBelow
        : (_selectedLesson != null ? l10n.lessonsHidden : l10n.lessonsHidden);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _showLessonsPanel
                ? Icons.playlist_play
                : Icons.visibility_off_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (!_showLessonsPanel)
            TextButton(
              onPressed: () {
                setState(() {
                  _showLessonsPanel = true;
                });
              },
              child: Text(l10n.show),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollableLessonsSection({
    required double panelHeight,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.lessons,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.available(_lessons.length),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showLessonsPanel = false;
                      });
                    },
                    icon: const Icon(Icons.visibility_off_outlined, size: 18),
                    label: Text(AppLocalizations.of(context)!.hide),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: panelHeight,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _buildLessonsList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetails({
    required double horizontalPadding,
    required bool compactMeta,
  }) {
    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _course!.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: compactMeta ? 24 : null,
            ),
          ),
          const SizedBox(height: 8),
          if (compactMeta) ...[
            if (_course!.creatorName != null) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _course!.creatorName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Align(alignment: Alignment.centerLeft, child: _buildPriceBadge()),
          ] else
            Row(
              children: [
                if (_course!.creatorName != null) ...[
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _course!.creatorName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                _buildPriceBadge(),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            '$_lessonCount lesson${_lessonCount != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_course!.description != null &&
              _course!.description!.isNotEmpty) ...[
            Text(
              'About this course',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _course!.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],
          if (!_isEnrolled) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isEnrolling ? null : _handleEnroll,
                icon: _isEnrolling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.school),
                label: Text(
                  _isEnrolling
                      ? 'Processing...'
                      : AppLocalizations.of(context)!.enrollNow,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_isEnrolled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1F7A63).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1F7A63).withAlpha(50),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF1F7A63)),
                  SizedBox(width: 8),
                  Text(
                    'You are enrolled in this course',
                    style: TextStyle(
                      color: Color(0xFF1F7A63),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_isEnrolled && _lessons.isEmpty) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No lessons available yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 1040,
      desktop: 1440,
    );
    final hideAppBar = _selectedLesson?.isVideo == true;

    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCourseDetail,
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
                _course?.title ?? 'Course Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      body: SafeArea(top: hideAppBar, bottom: false, child: body),
    );
  }

  Widget _buildContent(double contentMaxWidth) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
            final viewportHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height;
            final mediaAspectRatio = _mediaAspectRatioForWidth(viewportWidth);
            final mediaHeight = _mediaHeightForWidth(
              viewportWidth,
              mediaAspectRatio,
            );
            final horizontalPadding = _horizontalPaddingForWidth(viewportWidth);
            final compactMeta = viewportWidth < 460;
            final lessonsPanelHeight = _lessonsPanelHeightForSize(
              width: viewportWidth,
              viewportHeight: viewportHeight,
            );

            if (!_hasLessons) {
              return SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrimaryMedia(
                      mediaHeight: mediaHeight,
                      mediaAspectRatio: mediaAspectRatio,
                    ),
                    _buildCourseDetails(
                      horizontalPadding: horizontalPadding,
                      compactMeta: compactMeta,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrimaryMedia(
                    mediaHeight: mediaHeight,
                    mediaAspectRatio: mediaAspectRatio,
                  ),
                  if (_showLessonsPanel)
                    _buildScrollableLessonsSection(
                      panelHeight: lessonsPanelHeight,
                      horizontalPadding: horizontalPadding,
                    )
                  else
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        20,
                      ),
                      child: _buildLessonsStatusCard(),
                    ),
                  _buildCourseDetails(
                    horizontalPadding: horizontalPadding,
                    compactMeta: compactMeta,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

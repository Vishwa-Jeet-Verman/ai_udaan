// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class InlineEmbedPlayer extends StatefulWidget {
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
  State<InlineEmbedPlayer> createState() => _InlineEmbedPlayerState();
}

class _InlineEmbedPlayerState extends State<InlineEmbedPlayer> {
  static int _nextId = 0;
  // Injected once per page lifetime so multiple player instances don't
  // register duplicate document listeners.
  static bool _orientationListenerInjected = false;

  late final String _viewType;
  html.IFrameElement? _iframeElement;
  bool _interactionEnabled = true;

  /// Injects a tiny JS snippet that locks device orientation to landscape
  /// whenever any element enters native fullscreen (e.g. the YouTube iframe
  /// fullscreen button on mobile), and unlocks when fullscreen exits.
  /// The lock only takes effect when the document is already in fullscreen,
  /// which satisfies the browser's security requirement.
  void _injectOrientationLockScript() {
    if (_orientationListenerInjected) return;
    _orientationListenerInjected = true;
    final script = html.ScriptElement()
      ..text = r"""
(function () {
  function onFsChange() {
    try {
      var inFs = !!(document.fullscreenElement ||
                    document.webkitFullscreenElement ||
                    document.mozFullScreenElement);
      if (inFs) {
        if (screen.orientation && screen.orientation.lock) {
          screen.orientation.lock('landscape').catch(function () {});
        } else if (screen.lockOrientation) {
          screen.lockOrientation('landscape');
        } else if (screen.mozLockOrientation) {
          screen.mozLockOrientation('landscape');
        }
      } else {
        if (screen.orientation && screen.orientation.unlock) {
          screen.orientation.unlock();
        } else if (screen.unlockOrientation) {
          screen.unlockOrientation();
        } else if (screen.mozUnlockOrientation) {
          screen.mozUnlockOrientation();
        }
      }
    } catch (e) {}
  }
  document.addEventListener('fullscreenchange', onFsChange);
  document.addEventListener('webkitfullscreenchange', onFsChange);
  document.addEventListener('mozfullscreenchange', onFsChange);
})();
""";
    html.document.head?.append(script);
  }

  bool _isScrollThroughMode(BuildContext context) {
    if (widget.forceInteraction) return false;
    return MediaQuery.of(context).size.width >= 700;
  }

  void _syncIframePointerMode() {
    final iframe = _iframeElement;
    if (iframe == null || !mounted) {
      return;
    }

    final allowIframePointer =
        !_isScrollThroughMode(context) || _interactionEnabled;
    iframe.style.pointerEvents = allowIframePointer ? 'auto' : 'none';
  }

  @override
  void initState() {
    super.initState();
    _injectOrientationLockScript();
    _viewType = 'inline-embed-player-${_nextId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _iframeElement = html.IFrameElement()
        ..src = widget.url
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'auto'
        ..referrerPolicy = 'origin'
        ..setAttribute(
          'sandbox',
          // allow-popups is required for the Fullscreen API request to
          // leave the sandboxed iframe and fill the browser viewport.
          'allow-scripts allow-same-origin allow-presentation allow-forms allow-popups',
        )
        ..allow =
            'autoplay; encrypted-media; fullscreen; picture-in-picture; accelerometer; gyroscope; web-share'
        ..setAttribute('allowfullscreen', 'true')
        ..allowFullscreen = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncIframePointerMode();
      });

      return _iframeElement!;
    });
  }

  void _setInteractionEnabled(bool enabled) {
    if (_interactionEnabled == enabled) {
      return;
    }
    setState(() {
      _interactionEnabled = enabled;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncIframePointerMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enableScrollThroughMode = _isScrollThroughMode(context);
    _syncIframePointerMode();

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: [
          Positioned.fill(
            child: HtmlElementView(
              key: ValueKey(_viewType),
              viewType: _viewType,
            ),
          ),
          if (enableScrollThroughMode && !_interactionEnabled)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setInteractionEnabled(true),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Scroll mode on. Click to control video',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          if (enableScrollThroughMode)
            Positioned(
              right: 10,
              top: 10,
              child: Material(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _setInteractionEnabled(!_interactionEnabled),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      _interactionEnabled ? 'Scroll' : 'Controls',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

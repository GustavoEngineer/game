import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaelenlegacy/utils/orientation_helper.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _hasEnded = false;
  bool _showTexts = false;
  bool _isLooping = false;
  bool _playedCharging = false;
  bool _playingCharging = false;
  late final AnimationController _fadeController;
  bool _hasStartedPreFade = false;
  bool _isFading = false;
  final Duration _preFadeDuration = Duration(milliseconds: 900);
  final Duration _slowRevealDuration = Duration(milliseconds: 600);
  final Duration _quickRevealDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Note: Orientation is handled by `LandscapeOnly` wrapper.

    // Create fade controller for the charging->intro transition
    _fadeController = AnimationController(
      vsync: this,
      duration: _preFadeDuration,
    );

    // Start by playing the charging/loading clip once, then switch to
    // intro.mp4 in loop.
    _playCharging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _fadeController.dispose();
    // Orientation restored by `LandscapeOnly` dispose.
    super.dispose();
  }

  Future<void> _playCharging() async {
    // Play the charging/loading video once, then we'll switch to looping intro.
    _playedCharging = true;
    _playingCharging = true;

    try {
      _controller.removeListener(_onVideoUpdate);
      await _controller.dispose();
    } catch (_) {}

    _controller = VideoPlayerController.asset('assets/videos/charching.mp4');
    await _controller.initialize();
    if (!mounted) return;
    setState(() {});
    _controller.setLooping(false);
    _controller.setVolume(1.0);
    _controller.play();
    _controller.addListener(_onVideoUpdate);
  }

  Future<void> _startLoopingIntro() async {
    // Start intro.mp4 in looping mode and show the UI texts.
    // Prevent re-entrance
    if (_isFading) return;
    _isFading = true;

    // We'll run a small transition: if a pre-fade started, ensure it's
    // completed (screen is black) before switching. Then reveal in two
    // stages: slow then quick while intro loops.
    _isLooping = true;

    try {
      if (_hasStartedPreFade) {
        // wait for pre-fade to finish
        await _fadeController.forward();
      } else {
        // If no pre-fade, perform a quick fade to black for consistency
        await _fadeController.forward();
      }

      try {
        _controller.removeListener(_onVideoUpdate);
        await _controller.dispose();
      } catch (_) {}

      _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
      _controller.setLooping(true);
      _controller.setVolume(1.0);
      _controller.play();
      _controller.addListener(_onVideoUpdate);

      // Reveal in two stages: slow to partial, then quick to full
      await _fadeController.animateTo(
        0.4,
        duration: _slowRevealDuration,
        curve: Curves.easeInOut,
      );
      await _fadeController.animateTo(
        0.0,
        duration: _quickRevealDuration,
        curve: Curves.easeOut,
      );

      // Reveal texts now that the looping intro is playing
      _showTexts = true;
      if (mounted) setState(() {});

      // Reset pre-fade state
      _hasStartedPreFade = false;
      _playingCharging = false;
    } finally {
      _isFading = false;
    }
  }

  Future<void> _playNewGameIntro() async {
    // Prevent re-entrance
    if (_isFading) return;
    _isFading = true;

    // Hide UI texts immediately
    _showTexts = false;
    if (mounted) setState(() {});

    // Ensure we reset ended state so the listener can work correctly
    _hasEnded = false;
    _isLooping = false;

    // Fast fade to black
    await _fadeController.animateTo(
      1.0,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeIn,
    );

    // Switch to newgameintro.mp4
    try {
      _controller.removeListener(_onVideoUpdate);
      await _controller.dispose();
    } catch (_) {}

    _controller = VideoPlayerController.asset('assets/videos/newgameintro.mp4');
    await _controller.initialize();
    if (!mounted) return;
    setState(() {});
    _controller.setLooping(false);
    _controller.setVolume(1.0);
    _controller.play();
    _controller.addListener(_onVideoUpdate);

    // Quick reveal
    await _fadeController.animateTo(
      0.0,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    _isFading = false;
  }

  void _onVideoUpdate() {
    if (!_controller.value.isInitialized) return;
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    final remaining = duration - position;

    // If we're playing the charging clip, start pre-fade shortly before it ends
    if (_playingCharging &&
        !_hasStartedPreFade &&
        remaining <= _preFadeDuration) {
      _hasStartedPreFade = true;
      // start pre-fade (do not await)
      _fadeController.forward();
    }

    if (position >= duration && !_hasEnded) {
      _hasEnded = true;

      // Decide next step based on current stage:
      // - If we haven't played the charging clip yet, play it.
      // - Else if we're not looping yet, start looping intro.
      // - Otherwise, do nothing.
      if (!_playedCharging && !_isLooping) {
        _playCharging();
      } else if (!_isLooping) {
        _startLoopingIntro();
      }
    }
  }

  // Quit the game by popping the platform navigator.
  // On Android this closes the activity; on iOS programmatic exits are discouraged.
  void _quitGame() {
    SystemNavigator.pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, always restart the intro sequence from start.
      // This disposes any current controller and begins the intro clip.
      _playCharging();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LandscapeOnly(
      child: Scaffold(
        body: Stack(
          children: [
            // Background video
            SizedBox.expand(
              child: _controller.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : Container(color: Colors.black),
            ),

            // Full-screen fade overlay controlled by _fadeController. Covers the
            // entire screen so the darkening is visible during the transition
            // from `charching.mp4` to the looping `intro.mp4`.
            IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(_fadeController.value),
                  );
                },
              ),
            ),

            // Dark radial overlay in bottom-left corner (doesn't block interactions)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      // radius controls how far the dark corner reaches
                      // increased to make the dark corner cover more area
                      radius: 2.0,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp,
                    ),
                  ),
                ),
              ),
            ),

            // Top-left title + blurred menu (increased blur)
            AnimatedOpacity(
              opacity: _showTexts ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 12.0,
                    left: 6.0,
                    right: 12.0,
                    bottom: 12.0,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title without background or blur — only text with shadows
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 14.0,
                          ),
                          child: Text(
                            'Kaelen Legacy',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 3),
                                  blurRadius: 8.0,
                                  color: Colors.black87,
                                ),
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4.0,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 34.0),

                        // Menu options under the title
                        Padding(
                          padding: const EdgeInsets.only(left: 14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _playNewGameIntro,
                                child: Text(
                                  'New Game',
                                  style: TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500, // medium
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 6.0,
                                        color: Colors.black87,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.0),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 6.0,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.0),
                              GestureDetector(
                                onTap: _quitGame,
                                child: Text(
                                  'Quit game',
                                  style: TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 6.0,
                                        color: Colors.black87,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

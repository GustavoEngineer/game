import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  bool _isFadingOut = false;
  bool _isIntro = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeController);
    _controller = VideoPlayerController.asset('assets/videos/flame.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.play();
        });
        _fadeController.forward();
        _controller.addListener(_videoListener);
      });
  }

  void _videoListener() {
    if (!_isFadingOut && !_isIntro && _controller.value.isInitialized) {
      final duration = _controller.value.duration;
      final position = _controller.value.position;
      if (duration.inMilliseconds > 0 &&
          duration.inSeconds - position.inSeconds <= 1) {
        _isFadingOut = true;
        _fadeController.reverse().then((_) async {
          await _controller.pause();
          await _controller.dispose();
          _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
          await _controller.initialize();
          setState(() {
            _isIntro = true;
            _isInitialized = true;
            _isFadingOut = false;
          });
          _controller.play();
          _fadeController.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized)
            SizedBox.expand(child: VideoPlayer(_controller))
          else
            Container(color: Colors.black),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(color: Colors.black),
              );
            },
          ),
        ],
      ),
    );
  }
}

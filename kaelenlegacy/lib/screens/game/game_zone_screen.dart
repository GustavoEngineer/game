import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GameZoneScreen extends StatefulWidget {
  final VoidCallback? onVideoEnd;
  const GameZoneScreen({Key? key, this.onVideoEnd}) : super(key: key);

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  double _videoOpacity = 1.0;
  bool _showMap = false;
  double _scale = 1.0;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/newgameintro.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setLooping(false);
        _controller.addListener(_videoListener);
      });
  }

  void _videoListener() {
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (!_isZooming &&
        !_showMap &&
        duration.inMilliseconds > 0 &&
        duration.inMilliseconds - position.inMilliseconds <= 1000) {
      // Iniciar animación de zoom 1 segundo antes de terminar
      _isZooming = true;
      setState(() {
        _scale = 1.0;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        setState(() {
          _scale = 1.3;
        });
      });
      Future.delayed(const Duration(milliseconds: 950), () {
        setState(() {
          _videoOpacity = 0.0;
        });
      });
      Future.delayed(const Duration(milliseconds: 1100), () {
        setState(() {
          _showMap = true;
          _isInitialized = false;
          _scale = 1.0;
          _videoOpacity = 1.0;
        });
        _controller.removeListener(_videoListener);
        _controller.dispose();
        _controller = VideoPlayerController.asset('assets/videos/showmap.mp4')
          ..initialize().then((_) {
            setState(() {
              _isInitialized = true;
            });
            _controller.play();
            _controller.setLooping(false);
            // Si quieres una acción al terminar showmap.mp4, puedes agregar otro listener aquí
          });
      });
    } else if (_showMap && position >= duration) {
      if (widget.onVideoEnd != null) {
        widget.onVideoEnd!();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isInitialized
            ? AnimatedOpacity(
                opacity: _videoOpacity,
                duration: const Duration(milliseconds: 100),
                child: AnimatedScale(
                  scale: _scale,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: SizedBox.expand(child: VideoPlayer(_controller)),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

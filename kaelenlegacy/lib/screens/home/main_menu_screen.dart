import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'providers/menu_carousel_provider.dart';
import '../game/game_zone_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showGameZone = false;
  // Para evitar que la ruleta y la sombra se muestren cuando inicia el video de New Game
  void _onMenuOptionChanged(String option) async {
    if (option == 'Store' &&
        _controller.dataSource != 'assets/videos/store.mp4') {
      await _changeVideo('assets/videos/store.mp4');
    } else if (option != 'Store' &&
        _controller.dataSource == 'assets/videos/store.mp4') {
      await _changeVideo('assets/videos/intro.mp4');
    }
    if (option == 'New Game') {
      setState(() {
        _showGameZone = true;
      });
    }
  }

  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  bool _isInitialized = false;
  bool _isFadingOut = false;
  bool _isIntro = false;
  bool _showTitle = false;
  double _videoOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
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
          _controller.setLooping(true); // <-- ya está aquí
          setState(() {
            _isIntro = true;
            _isInitialized = true;
            _isFadingOut = false;
            _showTitle = false;
          });
          _controller.play();
          _fadeController.forward();
          Future.delayed(const Duration(milliseconds: 1000), () {
            setState(() {
              _showTitle = true;
            });
          });
        });
      }
    }
  }

  Future<void> _changeVideo(String asset) async {
    setState(() => _videoOpacity = 0.0); // Fade out
    await Future.delayed(const Duration(milliseconds: 100));
    await _controller.pause();
    await _controller.dispose();
    _controller = VideoPlayerController.asset(asset);
    await _controller.initialize();
    // Reproducir en bucle si es intro.mp4 o store.mp4
    if (asset == 'assets/videos/intro.mp4' ||
        asset == 'assets/videos/store.mp4') {
      _controller.setLooping(true);
    } else {
      _controller.setLooping(false);
    }
    setState(() {
      _isInitialized = true;
      _videoOpacity = 0.0;
    });
    _controller.play();
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _videoOpacity = 1.0); // Fade in
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
      body: _showGameZone
          ? GameZoneScreen()
          : Stack(
              children: [
                if (_isInitialized)
                  Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: _videoOpacity,
                        duration: const Duration(milliseconds: 100),
                        child: SizedBox.expand(child: VideoPlayer(_controller)),
                      ),
                      // Mostrar la sombra solo cuando la ruleta está visible (durante intro.mp4)
                      if (_isIntro)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.black54,
                                  Colors.black,
                                ],
                                stops: [0.0, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      // Mostrar la ruleta de opciones solo durante el video "intro.mp4"
                      if (_isIntro)
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.18,
                          right: 32,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            width: 120,
                            child: MenuCarousel(
                              vertical: true,
                              onOptionChanged: _onMenuOptionChanged,
                            ),
                          ),
                        ),
                    ],
                  )
                else if (_showTitle) ...[
                  // Título centrado arriba
                  Positioned(
                    left: 0,
                    right: 0,
                    top: MediaQuery.of(context).size.height * 0.18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Kaelen',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.bold,
                            fontSize: 42,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Legacy',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.bold,
                            fontSize: 42,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ruleta de opciones vertical y pegada a la derecha
                  // (ya no se muestra aquí)
                ],
              ],
            ),
    );
  }
}

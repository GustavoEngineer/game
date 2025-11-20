import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'providers/menu_carousel_provider.dart';
import '../gamezone/game_zone_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  bool _isInitialized = false;
  double _videoOpacity = 1.0;

  // Nueva variable para controlar la animación de carga
  bool _showPreHome = true;
  int _menuSelectedIndex = 0; // <-- Nuevo estado
  double _zoomScale = 1.0;
  bool _isZooming = false;
  bool _isTransitioning = false;
  double _fadeToBlack = 0.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Inicia con el video de carga principal
    _controller = VideoPlayerController.asset('assets/videos/flame.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.setLooping(false);
          _controller.play();
          _videoOpacity = 1.0;
        });
        _fadeController.forward();
        // Listener para detectar fin del video de carga
        _controller.addListener(_preHomeListener);
      });
  }

  void _preHomeListener() async {
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (duration.inMilliseconds > 0 && position >= duration) {
      _controller.removeListener(_preHomeListener);
      await _controller.pause();
      await _controller.dispose();
      // Cambia a la pantalla principal (home)
      setState(() {
        _showPreHome = false;
        _isInitialized = false;
      });
      // Inicializa el video de fondo principal
      _controller = VideoPlayerController.asset('assets/videos/intro.mp4')
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
            _controller.setLooping(true);
            _controller.play();
            _videoOpacity = 1.0;
          });
        });
    }
  }

  void _onMenuOptionChanged(String option) async {
    final cleanOption = option.replaceAll('\n', ' ');
    // Solo acciones especiales al tap en "New Game" y "Quit"
    if (cleanOption == 'New Game') {
      setState(() => _videoOpacity = 0.0);
      await Future.delayed(const Duration(milliseconds: 500));
      await _controller.pause();
      await _controller.dispose();
      _controller = VideoPlayerController.asset(
        'assets/videos/newgameintro.mp4',
      );
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
        _videoOpacity = 0.0;
      });
      _controller.play();
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _videoOpacity = 1.0);
      _controller.addListener(() async {
        final duration = _controller.value.duration;
        final position = _controller.value.position;
        if (duration.inMilliseconds > 0) {
          if (!_isZooming &&
              duration.inMilliseconds - position.inMilliseconds <= 2000) {
            setState(() {
              _isZooming = true;
              _zoomScale = 1.0;
              _fadeToBlack = 0.0;
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              setState(() {
                _zoomScale = 1.2;
                _fadeToBlack = 1.0;
              });
            });
          }
          if (position >= duration && !_isTransitioning) {
            setState(() {
              _isTransitioning = true;
            });
            await Future.delayed(const Duration(milliseconds: 200));
            await _controller.pause();
            await _controller.dispose();
            setState(() {
              _videoOpacity = 0.0;
              _isInitialized = false;
              _isZooming = false;
              _zoomScale = 1.0;
              _fadeToBlack = 0.0;
              _isTransitioning = false;
            });
            _controller = VideoPlayerController.asset(
              'assets/videos/showmap.mp4',
            );
            await _controller.initialize();
            setState(() {
              _isInitialized = true;
            });
            _controller.play();
            await Future.delayed(const Duration(milliseconds: 400));
            setState(() {
              _videoOpacity = 1.0;
            });
          }
        }
      });
    }
    if (cleanOption == 'Quit') {
      Future.delayed(const Duration(milliseconds: 300), () {
        SystemNavigator.pop();
      });
    }
  }

  Future<void> _changeVideo(String asset) async {
    setState(() => _videoOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 100));
    await _controller.pause();
    await _controller.dispose();
    _controller = VideoPlayerController.asset(asset);
    await _controller.initialize();
    if (asset == 'assets/videos/intro.mp4' ||
        asset == 'assets/videos/store.mp4' ||
        asset == 'assets/videos/settings.mp4') {
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
    setState(() => _videoOpacity = 1.0);
  }

  @override
  void dispose() {
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
            Stack(
              children: [
                AnimatedOpacity(
                  opacity: _videoOpacity,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedScale(
                    scale: _zoomScale,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: SizedBox.expand(child: VideoPlayer(_controller)),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _fadeToBlack,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (_controller.dataSource == 'assets/videos/showmap.mp4')
                  Positioned(
                    bottom: 32,
                    right: 32,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _videoOpacity = 0.0);
                        await Future.delayed(const Duration(milliseconds: 300));
                        await _controller.pause();
                        await _controller.dispose();
                        _controller = VideoPlayerController.asset(
                          'assets/videos/intro.mp4',
                        );
                        await _controller.initialize();
                        setState(() {
                          _isInitialized = true;
                          _showPreHome = false;
                          _videoOpacity = 0.0;
                          _zoomScale = 1.0;
                          _fadeToBlack = 0.0;
                        });
                        _controller.setLooping(true);
                        _controller.play();
                        await Future.delayed(const Duration(milliseconds: 200));
                        setState(() {
                          _videoOpacity = 1.0;
                        });
                      },
                      child: Text(
                        'exit',
                        style: TextStyle(
                          fontFamily: 'Spectral',
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.w300, // Light
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 6,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          // Solo muestra el home si terminó la animación de carga principal
          // Sombra izquierda: sólo cuando el fondo es el video por defecto (intro.mp4)
          if (!_showPreHome &&
              _controller.dataSource == 'assets/videos/intro.mp4') ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.transparent, Colors.black54, Colors.black],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.03,
              top: MediaQuery.of(context).size.height * 0.12,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.42,
                height: MediaQuery.of(context).size.height * 0.76,
                child: Center(
                  child: Text(
                    'Kaelen Legacy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 80,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        const Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 4,
                          color: Colors.black38,
                        ),
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 10,
                          color: Color(0xFFFFD700).withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (!_showPreHome &&
              _controller.dataSource != 'assets/videos/newgameintro.mp4' &&
              _controller.dataSource != 'assets/videos/showmap.mp4')
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black54, Colors.black],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          if (!_showPreHome &&
              _isInitialized &&
              _controller.dataSource != 'assets/videos/newgameintro.mp4' &&
              _controller.dataSource != 'assets/videos/showmap.mp4')
            Positioned(
              top: MediaQuery.of(context).size.height * 0.18,
              right: 32,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: 120,
                child: MenuCarousel(
                  vertical: true,
                  onOptionChanged: _onMenuOptionChanged,
                  selectedIndex: _menuSelectedIndex,
                  onPageChanged: (index) async {
                    setState(() {
                      _menuSelectedIndex = index;
                    });
                    // Cambia el fondo/video al cambiar de opción
                    final option = [
                      'New Game',
                      'Store',
                      'Settings',
                      'Quit',
                    ][index];
                    if (option == 'Store' &&
                        _controller.dataSource != 'assets/videos/store.mp4') {
                      await _changeVideo('assets/videos/store.mp4');
                    } else if (option == 'Settings' &&
                        _controller.dataSource !=
                            'assets/videos/settings.mp4') {
                      await _changeVideo('assets/videos/settings.mp4');
                    } else if (option != 'Store' &&
                        option != 'Settings' &&
                        (_controller.dataSource == 'assets/videos/store.mp4' ||
                            _controller.dataSource ==
                                'assets/videos/settings.mp4')) {
                      await _changeVideo('assets/videos/intro.mp4');
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

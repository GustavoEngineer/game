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
    if (option == 'Store' &&
        _controller.dataSource != 'assets/videos/store.mp4') {
      await _changeVideo('assets/videos/store.mp4');
    } else if (option == 'Settings' &&
        _controller.dataSource != 'assets/videos/settings.mp4') {
      await _changeVideo('assets/videos/settings.mp4');
    } else if (option != 'Store' &&
        option != 'Settings' &&
        (_controller.dataSource == 'assets/videos/store.mp4' ||
            _controller.dataSource == 'assets/videos/settings.mp4')) {
      await _changeVideo('assets/videos/intro.mp4');
    }
    if (option == 'New Game') {
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
        if (duration.inMilliseconds > 0 && position >= duration) {
          await _controller.pause();
        }
      });
    }
    if (option == 'Quit') {
      // Cierra la aplicación
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
            AnimatedOpacity(
              opacity: _videoOpacity,
              duration: const Duration(milliseconds: 800),
              child: SizedBox.expand(child: VideoPlayer(_controller)),
            ),
          // Solo muestra el home si terminó la animación de carga principal
          if (!_showPreHome)
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
          if (!_showPreHome)
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
      ),
    );
  }
}

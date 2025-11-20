import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:kaelenlegacy/screens/home/home_screen.dart'; // Importa el widget HomeScreen
import 'package:video_player/video_player.dart'; // Importa el widget VideoPlayer

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.setLooping(true);
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (_isInitialized) SizedBox.expand(child: VideoPlayer(_controller)),
          // Botón "X" en la esquina superior izquierda
          Positioned(
            top: 24,
            left: 24,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        HomeScreen(), // Regresa a HomeScreen
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: Duration(milliseconds: 400),
                  ),
                );
              },
              tooltip: 'Cerrar',
            ),
          ),
          Align(
            alignment: Alignment(-0.7, 0.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * 0.37,
              height: MediaQuery.of(context).size.height,
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        top: 32,
                        left: 32,
                        right: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Iniciar Sesión',
                            style: const TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomInputField(
                            hintText: 'Usuario',
                            obscureText: false,
                          ),
                          const SizedBox(height: 16),
                          CustomInputField(
                            hintText: 'Contraseña',
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            onPressed: () {
                              // Acción de login
                            },
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
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

// Custom input field widget
class CustomInputField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  const CustomInputField({required this.hintText, required this.obscureText});

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showGold = _hasFocus || _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      obscureText: widget.obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.black,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero, // <-- Sin bordes redondeados
          borderSide: BorderSide(
            color: showGold ? Color(0xFFFFD700) : Colors.white24,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero, // <-- Sin bordes redondeados
          borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
// Orientation changes are intentionally avoided for GameZone; we keep
// the helper available elsewhere but don't need it in this file.
import 'dart:typed_data';
import 'dart:async';
import 'package:kaelenlegacy/utils/image_rotator.dart';
import 'package:kaelenlegacy/utils/fade_utils.dart';

class GameZoneScreen extends StatefulWidget {
  final Uint8List? rotatedBackground;
  final Completer<void>? onImageReadyCompleter;

  const GameZoneScreen({
    Key? key,
    this.rotatedBackground,
    this.onImageReadyCompleter,
  }) : super(key: key);

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _rotatedImageBytes;
  bool _rotationRequested = false;
  late final AnimationController _fadeController;
  bool _hasRevealed = false;
  bool _imageReadySignaled = false;

  @override
  void initState() {
    super.initState();
    // We intentionally avoid forcing device orientation here so the
    // OS does not animate a rotation. The UI will display a pre-rotated
    // background image so the screen appears horizontal immediately.

    // Use provided rotated bytes if passed; otherwise request a cached
    // rotated version. This will avoid repeated rotations and will
    // usually return immediately if prewarmed (see HomeScreen).
    if (widget.rotatedBackground != null) {
      _rotatedImageBytes = widget.rotatedBackground;
    }

    // Prepare fade controller: start fully dark and reveal when image is ready
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeController.value = 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If the app is currently in portrait (unlikely when app is global
    // landscape), ensure we have a rotated background ready. If the app
    // is in landscape, we'll display the original asset directly.
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait && !_rotationRequested) {
      _rotationRequested = true;
      if (_rotatedImageBytes == null) {
        getRotatedAsset('assets/images/mapbackground.png')
            .then((bytes) {
              if (!mounted) return;
              setState(() {
                _rotatedImageBytes = bytes;
              });
            })
            .catchError((e) {
              debugPrint(
                '[GameZoneScreen] failed to load rotated background: $e',
              );
            });
      }
    }

    // If we're in landscape, mark reveal state. The actual reveal and
    // notification will be triggered when the image paints its first
    // frame via the frameBuilder in the widget tree so we can be sure
    // the texture is attached before removing the previous video surface.
    if (orientation == Orientation.landscape && !_hasRevealed) {
      _hasRevealed = true;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signalImageReadyAfterFade() async {
    if (_imageReadySignaled) return;
    _imageReadySignaled = true;
    // Run the fade-in so the image reveals smoothly.
    await lighten(_fadeController, duration: const Duration(milliseconds: 700));
    // Notify Home (if provided) that the GameZone has finished its
    // reveal and it's safe to release video resources.
    try {
      if (widget.onImageReadyCompleter != null &&
          !widget.onImageReadyCompleter!.isCompleted) {
        widget.onImageReadyCompleter!.complete();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: orientation == Orientation.landscape
                // App is landscape: show the original asset (no rotation needed)
                ? Image.asset(
                    'assets/images/mapbackground.png',
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    frameBuilder:
                        (
                          BuildContext context,
                          Widget child,
                          int? frame,
                          bool wasSynchronouslyLoaded,
                        ) {
                          if ((frame != null || wasSynchronouslyLoaded) &&
                              !_imageReadySignaled) {
                            _signalImageReadyAfterFade();
                          }
                          return child;
                        },
                  )
                // App is portrait: show the pre-rotated bytes if available
                : (_rotatedImageBytes == null
                      ? Container(color: Colors.black)
                      : Image.memory(
                          _rotatedImageBytes!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          frameBuilder:
                              (
                                BuildContext context,
                                Widget child,
                                int? frame,
                                bool wasSynced,
                              ) {
                                if ((frame != null || wasSynced) &&
                                    !_imageReadySignaled) {
                                  _signalImageReadyAfterFade();
                                }
                                return child;
                              },
                        )),
          ),

          // Full-screen fade overlay controlled by _fadeController.
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
        ],
      ),
    );
  }
}

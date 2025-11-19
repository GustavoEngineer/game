import 'package:flutter/material.dart';

class MenuCarousel extends StatefulWidget {
  final bool vertical;
  final ValueChanged<String>? onOptionChanged;
  final int selectedIndex;
  final ValueChanged<int>? onPageChanged;

  const MenuCarousel({
    this.vertical = false,
    this.onOptionChanged,
    this.selectedIndex = 0,
    this.onPageChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuCarousel> createState() => _MenuCarouselState();
}

class _MenuCarouselState extends State<MenuCarousel> {
  final List<String> options = ['New\nGame', 'Store', 'Settings', 'Quit'];
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.5, // Muestra más de las opciones vecinas
    );
  }

  @override
  void didUpdateWidget(covariant MenuCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _currentIndex) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      _currentIndex = widget.selectedIndex;
    }
  }

  void _onTap(int index) {
    widget.onOptionChanged?.call(options[index]);
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.vertical ? 200 : 100,
      width: widget.vertical ? null : 400,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: widget.vertical ? Axis.vertical : Axis.horizontal,
        itemCount: options.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          widget.onPageChanged?.call(index);
        },
        itemBuilder: (context, index) {
          double selected = widget.selectedIndex.toDouble();
          double distance = (selected - index).abs();
          double scale = 1 - (distance * 0.3).clamp(0.0, 0.7);
          double opacity = 1 - (distance * 0.5).clamp(0.3, 0.7);

          return Center(
            child: GestureDetector(
              onTap: () => _onTap(index),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Spectral',
                      fontStyle: FontStyle.italic,
                      fontSize: 44,
                      color: index == _currentIndex
                          ? Color(0xFFFFD700)
                          : Colors.grey.shade400,
                      fontWeight: index == _currentIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 8,
                          color: index == _currentIndex
                              ? Color(0xFFFFD700).withOpacity(0.5)
                              : Colors.black54,
                        ),
                      ],
                    ),
                    child: Text(
                      options[index],
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

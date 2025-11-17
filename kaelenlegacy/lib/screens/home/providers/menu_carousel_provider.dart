import 'package:flutter/material.dart';

class MenuCarousel extends StatefulWidget {
  final bool vertical;
  final ValueChanged<String>? onOptionChanged;
  const MenuCarousel({this.vertical = false, this.onOptionChanged, Key? key})
    : super(key: key);

  @override
  State<MenuCarousel> createState() => _MenuCarouselState();
}

class _MenuCarouselState extends State<MenuCarousel> {
  final List<String> options = ['New Game', 'Settings', 'Store', 'Quit'];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pageView = PageView.builder(
      scrollDirection: widget.vertical ? Axis.horizontal : Axis.vertical,
      itemCount: options.length,
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final isSelected = index == _selectedIndex;
        final textWidget = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: isSelected ? 16 : 8),
          child: Text(
            options[index],
            style: TextStyle(
              fontFamily: 'Spectral',
              fontStyle: FontStyle.italic,
              fontSize: isSelected ? 36 : 28,
              color: isSelected ? Colors.white : Colors.white54,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 6,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        );
        return Center(
          child: GestureDetector(
            onTap: isSelected && widget.onOptionChanged != null
                ? () => widget.onOptionChanged!(options[index])
                : null,
            child: widget.vertical
                ? RotatedBox(quarterTurns: -1, child: textWidget)
                : textWidget,
          ),
        );
      },
    );

    return widget.vertical
        ? RotatedBox(quarterTurns: 1, child: pageView)
        : pageView;
  }
}

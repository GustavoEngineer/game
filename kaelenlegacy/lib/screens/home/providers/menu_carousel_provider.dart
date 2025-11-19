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
  final List<String> options = ['New Game', 'Store', 'Settings', 'Quit'];
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
        // Llama al callback al cambiar de página
        if (widget.onOptionChanged != null) {
          widget.onOptionChanged!(options[index]);
        }
      },
      itemBuilder: (context, index) {
        final isSelected = index == _selectedIndex;
        final textWidget = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: isSelected ? 20 : 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              options[index],
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'Spectral',
                fontStyle: FontStyle.italic,
                fontSize: isSelected ? 44 : 28,
                color: isSelected
                    ? Color(0xFFFFD700)
                    : Colors.white54, // Dorado para seleccionado
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 8,
                    color: isSelected
                        ? Color(0xFFFFD700).withOpacity(0.5)
                        : Colors.black54,
                  ),
                ],
              ),
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

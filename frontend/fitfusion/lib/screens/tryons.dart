import 'package:flutter/material.dart';

class Tryons extends StatefulWidget {
  final String topImage;
  final String bottomImage;
  final String model;

  const Tryons({
    super.key,
    required this.topImage,
    required this.bottomImage,
    required this.model,
  });
  @override
  State<Tryons> createState() => _TryonsState();
}

class _TryonsState extends State<Tryons> {
  double _shirtScale = 1.6;
  double _bottomWearScale = 1.9;
  Offset _shirtPosition = const Offset(0, 0);
  Offset _bottomWearPosition = const Offset(0, 0);

  final GlobalKey _globalKey = GlobalKey();

  void _updateShirtPosition(DragUpdateDetails details) {
    setState(() {
      _shirtPosition += details.delta;
    });
  }

  void _updateBottomWearPosition(DragUpdateDetails details) {
    setState(() {
      _bottomWearPosition += details.delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: Center(
            child: RepaintBoundary(
              key: _globalKey,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    widget.model,
                  ),

                  // Draggable shirt
                  Positioned(
                    top: 350 + _bottomWearPosition.dy,
                    left: 0 + _bottomWearPosition.dx,
                    child: GestureDetector(
                      onPanUpdate: _updateBottomWearPosition,
                      child: Image.network(
                        widget.bottomImage,
                        width: 100 * _bottomWearScale,
                        height: 150 * _bottomWearScale,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150 + _shirtPosition.dy,
                    left: 0 + _shirtPosition.dx,
                    child: GestureDetector(
                      onPanUpdate: _updateShirtPosition,
                      child: Image.network(
                        widget.topImage,
                        width: 100 * _shirtScale,
                        height: 150 * _shirtScale,
                      ),
                    ),
                  ),

                  // Draggable bottom wear
                ],
              ),
            ),
          ),
        ),
        // Sliders for scaling
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Shirt Scale: ${_shirtScale.toStringAsFixed(1)}'),
        ),
        Slider(
          value: _shirtScale,
          min: 1.0,
          max: 3.0,
          onChanged: (value) {
            setState(() {
              _shirtScale = value;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child:
              Text('Bottom Wear Scale: ${_bottomWearScale.toStringAsFixed(1)}'),
        ),
        Slider(
          value: _bottomWearScale,
          min: 1.0,
          max: 3.0,
          onChanged: (value) {
            setState(() {
              _bottomWearScale = value;
            });
          },
        ),
      ],
    ));
  }
}

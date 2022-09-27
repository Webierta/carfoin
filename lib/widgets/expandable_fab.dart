// https://docs.flutter.dev/cookbook/effects/expandable-fab
// https://medium.com/@agungsurya/create-a-simple-animated-floatingactionbutton-in-flutter-2d24f37cfbcc

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../utils/styles.dart';

class ChildFab {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  const ChildFab({
    required this.onPressed,
    required this.icon,
    required this.label,
  });
}

@immutable
class ExpandableFab extends StatefulWidget {
  final IconData icon;
  final List<ChildFab> children;
  final bool? initialOpen;
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.icon,
    required this.children,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() {
    setState(() {
      _open = !_open;
      _open ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingChildFabs(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            heroTag: 'Open Fab',
            onPressed: toggle,
            foregroundColor: blue900,
            backgroundColor: amber,
            child: Icon(widget.icon),
          ),
          /*child: SizedBox(
            width: 56.0,
            height: 56.0,
            child: Center(
              child: Material(
                shape: const CircleBorder(),
                color: amber,
                clipBehavior: Clip.antiAlias,
                elevation: 4.0,
                child: InkWell(
                  onTap: toggle,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(widget.icon, color: blue900),
                  ),
                ),
              ),
            ),
          ),*/
        ),
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.close, color: Theme.of(context).primaryColor),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingChildFabs() {
    final children = <Widget>[];
    double step = 70;
    for (var i = 0; i < widget.children.length; i++, step += 70) {
      children.add(
        _ExpandingChildFab(
          directionInDegrees: 90,
          maxDistance: step,
          progress: _expandAnimation,
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: blue900,
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
                child: Text(
                  widget.children[i].label,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              /*FloatingActionButton(
                heroTag: widget.children[i].label,
                onPressed: () {
                  toggle();
                  widget.children[i].onPressed();
                },
                foregroundColor: blue900,
                backgroundColor: amber,
                child: widget.children[i].icon,
              ),*/
              Material(
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                color: amber,
                elevation: 4.0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      toggle();
                      widget.children[i].onPressed();
                    },
                    icon: widget.children[i].icon,
                    color: blue900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return children;
  }
}

@immutable
class _ExpandingChildFab extends StatelessWidget {
  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;
  const _ExpandingChildFab({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(opacity: progress, child: child),
    );
  }
}

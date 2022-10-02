library flutter_expandable_fab;

import 'dart:async' show Timer;
import 'dart:math' as math show pi, max;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/*
https://docs.flutter.dev/cookbook/effects/expandable-fab
https://medium.com/@agungsurya/create-a-simple-animated-floatingactionbutton-in-flutter-2d24f37cfbcc
https://github.com/zuvola/flutter_expandable_fab/blob/master/lib/flutter_expandable_fab.dart
https://pub.dev/packages/flutter_expandable_fab
https://www.kindacode.com/article/flutter-floating-action-button/
*/

class ChildFab {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  const ChildFab(
      {required this.onPressed, required this.icon, required this.label});
}

enum ExpandableFabType { fan, up, left }

@immutable
class ExpandableFabOverlayStyle {
  final Color? color;
  final double? blur;
  const ExpandableFabOverlayStyle({this.color, this.blur});
}

@immutable
class ExpandableFabCloseButtonStyle {
  final Widget child;
  final Color? foregroundColor;
  final Color? backgroundColor;
  const ExpandableFabCloseButtonStyle({
    this.child = const Icon(Icons.close),
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.grey,
  });
}

class _ExpandableFabLocation extends StandardFabLocation {
  final ValueNotifier<ScaffoldPrelayoutGeometry?> scaffoldGeometry =
      ValueNotifier(null);

  @override
  double getOffsetX(
      ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    Future.microtask(() {
      this.scaffoldGeometry.value = scaffoldGeometry;
    });
    return 0;
  }

  @override
  double getOffsetY(
      ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    return 0;
  }
}

@immutable
class ExpandableFab extends StatefulWidget {
  static final FloatingActionButtonLocation location = _ExpandableFabLocation();

  final double distance;
  final Duration duration;
  final double fanAngle;
  final bool initialOpen;
  final ExpandableFabType type;
  final ExpandableFabCloseButtonStyle closeButtonStyle;
  final Widget child;
  final Offset childrenOffset;
  final List<ChildFab> children;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final ExpandableFabOverlayStyle? overlayStyle;
  final bool? isEndDocked;

  const ExpandableFab({
    Key? key,
    this.distance = 70.0, // 100
    this.duration = const Duration(milliseconds: 250),
    this.fanAngle = 90,
    this.initialOpen = false,
    this.type = ExpandableFabType.up, // fan
    this.closeButtonStyle = const ExpandableFabCloseButtonStyle(),
    this.foregroundColor = const Color(0xFF0D47A1),
    this.backgroundColor = const Color(0xFFFFC107),
    this.child = const Icon(Icons.menu),
    this.childrenOffset = const Offset(4, 4),
    required this.children,
    this.onOpen,
    this.onClose,
    this.overlayStyle = const ExpandableFabOverlayStyle(
      color: Color(0x80000000),
    ),
    this.isEndDocked = false,
  }) : super(key: key);

  @override
  State<ExpandableFab> createState() => ExpandableFabState();
}

class ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;
  bool _isLabel = false;
  bool get isOpen => _open;
  bool get isLabel => _isLabel;

  void toggle() {
    setState(() => _open = !_open);
    if (_open) {
      widget.onOpen?.call();
      _controller.forward();
      Timer(const Duration(milliseconds: 250), () {
        setState(() => _isLabel = true);
      });
    } else {
      setState(() => _isLabel = false);
      widget.onClose?.call();
      _controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: widget.duration,
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

  @override
  Widget build(BuildContext context) {
    final location = ExpandableFab.location as _ExpandableFabLocation;
    Offset? offset;
    Widget? cache;
    return ValueListenableBuilder<ScaffoldPrelayoutGeometry?>(
      valueListenable: location.scaffoldGeometry,
      builder: ((context, geometry, child) {
        if (geometry == null) {
          return const SizedBox.shrink();
        }
        final x = kFloatingActionButtonMargin + geometry.minInsets.right;
        final bottomContentHeight =
            geometry.scaffoldSize.height - geometry.contentBottom;
        final y = kFloatingActionButtonMargin +
            math.max(geometry.minViewPadding.bottom, bottomContentHeight);
        if (offset != Offset(x, y)) {
          offset = Offset(x, y);
          cache = _buildButtons(offset!);
        }
        return cache!;
      }),
    );
  }

  Widget _buildButtons(Offset offset) {
    final blur = widget.overlayStyle?.blur;
    final overlayColor = widget.overlayStyle?.color;
    return GestureDetector(
      onTap: () => toggle(),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(),
          if (blur != null)
            IgnorePointer(
              ignoring: !_open,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: _open ? blur : 0.0),
                duration: widget.duration,
                curve: Curves.easeInOut,
                builder: (_, value, child) {
                  if (value < 0.001) return child!;
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                    child: child,
                  );
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          if (overlayColor != null)
            IgnorePointer(
              ignoring: !_open,
              child: AnimatedOpacity(
                duration: widget.duration,
                opacity: _open ? 1 : 0,
                curve: Curves.easeInOut,
                child: widget.isEndDocked == true
                    ? Transform.translate(
                        offset: offset, // const Offset(16, 0),
                        child: Container(color: overlayColor))
                    : Container(color: overlayColor),
              ),
            ),
          ..._buildExpandingActionButtons(offset),
          Transform.translate(
            offset: -offset,
            child: Stack(
              alignment: Alignment.center,
              children: [_buildTapToCloseFab(), _buildTapToOpenFab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    final style = widget.closeButtonStyle;
    return FloatingActionButton.small(
      heroTag: null,
      foregroundColor: style.foregroundColor,
      backgroundColor: style.backgroundColor,
      onPressed: toggle,
      child: style.child,
    );
  }

  List<Widget> _buildExpandingActionButtons(Offset offset) {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = widget.fanAngle / (count - 1);
    for (var i = 0; i < count; i++) {
      final double dir, dist;
      switch (widget.type) {
        case ExpandableFabType.fan:
          dir = step * i;
          dist = widget.distance;
          break;
        case ExpandableFabType.up:
          dir = 90;
          dist = widget.distance * (i + 1);
          break;
        case ExpandableFabType.left:
          dir = 0;
          dist = widget.distance * (i + 1);
          break;
      }
      children.add(
        _ExpandingActionButton(
          directionInDegrees: dir + (90 - widget.fanAngle) / 2,
          maxDistance: dist,
          progress: _expandAnimation,
          offset: offset + widget.childrenOffset,
          child: Row(
            children: [
              if (_open && _isLabel)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Text(
                    widget.children[i].label,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              FloatingActionButton.small(
                heroTag: widget.children[i].label,
                onPressed: () {
                  toggle();
                  widget.children[i].onPressed();
                },
                child: widget.children[i].icon,
              ),
            ],
          ),
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    final duration = widget.duration;
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: duration,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: duration,
          child: FloatingActionButton(
            heroTag: null,
            foregroundColor: widget.foregroundColor,
            backgroundColor: widget.backgroundColor,
            onPressed: toggle,
            child: AnimatedRotation(
              duration: duration,
              turns: _open ? -0.5 : 0,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Offset offset;
  final Widget child;
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final pos = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: offset.dx + pos.dx,
          bottom: offset.dy + pos.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(opacity: progress, child: child),
    );
  }
}

import 'package:flutter/material.dart';

enum Slide { left, right }

class BackgroundDismissible extends StatelessWidget {
  final Slide slide;
  final String label;
  final IconData icon;
  final double marginVertical;

  const BackgroundDismissible({
    super.key,
    required this.slide,
    required this.label,
    required this.icon,
    this.marginVertical = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFF4CAF50);
    Alignment alignment = Alignment.centerLeft;
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
    TextAlign textAlign = TextAlign.left;
    if (slide == Slide.left) {
      color = const Color(0xFFF44336);
      alignment = Alignment.centerRight;
      mainAxisAlignment = MainAxisAlignment.end;
      textAlign = TextAlign.right;
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: marginVertical),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFFFFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          children: <Widget>[
            if (slide == Slide.right) const SizedBox(width: 20),
            Icon(icon, color: Colors.white),
            Text(
              ' $label',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: textAlign,
            ),
            if (slide == Slide.left) const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

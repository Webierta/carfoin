import 'dart:async' show Timer;

import 'package:flutter/material.dart';

import '../utils/styles.dart';

class CustomDialog {
  const CustomDialog();

  generateDialog({
    required BuildContext context,
    required String msg,
    Color? color,
  }) {
    Timer? timer;
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        timer = Timer(
          const Duration(seconds: 4),
          () => Navigator.of(context).pop(),
        );
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: color ?? blue900,
                  elevation: 10,
                  textStyle: const TextStyle(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    width: double.infinity,
                    child: Text(msg),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (timer != null && timer!.isActive) {
        timer!.cancel();
      }
    });
  }
}

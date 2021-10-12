import 'package:flutter/material.dart';

abstract class DialogBehavior {
  bool get isShowing;

  void dismiss<T extends Object>([T? result]);

  Future<T?> show<T>(
    BuildContext context, {
    Color? barrierColor,
    bool useSafeArea = true,
    bool barrierDismissible = false,
    Duration transitionDuration = const Duration(milliseconds: 150),
    RouteTransitionsBuilder? transitionBuilder,
    bool useRootNavigator = true,
  });
}

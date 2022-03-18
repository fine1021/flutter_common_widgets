import 'package:flutter/material.dart';

class OverScrollBehavior extends ScrollBehavior {
  final bool showLeading;
  final bool showTrailing;
  final bool showScrollbar;
  final ScrollbarBuilder? scrollbar;

  OverScrollBehavior({
    this.showLeading = false,
    this.showTrailing = false,
    this.showScrollbar = false,
    this.scrollbar,
    AndroidOverscrollIndicator? androidOverscrollIndicator,
  })  : _androidOverscrollIndicator = androidOverscrollIndicator,
        super(androidOverscrollIndicator: androidOverscrollIndicator);

  final AndroidOverscrollIndicator? _androidOverscrollIndicator;

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      Theme.of(context).platform;

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class as well.
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
        return child;
      case Axis.vertical:
        switch (getPlatform(context)) {
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            return Scrollbar(
              controller: details.controller,
              child: child,
            );
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
            return showScrollbar
                ? _buildScrollbar(context, child, details)
                : child;
        }
    }
  }

  Widget _buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    var scrollbar = this.scrollbar;
    if (scrollbar != null) {
      return scrollbar(context, child, details);
    } else {
      return Scrollbar(controller: details.controller, child: child);
    }
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class as well.
    final AndroidOverscrollIndicator indicator = _androidOverscrollIndicator ??
        Theme.of(context).androidOverscrollIndicator ??
        androidOverscrollIndicator;
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
      case TargetPlatform.android:
        switch (indicator) {
          case AndroidOverscrollIndicator.stretch:
            return StretchingOverscrollIndicator(
              axisDirection: details.direction,
              child: child,
            );
          case AndroidOverscrollIndicator.glow:
            continue glow;
        }
      glow:
      case TargetPlatform.fuchsia:
        return GlowingOverscrollIndicator(
          axisDirection: details.direction,
          color: Theme.of(context).colorScheme.secondary,
          child: child,
          showLeading: showLeading,
          showTrailing: showTrailing,
        );
    }
  }
}

typedef ScrollbarBuilder = Widget Function(
  BuildContext context,
  Widget child,
  ScrollableDetails details,
);

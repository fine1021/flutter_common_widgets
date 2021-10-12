import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomTabBar extends TabBar {
  CustomTabBar({
    Key? key,
    required List<Widget> tabs,
    TabController? controller,
    bool isScrollable = false,
    Color? indicatorColor,
    bool automaticIndicatorColorAdjustment = true,
    double indicatorWeight = 2.0,
    EdgeInsetsGeometry indicatorPadding = EdgeInsets.zero,
    Decoration? indicator,
    TabBarIndicatorSize? indicatorSize,
    Color? labelColor,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? labelPadding,
    Color? unselectedLabelColor,
    TextStyle? unselectedLabelStyle,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    MaterialStateProperty<Color?>? overlayColor,
    MouseCursor? mouseCursor,
    bool? enableFeedback,
    ValueChanged<int>? onTap,
    ScrollPhysics? physics,
    this.customHeight,
  }) : super(
          key: key,
          tabs: tabs,
          controller: controller,
          isScrollable: isScrollable,
          indicatorColor: indicatorColor,
          automaticIndicatorColorAdjustment: automaticIndicatorColorAdjustment,
          indicatorWeight: indicatorWeight,
          indicatorPadding: indicatorPadding,
          indicator: indicator,
          indicatorSize: indicatorSize,
          labelColor: labelColor,
          labelStyle: labelStyle,
          labelPadding: labelPadding,
          unselectedLabelColor: unselectedLabelColor,
          unselectedLabelStyle: unselectedLabelStyle,
          dragStartBehavior: dragStartBehavior,
          overlayColor: overlayColor,
          mouseCursor: mouseCursor,
          enableFeedback: enableFeedback,
          onTap: onTap,
          physics: physics,
        );

  final double? customHeight;

  @override
  Size get preferredSize {
    if (customHeight == null) {
      return super.preferredSize;
    } else {
      return Size.fromHeight(customHeight! + indicatorWeight);
    }
  }
}

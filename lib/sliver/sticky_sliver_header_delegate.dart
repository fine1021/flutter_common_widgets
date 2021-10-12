import 'package:flutter/material.dart';

class StickySliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WidgetBuilder builder;
  final double maxHeight;
  final double minHeight;

  StickySliverHeaderDelegate(this.builder, this.maxHeight, this.minHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return builder(context);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

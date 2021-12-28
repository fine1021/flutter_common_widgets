import 'package:flutter/material.dart';

class TrackSliverChildBuilderDelegate extends SliverChildBuilderDelegate {
  TrackSliverChildBuilderDelegate(
    NullableIndexedWidgetBuilder builder, {
    ChildIndexGetter? findChildIndexCallback,
    int? childCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    int semanticIndexOffset = 0,
    this.sliverListLayoutTracer,
  }) : super(builder,
            findChildIndexCallback: findChildIndexCallback,
            childCount: childCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
            semanticIndexOffset: semanticIndexOffset);

  final void Function(int firstIndex, int lastIndex)? sliverListLayoutTracer;

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    super.didFinishLayout(firstIndex, lastIndex);
    sliverListLayoutTracer?.call(firstIndex, lastIndex);
  }
}

class TrackSliverChildListDelegate extends SliverChildListDelegate {
  TrackSliverChildListDelegate(
    List<Widget> children, {
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    int semanticIndexOffset = 0,
    this.sliverListLayoutTracer,
  }) : super(children,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
            semanticIndexOffset: semanticIndexOffset);

  final void Function(int firstIndex, int lastIndex)? sliverListLayoutTracer;

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    super.didFinishLayout(firstIndex, lastIndex);
    sliverListLayoutTracer?.call(firstIndex, lastIndex);
  }
}

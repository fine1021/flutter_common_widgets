import 'package:flutter/material.dart';

class StatefulBuilder2 extends StatefulWidget {
  /// Creates a widget that both has state and delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const StatefulBuilder2({
    Key? key,
    required this.builder,
    this.onDispose,
  })  : assert(builder != null),
        super(key: key);

  /// Called to obtain the child widget.
  ///
  /// This function is called whenever this widget is included in its parent's
  /// build and the old widget (if any) that it synchronizes with has a distinct
  /// object identity. Typically the parent's build method will construct
  /// a new tree of widgets and so a new Builder child will not be [identical]
  /// to the corresponding old one.
  final StatefulWidgetBuilder builder;

  final VoidCallback? onDispose;

  @override
  _StatefulBuilder2State createState() => _StatefulBuilder2State();
}

class _StatefulBuilder2State extends State<StatefulBuilder2> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }
}

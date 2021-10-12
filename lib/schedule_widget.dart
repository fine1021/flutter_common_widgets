import 'package:flutter/material.dart';

class ScheduleWidget<T> extends StatefulWidget {
  final T? viewModel;
  final WidgetBuilder? placeholder;
  final ScheduleWidgetBuilder<T> builder;
  final int scheduleTime;
  final bool Function(T? previous, T? next)? equals;
  final bool respectRouteAnimation;
  final String debugLabel;

  const ScheduleWidget({
    Key? key,
    this.viewModel,
    this.placeholder,
    required this.builder,
    this.scheduleTime = 2,
    this.equals,
    this.respectRouteAnimation = true,
    this.debugLabel = '',
  })  : assert(scheduleTime != null && scheduleTime > 1),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ScheduleWidgetState<T>();
  }
}

class _ScheduleWidgetState<T> extends State<ScheduleWidget<T>> {
  int currentTime = 0;
  bool hasScheduledWidget = false;

  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    scheduleWidgetInNextFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(covariant ScheduleWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 提供自定义比较方法，以此来支持特殊场景需求
    bool equals = widget.equals != null
        ? widget.equals!(oldWidget.viewModel, widget.viewModel)
        : oldWidget.viewModel == widget.viewModel;
    // 此处如果不相等，则需要重新加载界面，也即重新触发布局分帧上屏
    if (!equals) {
      currentTime = 0;
      if (hasScheduledWidget) {
        hasScheduledWidget = false;
        scheduleWidgetInNextFrame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isReadyForBuild() || isAnimationCompleted()) {
      currentTime = widget.scheduleTime;
      hasScheduledWidget = true;
      return widget.builder(context, widget.viewModel);
    } else {
      return widget.placeholder == null
          ? SizedBox.shrink()
          : widget.placeholder!(context);
    }
  }

  bool isAnimationCompleted() {
    if (!widget.respectRouteAnimation) {
      return false;
    }
    if (_route == null || _route!.animation == null) {
      return false;
    }
    var animation = _route!.animation!;

    /// On the first frame of a route's entrance transition, the route is built
    /// [Offstage] using an animation progress of 1.0. The route is invisible and
    /// non-interactive, but each widget has its final size and position.
    if (_route!.offstage) {
      return false;
    }
    return animation.isCompleted;
  }

  bool isReadyForBuild() {
    return currentTime >= widget.scheduleTime;
  }

  void scheduleWidgetInNextFrame() async {
    // await WidgetsBinding.instance.endOfFrame;
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (mounted) {
        if (currentTime < widget.scheduleTime && !isAnimationCompleted()) {
          currentTime++;
          scheduleWidgetInNextFrame();
          WidgetsBinding.instance!.scheduleFrame();
        } else if (!hasScheduledWidget) {
          setState(() {
            hasScheduledWidget = true;
          });
        }
      }
    });
  }
}

typedef ScheduleWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T? viewModel,
);

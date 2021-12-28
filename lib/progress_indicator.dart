import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const int _kIndeterminateLinearDuration = 1800;

// 为了适应产品需求，修改 material/progress_indicator.dart 源码，
// 增加secondaryValue/secondaryColor/secondaryValueColor的参数，添加二级进度绘制
// 增加radius的参数，支持进度条圆角

class CustomLinearProgressIndicator extends ProgressIndicator {
  /// Creates a linear progress indicator.
  ///
  /// {@macro flutter.material.progressIndicator.parameters}
  const CustomLinearProgressIndicator({
    Key? key,
    double? value,
    this.secondaryValue,
    Color? backgroundColor,
    Color? color,
    Animation<Color?>? valueColor,
    this.secondaryColor,
    this.secondaryValueColor,
    this.minHeight,
    this.radius,
    String? semanticsLabel,
    String? semanticsValue,
  })  : assert(minHeight == null || minHeight > 0),
        super(
          key: key,
          value: value,
          backgroundColor: backgroundColor,
          color: color,
          valueColor: valueColor,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        );

  /// {@template flutter.material.LinearProgressIndicator.trackColor}
  /// Color of the track being filled by the linear indicator.
  ///
  /// If [LinearProgressIndicator.backgroundColor] is null then the
  /// ambient [ProgressIndicatorThemeData.linearTrackColor] will be used.
  /// If that is null, then the ambient theme's [ColorScheme.background]
  /// will be used to draw the track.
  /// {@endtemplate}
  @override
  Color? get backgroundColor => super.backgroundColor;

  /// The minimum height of the line used to draw the indicator.
  ///
  /// This defaults to 4dp.
  final double? minHeight;

  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  final double? secondaryValue;

  /// The progress indicator's color.
  ///
  /// This is only used if [secondaryValueColor] is null. If [secondaryColor] is also null,
  /// then it defaults to the current theme's [ColorScheme.primary] by default.
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  final Color? secondaryColor;

  /// The progress indicator's secondary color as an animated value.
  ///
  /// If null, the progress indicator is rendered with [secondaryColor], or if that is
  /// also null then with the current theme's [ColorScheme.primary].
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  final Animation<Color?>? secondaryValueColor;

  final Radius? radius;

  @override
  _LinearProgressIndicatorState createState() =>
      _LinearProgressIndicatorState();

  Color _getValueColor(BuildContext context) =>
      valueColor?.value ??
      color ??
      ProgressIndicatorTheme.of(context).color ??
      Theme.of(context).colorScheme.primary;

  Color _getSecondaryValueColor(BuildContext context) =>
      secondaryValueColor?.value ??
      secondaryColor ??
      ProgressIndicatorTheme.of(context).color ??
      Theme.of(context).colorScheme.primary;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(PercentProperty('value', value,
        showName: false, ifNull: '<indeterminate>'));
  }

  Widget _buildSemanticsWrapper({
    required BuildContext context,
    required Widget child,
  }) {
    String? expandedSemanticsValue = semanticsValue;
    if (value != null) {
      expandedSemanticsValue ??= '${(value! * 100).round()}%';
    }
    return Semantics(
      label: semanticsLabel,
      value: expandedSemanticsValue,
      child: child,
    );
  }
}

class _LinearProgressIndicatorState extends State<CustomLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateLinearDuration),
      vsync: this,
    );
    if (widget.value == null) _controller.repeat();
  }

  @override
  void didUpdateWidget(CustomLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating)
      _controller.repeat();
    else if (widget.value != null && _controller.isAnimating)
      _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIndicator(BuildContext context, double animationValue,
      TextDirection textDirection) {
    final ProgressIndicatorThemeData indicatorTheme =
        ProgressIndicatorTheme.of(context);
    final Color trackColor = widget.backgroundColor ??
        indicatorTheme.linearTrackColor ??
        Theme.of(context).colorScheme.background;
    final double minHeight =
        widget.minHeight ?? indicatorTheme.linearMinHeight ?? 4.0;

    return widget._buildSemanticsWrapper(
      context: context,
      child: Container(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: minHeight,
        ),
        child: CustomPaint(
          painter: _LinearProgressIndicatorPainter(
            backgroundColor: trackColor,
            valueColor: widget._getValueColor(context),
            value: widget.value, // may be null
            animationValue: animationValue, // ignored if widget.value is not null
            textDirection: textDirection,
            secondaryValue: widget.secondaryValue,
            secondaryValueColor: widget._getSecondaryValueColor(context),
            radius: widget.radius,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);

    if (widget.value != null)
      return _buildIndicator(context, _controller.value, textDirection);

    return AnimatedBuilder(
      animation: _controller.view,
      builder: (BuildContext context, Widget? child) {
        return _buildIndicator(context, _controller.value, textDirection);
      },
    );
  }
}

class _LinearProgressIndicatorPainter extends CustomPainter {
  const _LinearProgressIndicatorPainter({
    required this.backgroundColor,
    required this.valueColor,
    this.value,
    required this.animationValue,
    required this.textDirection,
    this.secondaryValue,
    required this.secondaryValueColor,
    this.radius,
  }) : assert(textDirection != null);

  final Color backgroundColor;
  final Color valueColor;
  final double? value;
  final double animationValue;
  final TextDirection textDirection;
  final double? secondaryValue;
  final Color secondaryValueColor;
  final Radius? radius;

  // The indeterminate progress animation displays two lines whose leading (head)
  // and trailing (tail) endpoints are defined by the following four curves.
  static const Curve line1Head = Interval(
    0.0,
    750.0 / _kIndeterminateLinearDuration,
    curve: Cubic(0.2, 0.0, 0.8, 1.0),
  );
  static const Curve line1Tail = Interval(
    333.0 / _kIndeterminateLinearDuration,
    (333.0 + 750.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.4, 0.0, 1.0, 1.0),
  );
  static const Curve line2Head = Interval(
    1000.0 / _kIndeterminateLinearDuration,
    (1000.0 + 567.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.0, 0.0, 0.65, 1.0),
  );
  static const Curve line2Tail = Interval(
    1267.0 / _kIndeterminateLinearDuration,
    (1267.0 + 533.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.10, 0.0, 0.45, 1.0),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = valueColor;

    void drawBar(double x, double width) {
      if (width <= 0.0) return;

      double left;
      switch (textDirection) {
        case TextDirection.rtl:
          left = size.width - width - x;
          break;
        case TextDirection.ltr:
          left = x;
          break;
      }
      if (radius == null) {
        canvas.drawRect(Offset(left, 0.0) & Size(width, size.height), paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Offset(left, 0.0) & Size(width, size.height),
            radius!,
          ),
          paint,
        );
      }
    }

    if (value != null) {
      if (secondaryValue != null) {
        paint.color = secondaryValueColor;
        drawBar(0.0, secondaryValue!.clamp(0.0, 1.0) * size.width);
        paint.color = valueColor;
      }
      drawBar(0.0, value!.clamp(0.0, 1.0) * size.width);
    } else {
      final double x1 = size.width * line1Tail.transform(animationValue);
      final double width1 =
          size.width * line1Head.transform(animationValue) - x1;

      final double x2 = size.width * line2Tail.transform(animationValue);
      final double width2 =
          size.width * line2Head.transform(animationValue) - x2;

      drawBar(x1, width1);
      drawBar(x2, width2);
    }
  }

  @override
  bool shouldRepaint(_LinearProgressIndicatorPainter oldPainter) {
    return oldPainter.backgroundColor != backgroundColor ||
        oldPainter.valueColor != valueColor ||
        oldPainter.value != value ||
        oldPainter.animationValue != animationValue ||
        oldPainter.textDirection != textDirection ||
        oldPainter.secondaryValue != secondaryValue ||
        oldPainter.secondaryValueColor != secondaryValueColor ||
        oldPainter.radius != radius;
  }
}

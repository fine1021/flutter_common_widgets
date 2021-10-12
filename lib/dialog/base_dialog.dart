import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dialog_behavior.dart';

class _DialogWrapper extends StatefulWidget {
  final State<_DialogWrapper> state;

  const _DialogWrapper({Key? key, required this.state}) : super(key: key);

  @override
  State<_DialogWrapper> createState() {
    return state;
  }
}

abstract class BaseDialog extends State<_DialogWrapper> with DialogBehavior {
  /// 当点击返回按钮，是否取消对话框
  final bool cancelable;

  /// 当点击外围，是否取消对话框
  final bool canceledOnTouchOutside;

  /// 对话框内容对齐方式，默认居中对齐
  final Alignment alignment;

  /// 监听对话框消失
  final VoidCallback? onDismissListener;

  /// 监听点击对话框周围消失
  final VoidCallback? onTouchOutsideClosed;

  BaseDialog({
    this.cancelable = true,
    this.canceledOnTouchOutside = true,
    this.alignment = Alignment.center,
    this.onDismissListener,
    this.onTouchOutsideClosed,
  });

  bool _isShowing = false;
  ModalRoute<dynamic>? _route;

  @override
  bool get isShowing => _isShowing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    onDestroyDialog();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: onCreateDialog(context),
      onWillPop: () => Future.value(cancelable),
    );
  }

  Widget onCreateDialog(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: alignment,
        children: [
          if (canceledOnTouchOutside)
            GestureDetector(
              child: ConstrainedBox(constraints: const BoxConstraints.expand()),
              onTap: () {
                dismiss();
                onTouchOutsideClosed?.call();
              },
              behavior: HitTestBehavior.opaque,
            ),
          onCreateContent(context),
        ],
      ),
    );
  }

  Widget onCreateContent(BuildContext context);

  @mustCallSuper
  void onDestroyDialog() {
    _isShowing = false;
    if (onDismissListener != null) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        onDismissListener?.call();
      });
    }
  }

  String? getRouteName() {
    return objectRuntimeType(this, 'BaseDialog');
  }

  @override
  Future<T?> show<T>(
    BuildContext context, {
    Color? barrierColor,
    bool useSafeArea = true,
    bool barrierDismissible = false,
    Duration transitionDuration = const Duration(milliseconds: 150),
    RouteTransitionsBuilder? transitionBuilder,
    bool useRootNavigator = true,
  }) {
    _isShowing = true;
    WidgetBuilder builder = (buildContext) => _DialogWrapper(state: this);
    CapturedThemes themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(
        context,
        rootNavigator: useRootNavigator,
      ).context,
    );
    RoutePageBuilder pageBuilder = (
      BuildContext buildContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      final Widget pageChild = Builder(builder: builder);
      Widget dialog = themes.wrap(pageChild);
      if (useSafeArea) {
        dialog = SafeArea(child: dialog);
      }
      return dialog;
    };
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: pageBuilder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration,
      transitionBuilder: transitionBuilder ?? _buildMaterialDialogTransitions,
      useRootNavigator: useRootNavigator,
      routeSettings: RouteSettings(name: getRouteName()),
    );
  }

  @override
  void dismiss<T extends Object>([T? result]) {
    if (_isShowing) {
      if (_canDismissImmediately()) {
        Navigator.pop(context, result);
      } else {
        _scheduleDismiss(result);
      }
    }
  }

  bool _canDismissImmediately() {
    var route = _route;
    if (route == null) {
      return false;
    }
    return route.isCurrent;
  }

  /// [dismiss]方法调用过早，页面还没展示起来，此时需要等待页面展示完成再操作
  void _scheduleDismiss<T extends Object>([T? result]) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (_isShowing) {
        var route = _route;
        if (route == null) {
          _scheduleDismiss(result);
          return;
        }
        if (route.isCurrent) {
          // 当前Route位于最顶部，此时可以直接移除
          dismiss(result);
        } else if (route.isActive) {
          // 当前Route位于堆栈中，此时需要等待
          _scheduleDismiss(result);
        } else {
          // 能走到这里，说明当前Route已经关闭了，此时需要更改对话框展示的状态
          // isCurrent = false isActive = false isFirst = false
          _isShowing = false;
        }
      }
    });
  }
}

Widget buildBottomInDialogTransitions(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  Animation<Offset> offset = Tween<Offset>(
    begin: Offset(0.0, 1.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeOut,
  ));
  return SlideTransition(
    position: offset,
    child: child,
  );
}

Widget buildScaleInDialogTransitions(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return ScaleTransition(
    scale: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ),
    child: child,
  );
}

Widget _buildMaterialDialogTransitions(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ),
    child: child,
  );
}

library popup;

import 'dart:core';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'triangle_painter.dart';

typedef PopupStateChanged = Function(bool isShow);

class Popup {
  static double arrowHeight = 10.0;
  OverlayEntry _entry;

  /// if false menu is show above of the widget, otherwise menu is show under the widget
  bool _isDown = true;

  /// It's showing or not.
  bool _isShow = false;
  bool get isShow => _isShow;

  final VoidCallback onDismiss;
  final PopupStateChanged stateChanged;
  final BuildContext context;

  final Widget child;
  final Color backgroundColor;
  final BoxDecoration decoration;
  double height, width;

  Popup(
      {
        @required this.context,
        this.onDismiss,
        this.stateChanged,
        this.backgroundColor: const Color(0xff232323),
        this.decoration,
        @required this.child,
        @required this.height,
        @required this.width,
      }
  ) : assert(context != null),
      assert(child != null),
      assert(height != null && width != null);

  void show({Rect rect, GlobalKey widgetKey}) {
    assert(rect != null || widgetKey != null);
    rect = rect ?? _getWidgetGlobalRect(widgetKey);
    Offset offset = _calculateOffset(context, rect);

    _entry = OverlayEntry(builder: (context) {
      return buildPopupMenuLayout(offset, rect);
    });

    Overlay.of(context).insert(_entry);

    _isShow = true;
    if (stateChanged != null) {
      stateChanged(true);
    }
  }

  Rect _getWidgetGlobalRect(GlobalKey key) {
    RenderBox renderBox = key.currentContext.findRenderObject();
    Offset offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
        offset.dx, offset.dy, renderBox.size.width, renderBox.size.height);
  }

  Offset _calculateOffset(BuildContext context, Rect rect) {
    Size screenSize = window.physicalSize / window.devicePixelRatio;
    double dx = rect.left + rect.width / 2.0 - width / 2.0;
    if (dx < 10.0) {
      dx = 10.0;
    }

    if(dx + width > screenSize.width && dx > 10.0) {
      double tempDx = screenSize.width - width - 10;
      if(tempDx > 10) dx = tempDx;
    }

    double dy = rect.top - height;
    if (dy <= MediaQuery.of(context).padding.top + 10) {
      dy = arrowHeight + rect.height + rect.top;
      _isDown = false;
    } else {
      dy -= arrowHeight;
      _isDown = true;
    }

    return Offset(dx, dy);
  }

  LayoutBuilder buildPopupMenuLayout(Offset offset, Rect rect) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Container(
          child: Stack(
            children: <Widget>[
              // triangle arrow
              Positioned(
                left: rect.left + rect.width / 2.0 - 7.5,
                top: _isDown ? offset.dy+1 : offset.dy - arrowHeight-1,
                child: CustomPaint(
                  size: Size(15.0, arrowHeight),
                  painter: TrianglePainter(isDown: _isDown, color: backgroundColor),
                ),
              ),
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    child: child,
                    width: width,
                    height: height,
                    color: decoration != null ? null : backgroundColor,
                    decoration: decoration ?? decoration.copyWith(color: backgroundColor),
                  )
                ),
              ),
            ],
          ),
        ),
        onTap: dismiss,
        onVerticalDragStart: (DragStartDetails details) => dismiss(),
        onHorizontalDragStart: (DragStartDetails details) => dismiss(),
      );
    });
  }

  void dismiss() {
    if (!_isShow) {
      // Remove method should only be called once
      return;
    }

    _entry.remove();
    _isShow = false;
    if (onDismiss != null) {
      onDismiss();
    }

    if (this.stateChanged != null) {
      this.stateChanged(false);
    }
  }
}
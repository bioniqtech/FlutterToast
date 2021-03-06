import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Toast { LENGTH_SHORT, LENGTH_LONG }

enum ToastGravity {
  TOP,
  BOTTOM,
  CENTER,
  TOP_LEFT,
  TOP_RIGHT,
  BOTTOM_LEFT,
  BOTTOM_RIGHT,
  CENTER_LEFT,
  CENTER_RIGHT,
  SNACKBAR
}

enum TransitionType {
  Fade,
  Slide,
}

class Fluttertoast {
  static const MethodChannel _channel = const MethodChannel('PonnamKarthik/fluttertoast');

  static Future<bool> cancel() async {
    bool res = await _channel.invokeMethod("cancel");
    return res;
  }

  static Future<bool> showToast({
    @required String msg,
    Toast toastLength,
    int timeInSecForIosWeb = 1,
    double fontSize,
    ToastGravity gravity,
    Color backgroundColor,
    Color textColor,
    bool webShowClose = false,
    webBgColor: "linear-gradient(to right, #00b09b, #96c93d)",
    webPosition: "right",
    // Function(bool) didTap,
  }) async {
    // this.didTap = didTap;
    String toast = "short";
    if (toastLength == Toast.LENGTH_LONG) {
      toast = "long";
    }

    String gravityToast = "bottom";
    if (gravity == ToastGravity.TOP) {
      gravityToast = "top";
    } else if (gravity == ToastGravity.CENTER) {
      gravityToast = "center";
    } else {
      gravityToast = "bottom";
    }

    if (backgroundColor == null && defaultTargetPlatform == TargetPlatform.iOS) {
      backgroundColor = Colors.black;
    }
    if (textColor == null && defaultTargetPlatform == TargetPlatform.iOS) {
      textColor = Colors.white;
    }
    final Map<String, dynamic> params = <String, dynamic>{
      'msg': msg,
      'length': toast,
      'time': timeInSecForIosWeb,
      'gravity': gravityToast,
      'bgcolor': backgroundColor != null ? backgroundColor.value : null,
      'textcolor': textColor != null ? textColor.value : null,
      'fontSize': fontSize,
      'webShowClose': webShowClose,
      'webBgColor': webBgColor,
      'webPosition': webPosition
    };

    bool res = await _channel.invokeMethod('showToast', params);
    return res;
  }
}

typedef PositionedToastBuilder = Widget Function(BuildContext context, Widget child);

class FToast {
  BuildContext context;

  static final FToast _instance = FToast._internal();

  factory FToast() {
    return _instance;
  }

  init(BuildContext context) {
    _instance.context = context;
  }

  FToast._internal();

  OverlayEntry _entry;
  List<_ToastEntry> _overlayQueue = List();
  Timer _timer;

  _showOverlay() {
    if (_overlayQueue.length == 0) {
      _entry = null;
      return;
    }
    _ToastEntry _toastEntry = _overlayQueue.removeAt(0);
    _entry = _toastEntry.entry;
    if (context == null) throw ("Error: Context is null, Please call init(context) before showing toast.");
    Overlay.of(context).insert(_entry);

    _timer = Timer(_toastEntry.duration, () {
      Future.delayed(Duration(milliseconds: 360), () {
        removeCustomToast();
      });
    });
  }

  removeCustomToast() {
    _timer?.cancel();
    _timer = null;
    if (_entry != null) _entry.remove();
    _showOverlay();
  }

  removeQueuedCustomToasts() {
    _timer?.cancel();
    _timer = null;
    _overlayQueue.clear();
    if (_entry != null) _entry.remove();
    _entry = null;
  }

  void showToast({
    @required Widget child,
    PositionedToastBuilder positionedToastBuilder,
    TransitionType transitionType = TransitionType.Fade,
    Duration toastDuration,
    ToastGravity gravity,
  }) {
    Widget newChild = _ToastStateFul(
      child: child,
      duration: toastDuration ?? Duration(seconds: 2),
      transitionType: transitionType,
    );
    OverlayEntry newEntry = OverlayEntry(builder: (context) {
      if (positionedToastBuilder != null) return positionedToastBuilder(context, newChild);
      return _getPostionWidgetBasedOnGravity(newChild, gravity);
    });
    _overlayQueue.add(_ToastEntry(entry: newEntry, duration: toastDuration ?? Duration(seconds: 2)));
    if (_timer == null) _showOverlay();
  }

  _getPostionWidgetBasedOnGravity(Widget child, ToastGravity gravity) {
    switch (gravity) {
      case ToastGravity.TOP:
        return Positioned(top: 100.0, left: 24.0, right: 24.0, child: child);
        break;
      case ToastGravity.TOP_LEFT:
        return Positioned(top: 100.0, left: 24.0, child: child);
        break;
      case ToastGravity.TOP_RIGHT:
        return Positioned(top: 100.0, right: 24.0, child: child);
        break;
      case ToastGravity.CENTER:
        return Positioned(top: 50.0, bottom: 50.0, left: 24.0, right: 24.0, child: child);
        break;
      case ToastGravity.CENTER_LEFT:
        return Positioned(top: 50.0, bottom: 50.0, left: 24.0, child: child);
        break;
      case ToastGravity.CENTER_RIGHT:
        return Positioned(top: 50.0, bottom: 50.0, right: 24.0, child: child);
        break;
      case ToastGravity.BOTTOM_LEFT:
        return Positioned(bottom: 50.0, left: 24.0, child: child);
        break;
      case ToastGravity.BOTTOM_RIGHT:
        return Positioned(bottom: 50.0, right: 24.0, child: child);
        break;
      case ToastGravity.SNACKBAR:
        return Positioned(bottom: MediaQuery.of(context).viewInsets.bottom, left: 0, right: 0, child: child);
        break;
      case ToastGravity.BOTTOM:
      default:
        return Positioned(bottom: 50.0, left: 24.0, right: 24.0, child: child);
    }
  }
}

class _ToastEntry {
  final OverlayEntry entry;
  final Duration duration;

  _ToastEntry({this.entry, this.duration});
}

class _ToastStateFul extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final TransitionType transitionType;

  _ToastStateFul({this.child, this.duration, this.transitionType, Key key}) : super(key: key);

  @override
  ToastStateFulState createState() => ToastStateFulState();
}

class ToastStateFulState extends State<_ToastStateFul> with SingleTickerProviderStateMixin {
  showIt() {
    _animationController.forward();
  }

  hideIt() {
    _animationController.reverse();
    _timer?.cancel();
  }

  AnimationController _animationController;
  Animation _fadeAnimation;
  Animation<Offset> _slideAnimation;

  Timer _timer;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    super.initState();

    showIt();
    _timer = Timer(widget.duration, () {
      hideIt();
    });
  }

  @override
  void deactivate() {
    _timer?.cancel();
    _animationController.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.transitionType) {
      case TransitionType.Slide:
        return SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: widget.child,
            ),
          ),
        );
      case TransitionType.Fade:
      default:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: widget.child,
            ),
          ),
        );
    }
  }
}

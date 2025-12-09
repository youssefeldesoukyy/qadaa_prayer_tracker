import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.rightToLeft,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            Offset begin;
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            switch (direction) {
              case SlideDirection.rightToLeft:
                begin = const Offset(1.0, 0.0);
                break;
              case SlideDirection.leftToRight:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.bottomToTop:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.topToBottom:
                begin = const Offset(0.0, -1.0);
                break;
            }

            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

enum SlideDirection {
  rightToLeft,
  leftToRight,
  bottomToTop,
  topToBottom,
}


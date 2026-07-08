import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SmoothPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth curve with a fast start and very gentle deceleration
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
              reverseCurve: Curves.fastOutSlowIn.flipped,
            );
            
            final secondaryCurve = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.fastOutSlowIn,
              reverseCurve: Curves.fastOutSlowIn.flipped,
            );

            final slideIn = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curve);

            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(secondaryCurve);

            return SlideTransition(
              position: slideOut,
              child: SlideTransition(
                position: slideIn,
                // Add a shadow to the entering page to create depth and separation
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(-4, 0),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            );
          },
        );
}


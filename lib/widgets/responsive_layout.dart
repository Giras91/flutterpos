import 'package:flutter/material.dart';

/// ResponsiveLayout provides simple breakpoints and helpers to adapt UIs
/// across narrow (phone), medium (tablet) and wide (desktop) screens.
///
/// Usage:
/// ResponsiveLayout(
///   builder: (context, constraints, info) => ...
/// )
class ResponsiveInfo {
  final double width;
  final double height;
  final bool isPortrait;
  final int columns;

  ResponsiveInfo({
    required this.width,
    required this.height,
    required this.isPortrait,
    required this.columns,
  });
}

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints, ResponsiveInfo) builder;

  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;

        // Simple breakpoint logic - tweak as needed
        int columns;
        if (width < 600) {
          columns = 1; // phone portrait
        } else if (width < 900) {
          columns = 2; // phone landscape / small tablet
        } else if (width < 1200) {
          columns = 3; // tablet
        } else {
          columns = 4; // desktop
        }

        final info = ResponsiveInfo(
          width: width,
          height: height,
          isPortrait: isPortrait,
          columns: columns,
        );

        return builder(context, constraints, info);
      },
    );
  }
}

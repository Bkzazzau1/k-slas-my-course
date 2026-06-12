import 'package:flutter/material.dart';

class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.isTablet,
    required this.left,
    required this.right,
  });

  final bool isTablet;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (!isTablet) {
      return Column(children: [left, const SizedBox(height: 14), right]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

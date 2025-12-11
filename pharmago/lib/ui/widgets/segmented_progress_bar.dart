import 'package:flutter/material.dart';

/// A custom segmented progress bar widget that displays the current step
/// in a multi-step process with clean horizontal segments.
class SegmentedProgressBar extends StatelessWidget {
  /// Total number of steps in the process
  final int totalSteps;

  /// Current active step (1-based index)
  final int currentStep;

  /// Color for active segments
  final Color activeColor;

  /// Color for inactive segments
  final Color inactiveColor;

  const SegmentedProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.activeColor = const Color(0xFF1A5276),
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

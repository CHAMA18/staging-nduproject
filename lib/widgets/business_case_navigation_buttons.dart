import 'package:flutter/material.dart';
import 'package:ndu_project/utils/business_case_navigation.dart';

/// Navigation buttons for Business Case screens
class BusinessCaseNavigationButtons extends StatelessWidget {
  final String currentScreen;
  final EdgeInsets? padding;
  final Future<void> Function()? onNext;
  final Future<void> Function()? onBack;
  final Future<void> Function()? onSkip;
  final String skipLabel;

  const BusinessCaseNavigationButtons({
    super.key,
    required this.currentScreen,
    this.padding,
    this.onNext,
    this.onBack,
    this.onSkip,
    this.skipLabel = 'Skip',
  });

  @override
  Widget build(BuildContext context) {
    final hasPrevious = BusinessCaseNavigation.hasPrevious(currentScreen);
    final hasNext = BusinessCaseNavigation.hasNext(currentScreen);
    final handleBack = onBack == null
        ? () => BusinessCaseNavigation.navigateBack(context, currentScreen)
        : () async => await onBack!();
    final handleNext = onNext == null
        ? () => BusinessCaseNavigation.navigateForward(context, currentScreen)
        : () async => await onNext!();
    final hasSkip = onSkip != null;
    final handleSkip = onSkip == null ? null : () async => await onSkip!();

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (hasPrevious)
            _NavigationButton(
              icon: Icons.arrow_back_ios_new,
              label: 'Back',
              onPressed: handleBack,
              isForward: false,
            )
          else
            const SizedBox(width: 120),

          Row(
            children: [
              if (hasSkip)
                _NavigationButton(
                  icon: Icons.skip_next_rounded,
                  label: skipLabel,
                  onPressed: handleSkip!,
                  isForward: true,
                  minWidth: 120,
                ),
              if (hasSkip && hasNext) const SizedBox(width: 12),
              // Forward button
              if (hasNext)
                _NavigationButton(
                  icon: Icons.arrow_forward_ios,
                  label: 'Next',
                  onPressed: handleNext,
                  isForward: true,
                  minWidth: 120,
                )
              else
                const SizedBox(width: 120),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isForward;
  final double? minWidth;

  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isForward,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFC812);
    const primaryText = Color(0xFF1A1D1F);
    const cardBorder = Color(0xFFE4E7EC);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isForward ? accentColor : Colors.white,
        foregroundColor: primaryText,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: minWidth == null ? null : Size(minWidth!, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isForward ? accentColor : cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isForward) ...[
            Icon(icon, size: 18, color: primaryText),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          if (isForward) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: primaryText),
          ],
        ],
      ),
    );
  }
}

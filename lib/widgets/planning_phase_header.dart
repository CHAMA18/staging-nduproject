import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

class PlanningPhaseHeader extends StatelessWidget {
  const PlanningPhaseHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onForward,
    this.showNavigationButtons = true,
    this.showImportButton = true,
    this.showContentButton = true,
    this.onImportPressed,
    this.onContentPressed,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final bool showNavigationButtons;
  final bool showImportButton;
  final bool showContentButton;
  final VoidCallback? onImportPressed;
  final VoidCallback? onContentPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UnifiedPhaseHeader(
            title: title,
            onBackPressed: showNavigationButtons
                ? onBack ?? () => Navigator.maybePop(context)
                : null,
            trailingActions: showNavigationButtons
                ? [
                    _CircleIconButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: onForward,
                    ),
                  ]
                : const <Widget>[],
            showActivityLogAction: true,
          ),
          if (showImportButton || showContentButton) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (showImportButton)
                  _YellowButton(
                    label: 'Import',
                    icon: Icons.upload_outlined,
                    onPressed: onImportPressed ?? () {},
                  ),
                if (showImportButton && showContentButton)
                  const SizedBox(width: 12),
                if (showContentButton)
                  _WhiteButton(
                    label: 'Content',
                    icon: Icons.download_outlined,
                    onPressed: onContentPressed ?? () {},
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}

class _YellowButton extends StatelessWidget {
  const _YellowButton(
      {required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';

/// Card widget for displaying a potential solution with summary information
class SolutionCard extends StatelessWidget {
  const SolutionCard({
    super.key,
    required this.solution,
    required this.onViewDetails,
    required this.onSelectPreferred,
    this.onDelete,
    this.riskCount = 0,
    this.itConsiderationsCount = 0,
    this.infrastructureStatus = 'Not specified',
    this.costBenefitSummary = 'Not calculated',
    this.stakeholderCount = 0,
    this.scopeBrief = '',
    this.isSelected = false,
    this.isSaving = false,
  });

  final PotentialSolution solution;
  final VoidCallback onViewDetails;
  final VoidCallback onSelectPreferred;
  final VoidCallback? onDelete;
  final int riskCount;
  final int itConsiderationsCount;
  final String infrastructureStatus;
  final String costBenefitSummary;
  final int stakeholderCount;
  final String scopeBrief;
  final bool isSelected;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final borderColor = isSelected
        ? const Color(0xFFFFD700).withValues(alpha: 0.9)
        : Colors.grey.shade300;

    return Card(
      elevation: isSelected ? 4 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solution #${solution.number}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete solution',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (solution.title.isNotEmpty)
              Text(
                solution.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 10),
            _buildSummaryRow(Icons.description, 'Scope', scopeBrief.isNotEmpty ? scopeBrief : 'Not specified'),
            _buildSummaryRow(Icons.warning, 'Risks', '$riskCount identified'),
            _buildSummaryRow(Icons.computer, 'IT', '$itConsiderationsCount items'),
            _buildSummaryRow(Icons.construction, 'Infrastructure', infrastructureStatus),
            _buildSummaryRow(Icons.attach_money, 'Cost Benefit', costBenefitSummary),
            _buildSummaryRow(Icons.people, 'Stakeholders', '$stakeholderCount identified'),
            const SizedBox(height: 12),
            if (isMobile) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : onViewDetails,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSelectPreferred,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(isSelected ? 'Selected' : 'Select as Preferred'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSaving ? null : onViewDetails,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : onSelectPreferred,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(isSelected ? 'Selected' : 'Select This'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

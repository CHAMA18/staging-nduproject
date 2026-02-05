import 'package:flutter/material.dart';
import 'package:ndu_project/services/design_phase_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

class DesignPhaseProgressIndicator extends StatelessWidget {
  const DesignPhaseProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;

    if (projectId == null || projectId.isEmpty) {
      return _buildFallbackIndicator();
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: DesignPhaseService.instance.calculateOverallProgress(projectId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Progress error: ${snapshot.error}');
          return _buildFallbackIndicator();
        }

        final data = snapshot.data ?? {};
        final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
        final completed = (data['completed'] as int?) ?? 0;
        final total = (data['total'] as int?) ?? 14;

        return _buildIndicator(progress, completed, total);
      },
    );
  }

  Widget _buildFallbackIndicator() {
    return _buildIndicator(0.0, 0, 14);
  }

  Widget _buildIndicator(double progress, int completed, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Design Phase Completion',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D1F),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$completed of $total sections approved',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

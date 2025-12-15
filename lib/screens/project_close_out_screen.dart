import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ProjectCloseOutScreen extends StatefulWidget {
  const ProjectCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectCloseOutScreen()),
    );
  }

  @override
  State<ProjectCloseOutScreen> createState() => _ProjectCloseOutScreenState();
}

class _ProjectCloseOutScreenState extends State<ProjectCloseOutScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Project Close Out',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            _buildStatusChips(),
            const SizedBox(height: 16),
            _buildHelperChips(),
            const SizedBox(height: 24),
            _buildMainContent(context, isMobile),
            const SizedBox(height: 24),
            _buildBottomCards(context, isMobile),
            const SizedBox(height: 24),
            _buildFooterNavigation(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROJECT CLOSE OUT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Formally close the project and lock in the outcomes',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirm that deliverables, contracts, finances, and knowledge are fully wrapped so the project can be closed with confidence.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatusChip('All obligations met', true),
        _buildStatusChip('Approvals captured', false),
        _buildStatusChip('Finances reconciled', false),
        _buildStatusChip('Knowledge archived', false),
        _buildStatusChip('Closeout checklist', true),
        _buildStatusChip('Approvals & sign-off', false),
        _buildStatusChip('Financial wrap-up', false),
        _buildStatusChip('Archive & access', false),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildHelperChips() {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        _buildHelperItem('Keep this page as the single source of truth for closure'),
        _buildHelperItem('Capture only what is needed to prove completion'),
        _buildHelperItem('Make it easy to re-use this playbook next time'),
      ],
    );
  }

  Widget _buildHelperItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFD1D5DB),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCloseoutSummaryCard(),
              const SizedBox(height: 16),
              _buildCoreChecklistCard(),
              const SizedBox(height: 16),
              _buildApprovalsSignOffCard(),
              const SizedBox(height: 16),
              _buildFinancialReconciliationCard(),
              const SizedBox(height: 16),
              _buildContractsVendorsCard(),
              const SizedBox(height: 16),
              _buildKnowledgeArchivingCard(),
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCloseoutSummaryCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildCoreChecklistCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildApprovalsSignOffCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFinancialReconciliationCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildContractsVendorsCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildKnowledgeArchivingCard()),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCloseoutSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Closeout summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'On track to close',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Capture the one-page view of where the project stands, what remains to close, and the target closure date.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_outlined, 'Target close date:', '15 Jun 2025', const Color(0xFF2563EB)),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.check_circle_outline, 'Closeout completion:', '80% of items done', const Color(0xFF16A34A)),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.flag_outlined, 'Open follow-ups:', '3 items before sign-off', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildCoreChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Core closeout checklist',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Must-have items',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick view of the essential tasks that must be complete before the project is officially closed.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildChecklistItem('All launch deliverables accepted by business owner.', true),
          _buildChecklistItem('Production support owner and runbook confirmed.', true),
          _buildChecklistItem('Final risks and open issues documented.', false),
          _buildChecklistItem('Benefits tracking handoff agreed.', false),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? const Color(0xFF374151) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsSignOffCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Approvals & sign-off',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Who signs what',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'List the people who must sign off, and which artefacts they approve.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildApprovalItem('Business owner approves scope delivered vs agreed.', true),
          _buildApprovalItem('IT/Operations lead confirms readiness and support model.', true),
          _buildApprovalItem('Finance partner confirms spend vs budget.', false),
          _buildApprovalItem('Executive sponsor acknowledges closure.', false),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? const Color(0xFF374151) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialReconciliationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Financial reconciliation snapshot',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Numbers in one place',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Summarize the financial position at closeout, without going into full detail.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildFinancialItem('Planned vs actual spend by major cost bucket.', true),
          _buildFinancialItem('Explanation for any material variances.', false),
          _buildFinancialItem('Outstanding invoices, credits, or accruals to resolve.', false),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricChip('Budget used:', '94%', const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              _buildMetricChip('Variance:', '+6% vs plan', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? const Color(0xFF374151) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsVendorsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Contracts & vendors',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Nothing left hanging',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Confirm that all contract obligations are met and no hidden renewals are left behind.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildContractItem('Final acceptance documents issued to key vendors.', true),
          _buildContractItem('Auto-renewals reviewed and either renewed or cancelled.', false),
          _buildContractItem('Access to vendor portals and sandboxes cleaned up.', false),
        ],
      ),
    );
  }

  Widget _buildContractItem(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? const Color(0xFF374151) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeArchivingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Knowledge archiving',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Easy to find later',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Define where final project artefacts live and how people will find them in 6-12 months.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildKnowledgeItem('Project documentation stored in a single, durable space.', true),
          _buildKnowledgeItem('Runbooks, designs, and key decisions clearly labelled.', false),
          _buildKnowledgeItem('Links to benefits tracking and lessons learned pages.', false),
        ],
      ),
    );
  }

  Widget _buildKnowledgeItem(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? const Color(0xFF374151) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCards(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccessToolsCard(),
              const SizedBox(height: 16),
              _buildFormalClosureCard(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildAccessToolsCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildFormalClosureCard()),
          ],
        );
      },
    );
  }

  Widget _buildAccessToolsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Access & tools at close',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Safe & tidy',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Make sure tools used during the project are either decommissioned or moved into steady-state ownership.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildAccessItem('Temporary project tools shut down or reassigned.', true),
          _buildAccessItem('Admin and elevated access removed for ex-team members.', false),
          _buildAccessItem('Monitoring and alerts owned by the right team.', false),
        ],
      ),
    );
  }

  Widget _buildAccessItem(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? const Color(0xFF374151) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormalClosureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Formal closure statement',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'In one paragraph',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Draft the short statement you will use in steering or leadership forums to confirm the project is closed.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildClosureItem('Summarize outcomes vs original goals in 3-4 bullets.', true),
          _buildClosureItem('Note any remaining risks or follow-on initiatives.', false),
          _buildClosureItem('State who now owns ongoing performance and benefits.', false),
        ],
      ),
    );
  }

  Widget _buildClosureItem(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? const Color(0xFF374151) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back: Demobilize team'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Launch phase · Project close out',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                      label: const Text('Help me draft a closure statement'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                      label: const Text('Finish launch phase'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Use this page as your lightweight audit trail: anyone should be able to see what was delivered, who signed off, and what still needs...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.checklist_outlined, size: 16, color: Colors.white),
                  label: const Text('Review project closeout items'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back: Demobilize team'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Launch phase · Project close out',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                    label: const Text('Help me draft a closure statement'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                    label: const Text('Finish launch phase'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Use this page as your lightweight audit trail: anyone should be able to see what was delivered, who signed off, and what still needs...',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.checklist_outlined, size: 16, color: Colors.white),
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Review project closeout items'),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: Colors.white),
                      ],
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/screens/project_charter_sections.dart';

class CharterGovernanceSection extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterGovernanceSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      // constraints: const BoxConstraints(minHeight: 650), // Removed: Full width section adapts to content height
      decoration: BoxDecoration(
        color:
            const Color(0xFFF8FAFC), // Enterprise Fix: Subtle background tint
        borderRadius: BorderRadius.circular(12),
        // Increased contrast: darker border + subtle shadow
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('GOVERNANCE & CONTROLS', style: kSectionTitleStyle),
          const SizedBox(height: 24),

          // GRID LAYOUT
          // Row 1: Security | Stakeholders
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child:
                      _GovernanceCard(child: CharterSecurityShort(data: data))),
              const SizedBox(width: 24),
              Expanded(
                  child: _GovernanceCard(
                      child: CharterStakeholdersShort(data: data))),
            ],
          ),
          const SizedBox(height: 24),

          // Row 2: Approvals (Full Width)
          CharterApprovals(data: data),
        ],
      ),
    );
  }
}

class _GovernanceCard extends StatelessWidget {
  final Widget child;
  const _GovernanceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      child: child,
    );
  }
}

// --- REFACTORED SHORT COMPONENTS FOR GRID ---

// --- REFACTORED SHORT COMPONENTS FOR GRID ---

class CharterSecurityShort extends StatelessWidget {
  final ProjectDataModel? data;
  const CharterSecurityShort({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();
    final secRoles = data!.frontEndPlanning.securityRoles;
    final isSet = secRoles.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderWithStatus('SECURITY HIGHLIGHTS', isSet),
        const SizedBox(height: 12),
        if (!isSet)
          const Text('Standard organizational security apply.',
              style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontSize: 13)),
        if (isSet)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: secRoles
                .take(3)
                .map((r) => Chip(
                      label: Text(r.name),
                      backgroundColor: Colors.grey.shade100,
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(fontSize: 11),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          )
      ],
    );
  }
}

class CharterStakeholdersShort extends StatelessWidget {
  final ProjectDataModel? data;
  const CharterStakeholdersShort({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    // Quick extract
    final items = <Map<String, String>>[];
    if (data!.charterProjectSponsorName.isNotEmpty) {
      items.add({'name': data!.charterProjectSponsorName, 'role': 'Sponsor'});
    }
    if (data!.charterProjectManagerName.isNotEmpty) {
      items.add({'name': data!.charterProjectManagerName, 'role': 'Manager'});
    }

    final isSet = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderWithStatus('KEY STAKEHOLDERS', isSet),
        const SizedBox(height: 12),
        if (!isSet)
          const Text('No key stakeholders identified.',
              style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontSize: 13)),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(i['name']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(i['role']!,
                        style: TextStyle(
                            fontSize: 10, color: Colors.blue.shade800)),
                  )
                ],
              ),
            )),
      ],
    );
  }
}

class CharterApprovals extends StatelessWidget {
  final ProjectDataModel? data;
  const CharterApprovals({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    // Logic: Sponsor preferred. If no Sponsor, then Owner (Project Manager field).
    // If Owner is also the PM (current user), they can approve.
    String signerName = data?.charterProjectSponsorName ?? '';
    String signerRole = 'Project Sponsor';

    if (signerName.isEmpty) {
      signerName = data?.charterProjectManagerName ?? '';
      signerRole = 'Project Owner';
    }

    if (signerName.isEmpty) {
      signerName = 'Pending Assignment';
    }

    final isApproved = data?.charterApprovalDate != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('APPROVAL AUTHORITY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.black54)),
              if (isApproved)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green.shade800),
                      const SizedBox(width: 4),
                      Text('APPROVED',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Single Signer Row
          Row(
            children: [
              Expanded(
                child: _buildSignatureBlock(
                  context,
                  signerName,
                  signerRole,
                  isApproved && data?.charterApprovalDate != null
                      ? DateFormat('MM/dd/yyyy')
                          .format(data!.charterApprovalDate!)
                      : null,
                  isApproved,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBlock(BuildContext context, String name, String role,
      String? date, bool isApproved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cursive', // Mock signature font style
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
              ),
              if (!isApproved)
                InkWell(
                  onTap: () {
                    // Placeholder for approval action
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Approval logic not yet connected.')));
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('Click to Approve',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(role,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            Text(
              date != null ? 'Date: $date' : 'Pending',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderWithStatus extends StatelessWidget {
  final String title;
  final bool isSet;
  const _HeaderWithStatus(this.title, this.isSet);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const Spacer(),
        if (!isSet)
          const Text('MISSING',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange)),
        if (isSet)
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
      ],
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

enum _SecurityTab { dashboard, roles, permissions, settings, accessLogs }

class SecurityManagementScreen extends StatefulWidget {
  const SecurityManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SecurityManagementScreen()),
    );
  }

  @override
  State<SecurityManagementScreen> createState() => _SecurityManagementScreenState();
}

class _SecurityManagementScreenState extends State<SecurityManagementScreen> {
  _SecurityTab _selectedTab = _SecurityTab.dashboard;

  void _handleTabSelected(_SecurityTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = AppBreakpoints.isMobile(context) ? 20 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Security Management'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'AI Notes',
                          sectionLabel: 'Security Management',
                          noteKey: 'planning_security_management_notes',
                          checkpoint: 'security_management',
                          description: 'Summarize security priorities, access controls, and monitoring needs.',
                        ),
                        const SizedBox(height: 24),
                        _TabStrip(selectedTab: _selectedTab, onSelected: _handleTabSelected),
                        const SizedBox(height: 28),
                        _TabContent(selectedTab: _selectedTab),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Security Management',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        SizedBox(height: 8),
        Text(
          'Control access, monitor activity, and configure security settings',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.selectedTab, required this.onSelected});

  final _SecurityTab selectedTab;
  final ValueChanged<_SecurityTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _TabData(label: 'Dashboard', icon: Icons.dashboard_customize, tab: _SecurityTab.dashboard),
      _TabData(label: 'Roles', icon: Icons.badge_outlined, tab: _SecurityTab.roles),
      _TabData(label: 'Permissions', icon: Icons.lock_open_outlined, tab: _SecurityTab.permissions),
      _TabData(label: 'Settings', icon: Icons.settings_outlined, tab: _SecurityTab.settings),
      _TabData(label: 'Access Logs', icon: Icons.receipt_long_outlined, tab: _SecurityTab.accessLogs),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 12)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              _TabChip(
                data: tabs[i],
                selected: tabs[i].tab == selectedTab,
                onTap: () => onSelected(tabs[i].tab),
              ),
              if (i != tabs.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabData {
  const _TabData({required this.label, required this.icon, required this.tab});

  final String label;
  final IconData icon;
  final _SecurityTab tab;
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.data, required this.selected, required this.onTap});

  final _TabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = selected ? const Color(0xFFFFC044) : Colors.transparent;
    final Color textColor = selected ? const Color(0xFF1A1D1F) : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, color: textColor, size: 18),
              const SizedBox(width: 10),
              Text(
                data.label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.selectedTab});

  final _SecurityTab selectedTab;

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case _SecurityTab.dashboard:
        return const _EmptySecurityState(
          title: 'No security dashboard data yet',
          message: 'Add security inputs to populate monitoring and alert insights.',
          icon: Icons.shield_outlined,
        );
      case _SecurityTab.roles:
        return const _EmptySecurityState(
          title: 'No role data yet',
          message: 'Define security roles to populate access coverage.',
          icon: Icons.badge_outlined,
        );
      case _SecurityTab.permissions:
        return const _EmptySecurityState(
          title: 'No permission data yet',
          message: 'Capture permissions and access scopes to populate this view.',
          icon: Icons.lock_open_outlined,
        );
      case _SecurityTab.settings:
        return const _EmptySecurityState(
          title: 'No security settings yet',
          message: 'Add configuration details to populate security settings.',
          icon: Icons.settings_outlined,
        );
      case _SecurityTab.accessLogs:
        return const _EmptySecurityState(
          title: 'No access logs yet',
          message: 'Log security events to populate access history.',
          icon: Icons.receipt_long_outlined,
        );
    }
  }
}

class _EmptySecurityState extends StatelessWidget {
  const _EmptySecurityState({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            double cardWidth;
            if (maxWidth >= 1080) {
              cardWidth = (maxWidth - 32) / 3;
            } else if (maxWidth >= 720) {
              cardWidth = (maxWidth - 16) / 2;
            } else {
              cardWidth = maxWidth;
            }

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(width: cardWidth, child: const _RoleTiersCard()),
                SizedBox(width: cardWidth, child: const _ResourcePermissionsCard()),
                SizedBox(width: cardWidth, child: const _SecurityStatusCard()),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const _RecentActivityCard(),
      ],
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final TextEditingController _sessionTimeoutController = TextEditingController(text: '30');
  final TextEditingController _minPasswordLengthController = TextEditingController(text: '10');
  bool _requireMfa = true;
  bool _requireUppercase = true;
  bool _requireNumbers = true;
  bool _requireSpecial = true;

  @override
  void dispose() {
    _sessionTimeoutController.dispose();
    _minPasswordLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.settings_outlined, color: Color(0xFFB45309), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Settings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Configure system-wide security options',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            icon: Icons.verified_user_outlined,
            iconBackground: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            title: 'Authentication',
            subtitle: 'Enforce login security and session controls',
            children: [
              _SettingToggleRow(
                title: 'Require Multi-Factor Authentication',
                subtitle: 'Enforce MFA for all users when logging in',
                value: _requireMfa,
                onChanged: (value) => setState(() => _requireMfa = value),
              ),
              _SettingInputRow(
                title: 'Session Timeout (minutes)',
                subtitle: 'How long before an inactive session expires',
                controller: _sessionTimeoutController,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 32),
          _SettingsSection(
            icon: Icons.lock_outline,
            iconBackground: const Color(0xFFF0F9F9),
            iconColor: const Color(0xFF0F766E),
            title: 'Password Policy',
            subtitle: 'Set the minimum required characters for passwords',
            children: [
              _SettingInputRow(
                title: 'Minimum Password Length',
                subtitle: 'Set the minimum required characters for passwords',
                controller: _minPasswordLengthController,
              ),
              _SettingToggleRow(
                title: 'Require Uppercase Characters',
                subtitle: 'Passwords must contain at least one uppercase letter',
                value: _requireUppercase,
                onChanged: (value) => setState(() => _requireUppercase = value),
              ),
              _SettingToggleRow(
                title: 'Require Numbers',
                subtitle: 'Passwords must contain at least one number',
                value: _requireNumbers,
                onChanged: (value) => setState(() => _requireNumbers = value),
              ),
              _SettingToggleRow(
                title: 'Require Special Characters',
                subtitle: 'Passwords must contain at least one special character',
                value: _requireSpecial,
                onChanged: (value) => setState(() => _requireSpecial = value),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB020),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save All Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessLogsView extends StatefulWidget {
  const _AccessLogsView();

  @override
  State<_AccessLogsView> createState() => _AccessLogsViewState();
}

class _AccessLogsViewState extends State<_AccessLogsView> {
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Logs',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'System access and security event history',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 780;
              final searchField = isCompact
                  ? SizedBox(
                      width: double.infinity,
                      child: _LogsSearchField(
                        controller: _searchController,
                        onClear: () => setState(() => _searchController.clear()),
                      ),
                    )
                  : Expanded(
                      child: _LogsSearchField(
                        controller: _searchController,
                        onClear: () => setState(() => _searchController.clear()),
                      ),
                    );
              final statusDropdown = SizedBox(
                width: isCompact ? double.infinity : 150,
                child: _StatusDropdown(
                  value: _statusFilter,
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
              );
              final exportButton = SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2937),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Export'),
                ),
              );
              final searchButton = SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Search'),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 16),
                    searchButton,
                    const SizedBox(height: 16),
                    statusDropdown,
                    const SizedBox(height: 16),
                    exportButton,
                  ],
                );
              }

              return Row(
                children: [
                  searchField,
                  const SizedBox(width: 12),
                  searchButton,
                  const Spacer(),
                  statusDropdown,
                  const SizedBox(width: 12),
                  exportButton,
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: const [
                        _TableHeaderCell(label: 'Time', flex: 2),
                        _TableHeaderCell(label: 'User', flex: 2),
                        _TableHeaderCell(label: 'Action', flex: 2),
                        _TableHeaderCell(label: 'Resource', flex: 2),
                        _TableHeaderCell(label: 'Status', flex: 2),
                        _TableHeaderCell(label: 'IP Address', flex: 2),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 68),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'No access logs available',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'System access history will appear here once recorded',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < children.length; i++) ...[
          if (i != 0) const SizedBox(height: 20),
          children[i],
        ],
      ],
    );
  }
}

class _SettingToggleRow extends StatelessWidget {
  const _SettingToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }
}

class _SettingInputRow extends StatelessWidget {
  const _SettingInputRow({
    required this.title,
    required this.subtitle,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogsSearchField extends StatelessWidget {
  const _LogsSearchField({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search logs.',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                  ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        );
      },
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: value,
            hint: const Text('Status', style: TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
            icon: const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('All statuses')),
              DropdownMenuItem<String?>(value: 'Success', child: Text('Success')),
              DropdownMenuItem<String?>(value: 'Failure', child: Text('Failure')),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _RolesView extends StatelessWidget {
  const _RolesView();

  @override
  Widget build(BuildContext context) {
    const roles = [
      _RoleRowData(
        name: 'Admin',
        tierLabel: 'Tier 1',
        tierVariant: _TierBadgeVariant.primary,
        description: 'Full system access',
        created: '4/9/2025',
      ),
      _RoleRowData(
        name: 'Manager',
        tierLabel: 'Tier 2',
        tierVariant: _TierBadgeVariant.text,
        description: 'Contract approvals and team management',
        created: '4/9/2025',
      ),
      _RoleRowData(
        name: 'Contractor',
        tierLabel: 'Tier 3',
        tierVariant: _TierBadgeVariant.neutral,
        description: 'Basic contract viewing and updates',
        created: '4/9/2025',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_outlined, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Role Management',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Configure user access roles and permissions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Role'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: const [
                        _TableHeaderCell(label: 'Role Name', flex: 2),
                        _TableHeaderCell(label: 'Tier'),
                        _TableHeaderCell(label: 'Description', flex: 3),
                        _TableHeaderCell(label: 'Created'),
                        _TableHeaderCell(label: 'Actions', flex: 2, align: TextAlign.right),
                      ],
                    ),
                  ),
                  for (int i = 0; i < roles.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              roles[i].name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _RoleTierBadge(
                                label: roles[i].tierLabel,
                                variant: roles[i].tierVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              roles[i].description,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              roles[i].created,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 10,
                                children: const [
                                  _TableActionButton(label: 'Edit'),
                                  _TableActionButton(label: 'Permissions'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != roles.length - 1)
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Available system roles',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PermissionsView extends StatefulWidget {
  const _PermissionsView();

  @override
  State<_PermissionsView> createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<_PermissionsView> {
  String? _selectedResource;

  @override
  Widget build(BuildContext context) {
    const permissions = [
      _PermissionRowData(name: 'Create Contract', resource: 'contracts', action: 'create', description: 'Create new contracts'),
      _PermissionRowData(name: 'Read Contract', resource: 'contracts', action: 'read', description: 'View contract details'),
      _PermissionRowData(name: 'Update Contract', resource: 'contracts', action: 'update', description: 'Edit existing contracts'),
      _PermissionRowData(name: 'Delete Contract', resource: 'contracts', action: 'delete', description: 'Remove contracts from the system'),
      _PermissionRowData(name: 'Approve Contract', resource: 'contracts', action: 'approve', description: 'Approve contracts for execution'),
      _PermissionRowData(name: 'Create Bid', resource: 'bids', action: 'create', description: 'Create vendor bids'),
      _PermissionRowData(name: 'Read Bid', resource: 'bids', action: 'read', description: 'View bid details'),
      _PermissionRowData(name: 'Select Bid', resource: 'bids', action: 'select', description: 'Select winning bids'),
      _PermissionRowData(name: 'Access Reports', resource: 'reports', action: 'read', description: 'Access system reports and analytics'),
      _PermissionRowData(name: 'Manage Users', resource: 'users', action: 'manage', description: 'Create and edit user accounts'),
      _PermissionRowData(name: 'Manage Roles', resource: 'roles', action: 'manage', description: 'Create and edit roles'),
      _PermissionRowData(name: 'View Audit Log', resource: 'audit', action: 'read', description: 'Access system audit logs'),
    ];

    final filteredPermissions = _selectedResource == null
        ? permissions
        : permissions.where((permission) => permission.resource == _selectedResource).toList();

    final resourceFilters = <String>{for (final item in permissions) item.resource}.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_open_outlined, color: Color(0xFFB45309), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Permissions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'System permissions for resources and actions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedResource,
                  hint: const Text('Filter by resource', style: TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
                  icon: const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All resources'),
                    ),
                    for (final resource in resourceFilters)
                      DropdownMenuItem<String?>(
                        value: resource,
                        child: Text(resource),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedResource = value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: const [
                        _TableHeaderCell(label: 'Permission Name', flex: 2),
                        _TableHeaderCell(label: 'Resource'),
                        _TableHeaderCell(label: 'Action'),
                        _TableHeaderCell(label: 'Description', flex: 3),
                      ],
                    ),
                  ),
                  if (filteredPermissions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      alignment: Alignment.center,
                      child: const Text('No permissions found for this resource', style: TextStyle(color: Color(0xFF9CA3AF))),
                    )
                  else
                    for (int i = 0; i < filteredPermissions.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                filteredPermissions[i].name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                filteredPermissions[i].resource,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                filteredPermissions[i].action,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                filteredPermissions[i].description,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != filteredPermissions.length - 1)
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                    ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'System permissions',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _RoleRowData {
  const _RoleRowData({
    required this.name,
    required this.tierLabel,
    required this.tierVariant,
    required this.description,
    required this.created,
  });

  final String name;
  final String tierLabel;
  final _TierBadgeVariant tierVariant;
  final String description;
  final String created;
}

enum _TierBadgeVariant { primary, neutral, text }

class _RoleTierBadge extends StatelessWidget {
  const _RoleTierBadge({required this.label, required this.variant});

  final String label;
  final _TierBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case _TierBadgeVariant.primary:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        );
      case _TierBadgeVariant.neutral:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w600)),
        );
      case _TierBadgeVariant.text:
        return Text(label, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, fontWeight: FontWeight.w600));
    }
  }
}

class _PermissionRowData {
  const _PermissionRowData({
    required this.name,
    required this.resource,
    required this.action,
    required this.description,
  });

  final String name;
  final String resource;
  final String action;
  final String description;
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({required this.label, this.flex = 1, this.align = TextAlign.left});

  final String label;
  final int flex;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.2),
      ),
    );
  }
}

class _TableActionButton extends StatelessWidget {
  const _TableActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1F2937),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}

class _RoleTiersCard extends StatelessWidget {
  const _RoleTiersCard();

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      headerIcon: Icons.radio_button_checked_outlined,
      headerTitle: 'Role Tiers',
      headerSubtitle: 'Access level distribution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PieChart(
            slices: [
              _PieSlice(color: Color(0xFF0EA5E9), value: 33, label: 'Tier 1'),
              _PieSlice(color: Color(0xFF22D3EE), value: 33, label: 'Tier 3'),
              _PieSlice(color: Color(0xFFFBBF24), value: 34, label: 'Tier 2'),
            ],
          ),
          SizedBox(height: 18),
          _PieLegend(
            entries: [
              _LegendEntry(label: 'Tier 1', value: '33%', color: Color(0xFF0EA5E9)),
              _LegendEntry(label: 'Tier 3', value: '33%', color: Color(0xFF22D3EE)),
              _LegendEntry(label: 'Tier 2', value: '33%', color: Color(0xFFFBBF24)),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Total Roles: 3',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _ResourcePermissionsCard extends StatelessWidget {
  const _ResourcePermissionsCard();

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      headerIcon: Icons.lock_person_outlined,
      headerTitle: 'Resource Permissions',
      headerSubtitle: 'Permissions by resource type',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PieChart(
            slices: [
              _PieSlice(color: Color(0xFF22D3EE), value: 8, label: 'Users'),
              _PieSlice(color: Color(0xFFFB7185), value: 8, label: 'Reports'),
              _PieSlice(color: Color(0xFFF97316), value: 25, label: 'Bids'),
              _PieSlice(color: Color(0xFF6366F1), value: 8, label: 'Roles'),
              _PieSlice(color: Color(0xFF34D399), value: 8, label: 'Audits'),
            ],
          ),
          SizedBox(height: 18),
          _PieLegend(
            wrap: true,
            entries: [
              _LegendEntry(label: 'Users', value: '8%', color: Color(0xFF22D3EE)),
              _LegendEntry(label: 'Reports', value: '8%', color: Color(0xFFFB7185)),
              _LegendEntry(label: 'Bids', value: '25%', color: Color(0xFFF97316)),
              _LegendEntry(label: 'Roles', value: '8%', color: Color(0xFF6366F1)),
              _LegendEntry(label: 'Audits', value: '8%', color: Color(0xFF34D399)),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Total Permissions: 12',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard();

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      headerIcon: Icons.shield_outlined,
      headerTitle: 'Security Status',
      headerSubtitle: 'Critical security settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const _StatusTile(
            icon: Icons.verified_user_outlined,
            label: 'MFA Enabled',
            value: 'Enabled',
          ),
          const SizedBox(height: 12),
          const _StatusTile(
            icon: Icons.password_outlined,
            label: 'Password Min Length',
            value: '10 chars',
          ),
          const SizedBox(height: 12),
          const _StatusTile(
            icon: Icons.schedule_outlined,
            label: 'Session Timeout',
            value: '30 min',
          ),
          const SizedBox(height: 12),
          const _StatusTile(
            icon: Icons.warning_amber_outlined,
            label: 'Failed Logins (24h)',
            value: '0',
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: const Color(0xFF1A1D1F),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Manage Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
              const SizedBox(height: 4),
              const Text('Active', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      padding: const EdgeInsets.all(26),
      headerIcon: Icons.description_outlined,
      headerTitle: 'Recent Activity',
      headerSubtitle: 'System access and security events',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _DashedBorderBox(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF9FAFB),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.timeline_outlined, color: Color(0xFFD1D5DB), size: 42),
                    SizedBox(height: 12),
                    Text('No activity yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                    SizedBox(height: 4),
                    Text('Security logs will appear here when available', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _LegendEntry(label: 'Success', value: '', color: Color(0xFF10B981), inline: true),
              _LegendEntry(label: 'Failure', value: '', color: Color(0xFFEF4444), inline: true),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                foregroundColor: const Color(0xFF1A1D1F),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('View All Logs'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderBox extends StatelessWidget {
  const _DashedBorderBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final RRect rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    final Path path = Path()..addRRect(rrect);

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      const double dashLength = 8;
      const double gapLength = 6;
      while (distance < metric.length) {
        final double next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.headerIcon,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final IconData headerIcon;
  final String headerTitle;
  final String headerSubtitle;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(headerIcon, size: 18, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headerTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text(
                      headerSubtitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.slices});

  final List<_PieSlice> slices;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _PieChartPainter(slices),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              '100%',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieSlice {
  const _PieSlice({required this.color, required this.value, required this.label});

  final Color color;
  final double value;
  final String label;
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter(this.slices);

  final List<_PieSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double total = slices.fold(0, (sum, slice) => sum + slice.value);
    double startRadian = -math.pi / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (final slice in slices) {
      final double sweepRadian = (slice.value / total) * 2 * math.pi;
      paint.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRadian,
        sweepRadian,
        true,
        paint,
      );
      startRadian += sweepRadian;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PieLegend extends StatelessWidget {
  const _PieLegend({required this.entries, this.wrap = false});

  final List<_LegendEntry> entries;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final children = entries.map((entry) => entry).toList();
    if (wrap) {
      return Wrap(spacing: 16, runSpacing: 8, children: children);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.label, required this.value, required this.color, this.inline = false});

  final String label;
  final String value;
  final Color color;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 8),
          Text(label.toLowerCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }
}

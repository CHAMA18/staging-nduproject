import 'package:flutter/material.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/screens/engineering_design_screen.dart';

class BackendDesignScreen extends StatelessWidget {
  const BackendDesignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Backend Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(title: 'Design Phase'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend Design',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define the backend architecture, database schema, and API endpoints.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  if (isMobile)
                    Column(
                      children: const [
                        _ArchitectureOverviewCard(),
                        SizedBox(height: 16),
                        _DatabaseSchemaCard(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(flex: 2, child: _ArchitectureOverviewCard()),
                        SizedBox(width: 20),
                        Expanded(child: _DatabaseSchemaCard()),
                      ],
                    ),
                  const SizedBox(height: 28),
                  _BottomNavigation(isMobile: isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchitectureOverviewCard extends StatelessWidget {
  const _ArchitectureOverviewCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Architecture Overview',
      subtitle: 'Visual representation of the backend system architecture',
      trailing: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: LightModeColors.lightPrimary,
          foregroundColor: LightModeColors.lightOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Design Document', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _DiagramNode(icon: Icons.person_outline, label: 'User'),
              _DiagramArrow(),
              _DiagramNode(icon: Icons.desktop_windows_outlined, label: 'Web App'),
              _DiagramArrow(),
              _DiagramNode(icon: Icons.router_outlined, label: 'API Gateway'),
              _DiagramArrow(),
              _StackedServiceNode(
                title: 'Auth Service',
                items: const ['Auth Service', 'Payments', 'Notifications'],
              ),
              _DiagramArrow(),
              _DiagramNode(icon: Icons.storage_outlined, label: ''),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatabaseSchemaCard extends StatelessWidget {
  const _DatabaseSchemaCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Database Schema',
      subtitle: 'Define the database structure and entity relationships',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppSemanticColors.border),
            ),
            child: Column(
              children: const [
                _SchemaRow(field: 'id', type: 'UUID PRIMARY KEY'),
                _SchemaRow(field: 'email', type: 'VARCHAR(255) UNIQUE'),
                _SchemaRow(field: 'password_hash', type: 'VARCHAR(255)'),
                _SchemaRow(field: 'created_at', type: 'TIMESTAMP'),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+ 12 more columns',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppSemanticColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.description_outlined, size: 16, color: Color(0xFF6B7280)),
                SizedBox(width: 8),
                Text('backend_schema_v2.sql', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemaRow extends StatelessWidget {
  const _SchemaRow({required this.field, required this.type});

  final String field;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              field,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            type,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DiagramNode extends StatelessWidget {
  const _DiagramNode({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _DiagramArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5F5)),
    );
  }
}

class _StackedServiceNode extends StatelessWidget {
  const _StackedServiceNode({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: i == 0 ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppSemanticColors.border),
              ),
              child: Text(
                items[i],
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            if (i != items.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final backButton = OutlinedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UiUxDesignScreen()));
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppSemanticColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Back: UI/UX Design', style: TextStyle(fontWeight: FontWeight.w600)),
    );

    final nextButton = ElevatedButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EngineeringDesignScreen()));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: LightModeColors.lightPrimary,
        foregroundColor: LightModeColors.lightOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Next: Engineering', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          backButton,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: nextButton),
        ],
      );
    }

    return Row(
      children: [
        backButton,
        const Spacer(),
        nextButton,
      ],
    );
  }
}

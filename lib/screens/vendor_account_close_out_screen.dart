import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/contract_close_out_screen.dart';
import 'package:ndu_project/screens/summarize_account_risks_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class VendorAccountCloseOutScreen extends StatefulWidget {
  const VendorAccountCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorAccountCloseOutScreen()),
    );
  }

  @override
  State<VendorAccountCloseOutScreen> createState() =>
      _VendorAccountCloseOutScreenState();
}

class _VendorAccountCloseOutScreenState
    extends State<VendorAccountCloseOutScreen> {
  List<LaunchVendorItem> _vendors = [];
  List<LaunchAccessItem> _accessItems = [];
  List<LaunchFollowUpItem> _obligations = [];
  List<LaunchFollowUpItem> _closureChecklist = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _hasLoaded = false;
  bool _suspendSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String? get _projectId => ProjectDataHelper.getData(context).projectId;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 980;

    return ResponsiveScaffold(
      activeItemLabel: 'Vendor Account Close Out',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: isMobile ? 16 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMetricsRow(),
            const SizedBox(height: 20),
            _buildVendorsPanel(),
            const SizedBox(height: 16),
            _buildAccessPanel(),
            const SizedBox(height: 16),
            _buildObligationsPanel(),
            const SizedBox(height: 16),
            _buildClosureChecklistPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Contract Close Out',
              nextLabel: 'Next: Project Summary',
              onBack: () => ContractCloseOutScreen.open(context),
              onNext: () => SummarizeAccountRisksScreen.open(context),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ExecutionPageHeader(
      badge: 'LAUNCH PHASE',
      title: 'Vendor Account Close Out',
      description:
          'Close vendor accounts, revoke access, settle obligations, and confirm all outstanding items.',
      trailing: ExecutionActionBar(
        actions: [
          ExecutionActionItem(
            label: 'Import Vendors',
            icon: Icons.download_outlined,
            tone: ExecutionActionTone.secondary,
            onPressed: _importVendors,
          ),
          ExecutionActionItem(
            label: _isGenerating ? 'Generating…' : 'AI Assist',
            icon: Icons.auto_awesome_outlined,
            tone: ExecutionActionTone.ai,
            isLoading: _isGenerating,
            onPressed: _isGenerating ? null : _populateFromAi,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final active = _vendors.where((v) => v.accountStatus == 'Active').length;
    final closed = _vendors.where((v) => v.accountStatus == 'Closed').length;
    final pendingAccess =
        _accessItems.where((a) => a.status != 'Revoked').length;
    final openObligations =
        _obligations.where((o) => o.status != 'Complete').length;

    return ExecutionMetricsGrid(
      metrics: [
        ExecutionMetricData(
          label: 'Vendors',
          value: '${_vendors.length}',
          icon: Icons.business_outlined,
          emphasisColor: const Color(0xFF2563EB),
          helper: '$active active, $closed closed',
        ),
        ExecutionMetricData(
          label: 'Access Items',
          value: '$pendingAccess',
          icon: Icons.vpn_key_outlined,
          emphasisColor: pendingAccess > 0
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981),
          helper: 'pending revocation',
        ),
        ExecutionMetricData(
          label: 'Open Obligations',
          value: '$openObligations',
          icon: Icons.pending_actions_outlined,
          emphasisColor: openObligations > 0
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
        ),
        ExecutionMetricData(
          label: 'Closure Tasks',
          value:
              '${_closureChecklist.where((c) => c.status == 'Complete').length} / ${_closureChecklist.length}',
          icon: Icons.checklist_outlined,
          emphasisColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildVendorsPanel() {
    return LaunchDataTable(
      title: 'Vendor Close-Out Table',
      subtitle: 'Track each vendor\'s account status and outstanding items.',
      columns: const [
        'Vendor',
        'Contract Ref',
        'Status',
        'Outstanding',
        'Notes'
      ],
      rowCount: _vendors.length,
      onAdd: () {
        setState(() => _vendors.add(LaunchVendorItem()));
        _save();
      },
      importLabel: 'Import Vendors',
      onImport: _importVendors,
      emptyMessage:
          'No vendors yet. Import vendors from execution or add manually.',
      cellBuilder: (context, i) {
        final v = _vendors[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed = await launchConfirmDelete(context,
                itemName: 'vendor ${v.vendorName}');
            if (!confirmed || !mounted) return;
            setState(() => _vendors.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: v.vendorName,
              hint: 'Vendor',
              bold: true,
              expand: true,
              onChanged: (s) {
                _vendors[i] = v.copyWith(vendorName: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: v.contractRef,
              hint: 'Ref',
              width: 120,
              onChanged: (s) {
                _vendors[i] = v.copyWith(contractRef: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: v.accountStatus,
              items: const ['Active', 'Closing', 'Closed'],
              width: 110,
              onChanged: (s) {
                if (s == null) return;
                _vendors[i] = v.copyWith(accountStatus: s);
                _save();
                setState(() {});
              },
            ),
            LaunchEditableCell(
              value: v.outstandingItems,
              hint: 'Items',
              width: 120,
              onChanged: (s) {
                _vendors[i] = v.copyWith(outstandingItems: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: v.notes,
              hint: 'Notes',
              expand: true,
              onChanged: (s) {
                _vendors[i] = v.copyWith(notes: s);
                _save();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessPanel() {
    return LaunchDataTable(
      title: 'Access Revocation',
      subtitle:
          'Track system/tool access that needs to be revoked for each vendor.',
      columns: const [
        'System',
        'Vendor',
        'Access Level',
        'Revoked Date',
        'Status',
      ],
      rowCount: _accessItems.length,
      onAdd: () {
        setState(() => _accessItems.add(LaunchAccessItem()));
        _save();
      },
      emptyMessage:
          'No access items. Track vendor access that needs revocation.',
      cellBuilder: (context, i) {
        final a = _accessItems[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed = await launchConfirmDelete(context,
                itemName: 'access item ${a.system}');
            if (!confirmed || !mounted) return;
            setState(() => _accessItems.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: a.system,
              hint: 'System',
              bold: true,
              expand: true,
              onChanged: (s) {
                _accessItems[i] = a.copyWith(system: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: a.vendor,
              hint: 'Vendor',
              expand: true,
              onChanged: (s) {
                _accessItems[i] = a.copyWith(vendor: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: a.accessLevel,
              hint: 'Level',
              width: 120,
              onChanged: (s) {
                _accessItems[i] = a.copyWith(accessLevel: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: a.revokedDate,
              hint: 'Date',
              width: 120,
              onChanged: (s) {
                _accessItems[i] = a.copyWith(revokedDate: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: a.status,
              items: const ['Pending', 'Revoked', 'Confirmed'],
              width: 120,
              onChanged: (s) {
                if (s == null) return;
                _accessItems[i] = a.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildObligationsPanel() {
    return LaunchDataTable(
      title: 'Outstanding Obligations',
      subtitle:
          'Pending payments, deliverables, SLAs, or warranties requiring resolution.',
      columns: const ['Obligation', 'Details', 'Owner', 'Status'],
      rowCount: _obligations.length,
      onAdd: () {
        setState(() => _obligations.add(LaunchFollowUpItem()));
        _save();
      },
      emptyMessage: 'No obligations. Track pending vendor obligations.',
      cellBuilder: (context, i) {
        final o = _obligations[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed = await launchConfirmDelete(context,
                itemName: 'obligation ${o.title}');
            if (!confirmed || !mounted) return;
            setState(() => _obligations.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: o.title,
              hint: 'Title',
              bold: true,
              expand: true,
              onChanged: (s) {
                _obligations[i] = o.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: o.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _obligations[i] = o.copyWith(details: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: o.owner,
              hint: 'Owner',
              width: 120,
              onChanged: (s) {
                _obligations[i] = o.copyWith(owner: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: o.status,
              items: const ['Open', 'In Progress', 'Complete'],
              width: 120,
              onChanged: (s) {
                if (s == null) return;
                _obligations[i] = o.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildClosureChecklistPanel() {
    return LaunchDataTable(
      title: 'Account Closure Checklist',
      subtitle:
          'Standardized steps to verify each vendor account is fully closed.',
      columns: const ['Task', 'Details', 'Owner', 'Status'],
      rowCount: _closureChecklist.length,
      onAdd: () {
        setState(() => _closureChecklist.add(LaunchFollowUpItem()));
        _save();
      },
      emptyMessage: 'No checklist items. Add closure verification tasks.',
      cellBuilder: (context, i) {
        final c = _closureChecklist[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed = await launchConfirmDelete(context,
                itemName: 'checklist task ${c.title}');
            if (!confirmed || !mounted) return;
            setState(() => _closureChecklist.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: c.title,
              hint: 'Task',
              bold: true,
              expand: true,
              onChanged: (s) {
                _closureChecklist[i] = c.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: c.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _closureChecklist[i] = c.copyWith(details: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: c.owner,
              hint: 'Owner',
              width: 120,
              onChanged: (s) {
                _closureChecklist[i] = c.copyWith(owner: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: c.status,
              items: const ['Pending', 'In Progress', 'Complete'],
              width: 120,
              onChanged: (s) {
                if (s == null) return;
                _closureChecklist[i] = c.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _importVendors() async {
    if (_projectId == null) return;
    final imported = await LaunchPhaseService.loadExecutionVendors(_projectId!);
    if (imported.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No vendors found to import.')));
      }
      return;
    }
    setState(() {
      final existing = _vendors.map((v) => v.vendorName).toSet();
      for (final v in imported) {
        if (!existing.contains(v.vendorName)) _vendors.add(v);
      }
    });
    _save();
  }

  void _save() {
    if (_suspendSave || !_hasLoaded) return;
    Future.microtask(() {
      if (mounted) _persistData();
    });
  }

  Future<void> _loadData() async {
    if (_hasLoaded || _projectId == null) return;
    _suspendSave = true;
    try {
      final r = await LaunchPhaseService.loadVendorAccountCloseOut(
          projectId: _projectId!);
      if (!mounted) return;
      setState(() {
        _vendors = r.vendors;
        _accessItems = r.accessItems;
        _obligations = r.obligations;
        _closureChecklist = r.closureChecklist;
        _isLoading = false;
        _hasLoaded = true;
      });
      if (_vendors.isEmpty) {
        await _importVendors();
      }
      if (_vendors.isEmpty &&
          _accessItems.isEmpty &&
          _obligations.isEmpty &&
          _closureChecklist.isEmpty) {
        await _populateFromAi();
      }
    } catch (e) {
      debugPrint('Vendor close-out load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _suspendSave = false;
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveVendorAccountCloseOut(
          projectId: _projectId!,
          vendors: _vendors,
          accessItems: _accessItems,
          obligations: _obligations,
          closureChecklist: _closureChecklist);
    } catch (e) {
      debugPrint('Vendor close-out save error: $e');
    }
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;
    final data = ProjectDataHelper.getData(context);
    var ctx = ProjectDataHelper.buildExecutivePlanContext(data,
        sectionLabel: 'Vendor Account Close Out');
    if (ctx.trim().isEmpty) {
      ctx = ProjectDataHelper.buildProjectContextScan(data);
    }
    if (ctx.trim().isEmpty) return;
    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> gen = {};
    try {
      gen = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: ctx,
        sections: const {
          'vendors':
              'Vendors with name, contract reference, outstanding items, status',
          'access_items':
              'System access items with system, vendor, access level, status',
          'obligations':
              'Outstanding obligations: payments, deliverables, SLAs',
          'closure_checklist': 'Closure verification tasks with status',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Vendor AI error: $e');
    }
    if (!mounted) return;
    final hasData = _vendors.isNotEmpty ||
        _accessItems.isNotEmpty ||
        _obligations.isNotEmpty ||
        _closureChecklist.isNotEmpty;
    if (hasData) {
      setState(() => _isGenerating = false);
      return;
    }
    setState(() {
      _vendors = (gen['vendors'] ?? [])
          .map((m) => LaunchVendorItem(
              vendorName: _s(m['title']),
              outstandingItems: _s(m['details']),
              accountStatus: _ns(m['status'], 'Active')))
          .where((i) => i.vendorName.isNotEmpty)
          .toList();
      _accessItems = (gen['access_items'] ?? [])
          .map((m) => LaunchAccessItem(
              system: _s(m['title']),
              vendor: _s(m['details']),
              status: _ns(m['status'], 'Pending')))
          .where((i) => i.system.isNotEmpty)
          .toList();
      _obligations = (gen['obligations'] ?? [])
          .map((m) => LaunchFollowUpItem(
              title: _s(m['title']),
              details: _s(m['details']),
              status: _ns(m['status'], 'Open')))
          .where((i) => i.title.isNotEmpty)
          .toList();
      _closureChecklist = (gen['closure_checklist'] ?? [])
          .map((m) => LaunchFollowUpItem(
              title: _s(m['title']),
              details: _s(m['details']),
              status: _ns(m['status'], 'Pending')))
          .where((i) => i.title.isNotEmpty)
          .toList();
      _isGenerating = false;
    });
    await _persistData();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();
  String _ns(dynamic v, String fb) => _s(v).isEmpty ? fb : _s(v);
}

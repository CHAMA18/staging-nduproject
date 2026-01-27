import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/front_end_planning_security.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';

/// Front End Planning – Procurement screen
/// Recreates the provided procurement workspace mock with strategies and vendor table.
class FrontEndPlanningProcurementScreen extends StatefulWidget {
  const FrontEndPlanningProcurementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningProcurementScreen()),
    );
  }

  @override
  State<FrontEndPlanningProcurementScreen> createState() =>
      _FrontEndPlanningProcurementScreenState();
}

class _FrontEndPlanningProcurementScreenState
    extends State<FrontEndPlanningProcurementScreen> {
  final TextEditingController _notes = TextEditingController();

  bool _approvedOnly = false;
  bool _preferredOnly = false;
  bool _listView = true;
  String _categoryFilter = 'All Categories';
  final Set<int> _expandedStrategies = {};

  _ProcurementTab _selectedTab = _ProcurementTab.procurementDashboard;
  int _selectedTrackableIndex = 0;
  late final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  final List<_ProcurementItem> _items = [];

  final List<_TrackableItem> _trackableItems = [];

  final List<_ProcurementStrategy> _strategies = [];

  final List<_VendorRow> _vendors = [];
  final Set<String> _selectedVendorIds = {};
  int _vendorIdCounter = 0;

  final List<_VendorHealthMetric> _vendorHealthMetrics = [];

  final List<_VendorOnboardingTask> _vendorOnboardingTasks = [];

  final List<_VendorRiskItem> _vendorRiskItems = [];

  final List<_RfqItem> _rfqs = [];

  final List<_RfqCriterion> _rfqCriteria = [];

  final List<_PurchaseOrder> _purchaseOrders = [];

  final List<_TrackingAlert> _trackingAlerts = [];

  final List<_CarrierPerformance> _carrierPerformance = [];

  final List<_ReportKpi> _reportKpis = [];

  final List<_SpendBreakdown> _spendBreakdown = [];

  final List<_LeadTimeMetric> _leadTimeMetrics = [];

  final List<_SavingsOpportunity> _savingsOpportunities = [];

  final List<_ComplianceMetric> _complianceMetrics = [];

  late final OpenAiServiceSecure _openAi;
  bool _isGeneratingData = false;

  String _newVendorId() =>
      'vendor_${DateTime.now().microsecondsSinceEpoch}_${_vendorIdCounter++}';

  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = ProjectDataHelper.getData(context);
      _notes.text = data.frontEndPlanning.procurement;

      // Initialize all sections with fallback data immediately so UI shows content
      if (mounted) {
        setState(() {
          // Generate strategies and reports immediately (synchronous)
          if (_strategies.isEmpty) {
            _generateStrategies();
          }
          if (_reportKpis.isEmpty && _spendBreakdown.isEmpty) {
            _generateReportsData();
          }
        });
      }

      if (mounted) setState(() {});
      // Generate all data (will show fallback first, then enhance with AI)
      await _generateProcurementDataIfNeeded();
    });
  }

  Future<void> _regenerateAllProcurement() async {
    // Clear all data and regenerate
    setState(() {
      _items.clear();
      _vendors.clear();
      _rfqs.clear();
      _purchaseOrders.clear();
      _trackableItems.clear();
      _strategies.clear();
      _reportKpis.clear();
      _spendBreakdown.clear();
    });
    await _generateProcurementDataIfNeeded();
  }

  Future<void> _generateProcurementDataIfNeeded() async {
    if (_isGeneratingData) return;

    final needsItems = _items.isEmpty;
    final needsStrategies = _strategies.isEmpty;
    final needsVendors = _vendors.isEmpty;
    final needsRfqs = _rfqs.isEmpty;
    final needsPurchaseOrders = _purchaseOrders.isEmpty;
    final needsTrackableItems = _trackableItems.isEmpty;
    final needsReports = _reportKpis.isEmpty && _spendBreakdown.isEmpty;

    if (!needsItems &&
        !needsStrategies &&
        !needsVendors &&
        !needsRfqs &&
        !needsPurchaseOrders &&
        !needsTrackableItems &&
        !needsReports) {
      return;
    }

    // Set fallback data immediately so all sections display content
    if (mounted) {
      setState(() {
        if (needsStrategies) {
          _generateStrategies();
        }
        if (needsReports) {
          _generateReportsData();
        }
      });
    }

    setState(() => _isGeneratingData = true);

    try {
      final data = ProjectDataHelper.getData(context);
      final projectName =
          data.projectName.trim().isEmpty ? 'Project' : data.projectName.trim();
      final solutionTitle = data.solutionTitle.trim().isEmpty
          ? 'Solution'
          : data.solutionTitle.trim();
      final notes = data.frontEndPlanning.procurement.trim();

      // Generate all sections (they will show fallback data immediately, then enhance with AI)
      if (needsItems) {
        await _generateItems(projectName, solutionTitle, notes);
        // Update strategies after items are generated to get accurate counts
        _generateStrategies();
      }
      if (needsVendors) {
        await _generateVendors(projectName, solutionTitle, notes);
      }
      if (needsRfqs) {
        await _generateRfqs(projectName, solutionTitle, notes);
      }
      if (needsPurchaseOrders) {
        await _generatePurchaseOrders(projectName, solutionTitle, notes);
      }
      if (needsTrackableItems) {
        await _generateTrackableItems(projectName, solutionTitle, notes);
      }
    } catch (e) {
      debugPrint('Error generating procurement data: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingData = false);
      }
    }
  }

  Future<void> _generateItems(
      String projectName, String solutionTitle, String notes) async {
    // Always generate fallback items immediately to show content
    final now = DateTime.now();
    final categories = [
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Services'
    ];

    // Set fallback items immediately so UI shows content
    if (mounted) {
      setState(() {
        _items.clear();
        for (int i = 0; i < categories.length; i++) {
          _items.add(_ProcurementItem(
            name: '${categories[i]} Procurement',
            description: 'Procurement item for ${categories[i]}',
            category: categories[i],
            status: _ProcurementItemStatus.planning,
            priority: _ProcurementPriority.medium,
            budget: 50000 + (i * 10000),
            estimatedDelivery: _formatStoreDate(now.add(Duration(days: 90))),
            progress: 0.0,
          ));
        }
      });
    }

    // Then try to enhance with AI-generated data
    try {
      final items = <_ProcurementItem>[];

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        try {
          final result = await _openAi.generateProcurementItemSuggestion(
            projectName: projectName,
            solutionTitle: solutionTitle,
            category: category,
            contextNotes: notes,
          );

          final deliveryDays = (result['estimatedDeliveryDays'] as int?) ?? 90;
          final deliveryDate = DateTime.now().add(Duration(days: deliveryDays));
          final deliveryDateStr = _formatStoreDate(deliveryDate);

          _ProcurementPriority priority;
          final priorityStr = (result['priority'] ?? 'medium').toString();
          switch (priorityStr.toLowerCase()) {
            case 'critical':
              priority = _ProcurementPriority.critical;
              break;
            case 'high':
              priority = _ProcurementPriority.high;
              break;
            case 'low':
              priority = _ProcurementPriority.low;
              break;
            default:
              priority = _ProcurementPriority.medium;
          }

          _ProcurementItemStatus status;
          switch (i % 5) {
            case 0:
              status = _ProcurementItemStatus.planning;
              break;
            case 1:
              status = _ProcurementItemStatus.rfqReview;
              break;
            case 2:
              status = _ProcurementItemStatus.vendorSelection;
              break;
            case 3:
              status = _ProcurementItemStatus.ordered;
              break;
            default:
              status = _ProcurementItemStatus.delivered;
          }

          final progress = [0.0, 0.25, 0.5, 0.75, 1.0][i % 5];

          items.add(_ProcurementItem(
            name: (result['name'] ?? '$category Procurement').toString(),
            description: (result['description'] ??
                    'Procurement item for $category category')
                .toString(),
            category: category,
            status: status,
            priority: priority,
            budget: (result['budget'] as int?) ?? (50000 + (i * 10000)),
            estimatedDelivery: deliveryDateStr,
            progress: progress,
          ));
        } catch (e) {
          debugPrint('Error generating item for $category: $e');
          // Use fallback item
          items.add(_ProcurementItem(
            name: '$category Procurement',
            description: 'Procurement item for $category category',
            category: category,
            status: _ProcurementItemStatus.planning,
            priority: _ProcurementPriority.medium,
            budget: 50000 + (i * 10000),
            estimatedDelivery: _formatStoreDate(now.add(Duration(days: 90))),
            progress: 0.0,
          ));
        }
      }

      // Update with AI-generated items if we got any
      if (mounted && items.isNotEmpty) {
        setState(() {
          _items.clear();
          _items.addAll(items);
        });
      }
    } catch (e) {
      debugPrint('Error generating items: $e');
      // Fallback items already set above, so no need to set again
    }
  }

  void _generateStrategies() {
    setState(() {
      _strategies.clear();
      // Count items by category, or use default counts if items haven't been generated yet
      final itItemCount =
          _items.where((i) => i.category == 'IT Equipment').length;
      final constructionItemCount =
          _items.where((i) => i.category == 'Construction Services').length;
      final furnitureItemCount =
          _items.where((i) => i.category == 'Furniture').length;

      _strategies.addAll([
        _ProcurementStrategy(
          title: 'IT Infrastructure Procurement',
          status: _StrategyStatus.active,
          itemCount: itItemCount > 0 ? itItemCount : 1,
          description:
              'Strategic approach for acquiring IT infrastructure components and equipment.',
        ),
        _ProcurementStrategy(
          title: 'Construction & Facilities',
          status: _StrategyStatus.active,
          itemCount: constructionItemCount > 0 ? constructionItemCount : 1,
          description:
              'Procurement strategy for construction services and facility improvements.',
        ),
        _ProcurementStrategy(
          title: 'Office & Workspace',
          status: _StrategyStatus.draft,
          itemCount: furnitureItemCount > 0 ? furnitureItemCount : 1,
          description:
              'Strategy for furnishing and equipping office spaces and work areas.',
        ),
      ]);
    });
  }

  Future<void> _generateVendors(
      String projectName, String solutionTitle, String notes) async {
    // Set fallback vendors immediately so UI shows content
    if (mounted) {
      setState(() {
        _vendors.clear();
        _vendors.addAll([
          _VendorRow(
              id: _newVendorId(),
              initials: 'TC',
              name: 'TechCorp Solutions',
              category: 'IT Equipment',
              rating: 4,
              approved: true,
              preferred: false),
          _VendorRow(
              id: _newVendorId(),
              initials: 'BC',
              name: 'BuildRight Contractors',
              category: 'Construction Services',
              rating: 5,
              approved: true,
              preferred: true),
          _VendorRow(
              id: _newVendorId(),
              initials: 'OE',
              name: 'Office Essentials Co',
              category: 'Furniture',
              rating: 4,
              approved: true,
              preferred: false),
          _VendorRow(
              id: _newVendorId(),
              initials: 'SG',
              name: 'SecureGuard Services',
              category: 'Security',
              rating: 4,
              approved: true,
              preferred: false),
          _VendorRow(
              id: _newVendorId(),
              initials: 'FT',
              name: 'FastTrack Logistics',
              category: 'Logistics',
              rating: 5,
              approved: true,
              preferred: false),
        ]);
      });
    }

    // Then try to enhance with AI-generated data
    try {
      final vendors = await _openAi.generateProcurementVendors(
        projectName: projectName,
        solutionTitle: solutionTitle,
        contextNotes: notes,
        count: 5,
      );

      if (mounted && vendors.isNotEmpty) {
        setState(() {
          _vendors.clear();
          _vendors.addAll(vendors.map((v) {
            final name = (v['name'] ?? '').toString();
            return _VendorRow(
              id: _newVendorId(),
              initials: _deriveInitials(name),
              name: name,
              category: (v['category'] ?? 'IT Equipment').toString(),
              rating: (v['rating'] as int?) ?? 4,
              approved: v['approved'] as bool? ?? true,
              preferred: v['preferred'] as bool? ?? false,
            );
          }));
        });
      }
    } catch (e) {
      debugPrint('Error generating vendors: $e');
      // Fallback vendors already set above, so no need to set again
    }
  }

  Future<void> _generateRfqs(
      String projectName, String solutionTitle, String notes) async {
    // Set fallback RFQs immediately so UI shows content
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _rfqs.clear();
        for (int i = 0; i < 3; i++) {
          final dueDate = now.add(Duration(days: 30 + (i * 15)));
          _rfqs.add(_RfqItem(
            title: [
              'Network Infrastructure Equipment',
              'Office Furniture Set',
              'Security System Installation'
            ][i],
            category: ['IT Equipment', 'Furniture', 'Security'][i],
            owner: 'Procurement Manager',
            dueDate:
                '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
            invited: 5 + i,
            responses: 3 + i,
            budget: 50000 + (i * 25000),
            status: [
              _RfqStatus.draft,
              _RfqStatus.review,
              _RfqStatus.inMarket
            ][i],
            priority: [
              _ProcurementPriority.high,
              _ProcurementPriority.medium,
              _ProcurementPriority.critical
            ][i],
          ));
        }
      });
    }

    // Then try to enhance with AI-generated data
    try {
      final rfqs = await _openAi.generateProcurementRfqs(
        projectName: projectName,
        solutionTitle: solutionTitle,
        contextNotes: notes,
        count: 3,
      );

      if (mounted && rfqs.isNotEmpty) {
        setState(() {
          _rfqs.clear();
          _rfqs.addAll(rfqs.map((r) {
            final statusStr = (r['status'] ?? 'draft').toString();
            final priorityStr = (r['priority'] ?? 'medium').toString();

            _RfqStatus status;
            switch (statusStr.toLowerCase()) {
              case 'review':
                status = _RfqStatus.review;
                break;
              case 'inmarket':
              case 'in_market':
                status = _RfqStatus.inMarket;
                break;
              case 'evaluation':
                status = _RfqStatus.evaluation;
                break;
              case 'awarded':
                status = _RfqStatus.awarded;
                break;
              default:
                status = _RfqStatus.draft;
            }

            _ProcurementPriority priority;
            switch (priorityStr.toLowerCase()) {
              case 'critical':
                priority = _ProcurementPriority.critical;
                break;
              case 'high':
                priority = _ProcurementPriority.high;
                break;
              case 'low':
                priority = _ProcurementPriority.low;
                break;
              default:
                priority = _ProcurementPriority.medium;
            }

            return _RfqItem(
              title: (r['title'] ?? '').toString(),
              category: (r['category'] ?? 'IT Equipment').toString(),
              owner: (r['owner'] ?? 'Procurement Manager').toString(),
              dueDate: (r['dueDate'] ?? '').toString(),
              invited: (r['invited'] as int?) ?? 5,
              responses: (r['responses'] as int?) ?? 3,
              budget: (r['budget'] as int?) ?? 50000,
              status: status,
              priority: priority,
            );
          }));
        });
      }
    } catch (e) {
      debugPrint('Error generating RFQs: $e');
      // Fallback RFQs already set above, so no need to set again
    }
  }

  Future<void> _generatePurchaseOrders(
      String projectName, String solutionTitle, String notes) async {
    // Set fallback purchase orders immediately so UI shows content
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _purchaseOrders.clear();
        for (int i = 0; i < 4; i++) {
          final orderedDate = now.subtract(Duration(days: 10 + (i * 5)));
          final expectedDate = now.add(Duration(days: 20 + (i * 10)));
          _purchaseOrders.add(_PurchaseOrder(
            id: 'PO-${(1000 + i).toString().padLeft(4, '0')}',
            vendor: [
              'TechCorp Solutions',
              'BuildRight Contractors',
              'Office Essentials Co',
              'SecureGuard Services'
            ][i],
            category: [
              'IT Equipment',
              'Construction Services',
              'Furniture',
              'Security'
            ][i],
            owner: 'Procurement Manager',
            orderedDate:
                '${orderedDate.year}-${orderedDate.month.toString().padLeft(2, '0')}-${orderedDate.day.toString().padLeft(2, '0')}',
            expectedDate:
                '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}',
            amount: 50000 + (i * 25000),
            progress: [0.3, 0.6, 0.8, 1.0][i],
            status: [
              _PurchaseOrderStatus.awaitingApproval,
              _PurchaseOrderStatus.issued,
              _PurchaseOrderStatus.inTransit,
              _PurchaseOrderStatus.received
            ][i],
          ));
        }
      });
    }

    // Then try to enhance with AI-generated data
    try {
      final pos = await _openAi.generateProcurementPurchaseOrders(
        projectName: projectName,
        solutionTitle: solutionTitle,
        contextNotes: notes,
        count: 4,
      );

      if (mounted && pos.isNotEmpty) {
        setState(() {
          _purchaseOrders.clear();
          _purchaseOrders.addAll(pos.map((po) {
            final statusStr = (po['status'] ?? 'issued').toString();

            _PurchaseOrderStatus status;
            switch (statusStr.toLowerCase()) {
              case 'awaitingapproval':
              case 'awaiting_approval':
                status = _PurchaseOrderStatus.awaitingApproval;
                break;
              case 'intransit':
              case 'in_transit':
                status = _PurchaseOrderStatus.inTransit;
                break;
              case 'received':
                status = _PurchaseOrderStatus.received;
                break;
              default:
                status = _PurchaseOrderStatus.issued;
            }

            return _PurchaseOrder(
              id: (po['id'] ?? 'PO-0001').toString(),
              vendor: (po['vendor'] ?? '').toString(),
              category: (po['category'] ?? 'IT Equipment').toString(),
              owner: (po['owner'] ?? 'Procurement Manager').toString(),
              orderedDate: (po['orderedDate'] ?? '').toString(),
              expectedDate: (po['expectedDate'] ?? '').toString(),
              amount: (po['amount'] as int?) ?? 50000,
              progress:
                  ((po['progress'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
              status: status,
            );
          }));
        });
      }
    } catch (e) {
      debugPrint('Error generating purchase orders: $e');
      // Fallback purchase orders already set above, so no need to set again
    }
  }

  Future<void> _generateTrackableItems(
      String projectName, String solutionTitle, String notes) async {
    // Set fallback trackable items immediately so UI shows content
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _trackableItems.clear();
        for (int i = 0; i < 3; i++) {
          final lastUpdate = now.subtract(Duration(days: i));
          _trackableItems.add(_TrackableItem(
            name: [
              'Network Infrastructure Equipment',
              'Office Furniture Set',
              'Security Cameras'
            ][i],
            description: 'Procurement item for project delivery',
            orderStatus: 'Ordered',
            currentStatus: [
              _TrackableStatus.inTransit,
              _TrackableStatus.inTransit,
              _TrackableStatus.delivered
            ][i],
            lastUpdate:
                '${lastUpdate.year}-${lastUpdate.month.toString().padLeft(2, '0')}-${lastUpdate.day.toString().padLeft(2, '0')} ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}',
            events: [
              _TimelineEvent(
                title: 'Order placed',
                description: 'Order placed',
                subtext: 'not tracked',
                date:
                    '${now.subtract(Duration(days: 5 + i)).year}-${(now.subtract(Duration(days: 5 + i)).month).toString().padLeft(2, '0')}-${(now.subtract(Duration(days: 5 + i)).day).toString().padLeft(2, '0')}',
              ),
              _TimelineEvent(
                title: 'Shipped from warehouse',
                description: 'Shipped from warehouse',
                subtext: 'in transit',
                date:
                    '${now.subtract(Duration(days: 3 + i)).year}-${(now.subtract(Duration(days: 3 + i)).month).toString().padLeft(2, '0')}-${(now.subtract(Duration(days: 3 + i)).day).toString().padLeft(2, '0')}',
              ),
              if (i == 2)
                _TimelineEvent(
                  title: 'Delivered',
                  description: 'Delivered',
                  subtext: 'delivered',
                  date:
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                ),
            ],
          ));
        }
      });
    }

    // Then try to enhance with AI-generated data
    try {
      final items = await _openAi.generateProcurementTrackableItems(
        projectName: projectName,
        solutionTitle: solutionTitle,
        contextNotes: notes,
        count: 3,
      );

      if (mounted && items.isNotEmpty) {
        setState(() {
          _trackableItems.clear();
          _trackableItems.addAll(items.map((item) {
            final statusStr = (item['currentStatus'] ?? 'inTransit').toString();

            _TrackableStatus status;
            switch (statusStr.toLowerCase()) {
              case 'delivered':
                status = _TrackableStatus.delivered;
                break;
              case 'nottracked':
              case 'not_tracked':
                status = _TrackableStatus.notTracked;
                break;
              default:
                status = _TrackableStatus.inTransit;
            }

            final events = (item['events'] as List? ?? []).map((ev) {
              final eventStatusStr = (ev['status'] ?? 'inTransit').toString();
              _TrackableStatus eventStatus;
              switch (eventStatusStr.toLowerCase()) {
                case 'delivered':
                  eventStatus = _TrackableStatus.delivered;
                  break;
                case 'nottracked':
                case 'not_tracked':
                  eventStatus = _TrackableStatus.notTracked;
                  break;
                default:
                  eventStatus = _TrackableStatus.inTransit;
              }

              return _TimelineEvent(
                title: (ev['title'] ?? 'Update').toString(),
                description: (ev['title'] ?? 'Update').toString(),
                subtext: eventStatus.label,
                date: (ev['date'] ?? '').toString(),
              );
            }).toList();

            return _TrackableItem(
              name: (item['name'] ?? '').toString(),
              description: (item['description'] ?? '').toString(),
              orderStatus: (item['orderStatus'] ?? 'Ordered').toString(),
              currentStatus: status,
              lastUpdate: (item['lastUpdate'] ?? '').toString(),
              events: events,
            );
          }));
        });
      }
    } catch (e) {
      debugPrint('Error generating trackable items: $e');
      // Fallback trackable items already set above, so no need to set again
    }
  }

  void _generateReportsData() {
    final reportsData = _openAi.generateProcurementReportsData();
    if (reportsData.isEmpty) return;

    final data = reportsData.first;

    setState(() {
      // KPIs
      _reportKpis.clear();
      final kpis = (data['kpis'] as List? ?? []);
      _reportKpis.addAll(kpis.map((k) => _ReportKpi(
            label: (k['label'] ?? '').toString(),
            value: (k['value'] ?? '').toString(),
            delta: (k['delta'] ?? '').toString(),
            positive: k['positive'] as bool? ?? true,
          )));

      // Spend breakdown
      _spendBreakdown.clear();
      final spend = (data['spendBreakdown'] as List? ?? []);
      _spendBreakdown.addAll(spend.map((s) => _SpendBreakdown(
            label: (s['label'] ?? '').toString(),
            amount: (s['amount'] as int?) ?? 0,
            percent:
                ((s['percent'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 100.0),
            color: Color((s['color'] as int?) ?? 0xFF64748B),
          )));

      // Lead time metrics
      _leadTimeMetrics.clear();
      final leadTimes = (data['leadTimeMetrics'] as List? ?? []);
      _leadTimeMetrics.addAll(leadTimes.map((l) => _LeadTimeMetric(
            label: (l['label'] ?? '').toString(),
            onTimeRate:
                ((l['onTimeRate'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
          )));

      // Savings opportunities
      _savingsOpportunities.clear();
      final savings = (data['savingsOpportunities'] as List? ?? []);
      _savingsOpportunities.addAll(savings.map((s) => _SavingsOpportunity(
            title: (s['title'] ?? '').toString(),
            value: (s['value'] ?? '').toString(),
            owner: (s['owner'] ?? '').toString(),
          )));

      // Compliance metrics
      _complianceMetrics.clear();
      final compliance = (data['complianceMetrics'] as List? ?? []);
      _complianceMetrics.addAll(compliance.map((c) => _ComplianceMetric(
            label: (c['label'] ?? '').toString(),
            value: ((c['value'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
          )));
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  List<String> get _categoryOptions {
    final categories =
        _vendors.map((vendor) => vendor.category).toSet().toList()..sort();
    return ['All Categories', ...categories];
  }

  List<_VendorRow> get _filteredVendors {
    return _vendors.where((vendor) {
      if (_approvedOnly && !vendor.approved) return false;
      if (_preferredOnly && !vendor.preferred) return false;
      if (_categoryFilter != 'All Categories' &&
          vendor.category != _categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _isVendorSelected(String vendorId) =>
      _selectedVendorIds.contains(vendorId);

  void _toggleVendorSelection(String vendorId, bool selected) {
    setState(() {
      if (selected) {
        _selectedVendorIds.add(vendorId);
      } else {
        _selectedVendorIds.remove(vendorId);
      }
    });
  }

  Future<void> _openEditVendorDialog(_VendorRow vendor) async {
    final categoryOptions = const [
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics',
      'Services',
      'Materials',
    ];

    final result = await showDialog<_VendorRow>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return _AddVendorDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: categoryOptions,
          initialVendor: vendor,
        );
      },
    );

    if (result != null) {
      setState(() {
        final index = _vendors.indexWhere((v) => v.id == vendor.id);
        if (index != -1) {
          _vendors[index] = result;
        }
      });
    }
  }

  void _removeVendor(String vendorId) {
    setState(() {
      _vendors.removeWhere((vendor) => vendor.id == vendorId);
      _selectedVendorIds.remove(vendorId);
    });
  }

  void _handleNotesChanged(String value) {
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          procurement: value,
        ),
      ),
    );
  }

  Future<bool> _persistProcurementNotes({bool showConfirmation = false}) async {
    final success = await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'fep_procurement',
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          procurement: _notes.text.trim(),
        ),
      ),
      showSnackbar: false,
    );

    if (mounted && showConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Procurement notes saved'
              : 'Unable to save procurement notes'),
          backgroundColor:
              success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    }

    return success;
  }

  void _toggleStrategy(int index) {
    setState(() {
      if (_expandedStrategies.contains(index)) {
        _expandedStrategies.remove(index);
      } else {
        _expandedStrategies.add(index);
      }
    });
  }

  void _handleItemListTap() {
    setState(() => _selectedTab = _ProcurementTab.itemsList);
    // Trigger generation if items are empty
    if (_items.isEmpty) {
      _generateProcurementDataIfNeeded();
    }
  }

  void _handleTabSelected(_ProcurementTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    // Trigger generation if switching to items list and items are empty
    if (tab == _ProcurementTab.itemsList && _items.isEmpty) {
      _generateProcurementDataIfNeeded();
    }
  }

  void _handleTrackableSelected(int index) {
    if (_selectedTrackableIndex == index) return;
    setState(() => _selectedTrackableIndex = index);
  }

  _ProcurementTab? _nextTab() {
    final tabs = _ProcurementTab.values;
    final index = tabs.indexOf(_selectedTab);
    if (index == -1 || index >= tabs.length - 1) return null;
    return tabs[index + 1];
  }

  Future<void> _goToNextSection() async {
    final nextTab = _nextTab();
    if (nextTab != null) {
      setState(() => _selectedTab = nextTab);
      return;
    }

    // Save all data before navigation to prevent data loss
    final provider = ProjectDataHelper.getProvider(context);
    try {
      // Ensure all items are saved
      await provider.saveToFirebase(checkpoint: 'fep_procurement');
    } catch (e) {
      debugPrint('Error saving before navigation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // Don't navigate if save fails
    }

    // Check if destination is locked
    if (ProjectDataHelper.isDestinationLocked(context, 'fep_security')) {
      ProjectDataHelper.showLockedDestinationMessage(context, 'Security');
      return;
    }

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'fep_procurement',
      destinationCheckpoint: 'fep_security',
      destinationName: 'Security',
      nextScreenBuilder: () => const FrontEndPlanningSecurityScreen(),
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          procurement: _notes.text.trim(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case _ProcurementTab.procurementDashboard:
        return _buildDashboardSection();
      case _ProcurementTab.itemsList:
        return _ItemsListView(
          key: const ValueKey('procurement_items_list'),
          items: _items,
          trackableItems: _trackableItems,
          selectedIndex: _selectedTrackableIndex,
          onSelectTrackable: _handleTrackableSelected,
          currencyFormat: _currencyFormat,
          onAddItem: _openAddItemDialog,
        );
      case _ProcurementTab.vendorManagement:
        return _VendorManagementView(
          key: const ValueKey('procurement_vendor_management'),
          vendors: _filteredVendors,
          allVendors: _vendors,
          selectedVendorIds: _selectedVendorIds,
          approvedOnly: _approvedOnly,
          preferredOnly: _preferredOnly,
          listView: _listView,
          categoryFilter: _categoryFilter,
          categoryOptions: _categoryOptions,
          healthMetrics: _vendorHealthMetrics,
          onboardingTasks: _vendorOnboardingTasks,
          riskItems: _vendorRiskItems,
          onAddVendor: _openAddVendorDialog,
          onApprovedChanged: (value) => setState(() => _approvedOnly = value),
          onPreferredChanged: (value) => setState(() => _preferredOnly = value),
          onCategoryChanged: (value) => setState(() => _categoryFilter = value),
          onViewModeChanged: (value) => setState(() => _listView = value),
          onToggleVendorSelected: _toggleVendorSelection,
          onEditVendor: _openEditVendorDialog,
          onDeleteVendor: _removeVendor,
        );
      case _ProcurementTab.rfqWorkflow:
        return _RfqWorkflowView(
          key: const ValueKey('procurement_rfq_workflow'),
          rfqs: _rfqs,
          criteria: _rfqCriteria,
          currencyFormat: _currencyFormat,
          onCreateRfq: _openCreateRfqDialog,
        );
      case _ProcurementTab.purchaseOrders:
        return _PurchaseOrdersView(
          key: const ValueKey('procurement_purchase_orders'),
          orders: _purchaseOrders,
          currencyFormat: _currencyFormat,
          onCreatePo: _openCreatePoDialog,
        );
      case _ProcurementTab.itemTracking:
        return _ItemTrackingView(
          key: const ValueKey('procurement_item_tracking'),
          trackableItems: _trackableItems,
          selectedIndex: _selectedTrackableIndex,
          onSelectTrackable: _handleTrackableSelected,
          selectedItem: (_selectedTrackableIndex >= 0 &&
                  _selectedTrackableIndex < _trackableItems.length)
              ? _trackableItems[_selectedTrackableIndex]
              : null,
          alerts: _trackingAlerts,
          carriers: _carrierPerformance,
        );
      case _ProcurementTab.reports:
        return _ReportsView(
          key: const ValueKey('procurement_reports'),
          kpis: _reportKpis,
          spendBreakdown: _spendBreakdown,
          leadTimeMetrics: _leadTimeMetrics,
          savingsOpportunities: _savingsOpportunities,
          complianceMetrics: _complianceMetrics,
          currencyFormat: _currencyFormat,
        );
    }
  }

  Widget _buildNextSectionButton() {
    final nextTab = _nextTab();
    final nextLabel = nextTab?.label ?? 'Security';
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _goToNextSection,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF6C437),
          foregroundColor: const Color(0xFF111827),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 0,
        ),
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: Text('Next: $nextLabel',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildDashboardSection({Key? key}) {
    return Column(
      key: key ?? const ValueKey('procurement_dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PlanHeader(onItemListTap: _handleItemListTap)),
            PageRegenerateAllButton(
              onRegenerateAll: () async {
                final confirmed = await showRegenerateAllConfirmation(context);
                if (confirmed && mounted) {
                  await _regenerateAllProcurement();
                }
              },
              isLoading: _isGeneratingData,
              tooltip: 'Regenerate all procurement data',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 8),
        _StrategiesSection(
          strategies: _strategies,
          expandedStrategies: _expandedStrategies,
          onToggle: _toggleStrategy,
        ),
        const SizedBox(height: 32),
        _VendorsSection(
          vendors: _filteredVendors,
          allVendorsCount: _vendors.length,
          selectedVendorIds: _selectedVendorIds,
          approvedOnly: _approvedOnly,
          preferredOnly: _preferredOnly,
          listView: _listView,
          categoryFilter: _categoryFilter,
          categoryOptions: _categoryOptions,
          onAddVendor: _openAddVendorDialog,
          onApprovedChanged: (value) => setState(() => _approvedOnly = value),
          onPreferredChanged: (value) => setState(() => _preferredOnly = value),
          onCategoryChanged: (value) => setState(() => _categoryFilter = value),
          onViewModeChanged: (value) => setState(() => _listView = value),
          onToggleVendorSelected: _toggleVendorSelection,
          onEditVendor: _openEditVendorDialog,
          onDeleteVendor: _removeVendor,
        ),
      ],
    );
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatStoreDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  String _formatDisplayDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  String _deriveInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  List<Widget> _buildDialogContextChips() {
    final data = ProjectDataHelper.getData(context);
    final chips = <Widget>[
      const _ContextChip(label: 'Phase', value: 'Front End Planning'),
    ];
    final projectName = data.projectName.trim();
    if (projectName.isNotEmpty) {
      chips.insert(0, _ContextChip(label: 'Project', value: projectName));
    }
    final solution = data.solutionTitle.trim();
    if (solution.isNotEmpty) {
      chips.add(_ContextChip(label: 'Solution', value: solution));
    }
    return chips;
  }

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? helperText,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _openAddItemDialog() async {
    final categoryOptions = const [
      'Materials',
      'Equipment',
      'Services',
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics',
    ];

    final result = await showDialog<_ProcurementItem>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return _AddItemDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: categoryOptions,
        );
      },
    );

    if (result != null) {
      // Save items to provider before updating local state
      final provider = ProjectDataHelper.getProvider(context);

      setState(() {
        _items.add(result);
      });

      // Save to Firebase to prevent data loss
      try {
        await provider.saveToFirebase(checkpoint: 'fep_procurement');
      } catch (e) {
        debugPrint('Error saving procurement items: $e');
      }
    }
  }

  Future<void> _openAddVendorDialog() async {
    final categoryOptions = const [
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics',
      'Services',
      'Materials',
    ];

    final result = await showDialog<_VendorRow>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return _AddVendorDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: categoryOptions,
        );
      },
    );

    if (result != null) {
      setState(() => _vendors.add(result));
    }
  }

  Future<void> _openCreateRfqDialog() async {
    final categoryOptions = const [
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Services',
      'Materials'
    ];

    final result = await showDialog<_RfqItem>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return _CreateRfqDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: categoryOptions,
        );
      },
    );

    if (result != null) {
      setState(() => _rfqs.add(result));
    }
  }

  Future<void> _openCreatePoDialog() async {
    final categoryOptions = const [
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics',
      'Services'
    ];

    final result = await showDialog<_PurchaseOrder>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return _CreatePoDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: categoryOptions,
        );
      },
    );

    if (result != null) {
      setState(() => _purchaseOrders.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child:
                  const InitiationLikeSidebar(activeItemLabel: 'Procurement'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5F6FA),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ProcurementTopBar(
                                  onBack: () =>
                                      Navigator.of(context).maybePop(),
                                  onForward: _goToNextSection,
                                ),
                                const SizedBox(height: 24),
                                const PlanningAiNotesCard(
                                  title: 'Notes',
                                  sectionLabel: 'Procurement',
                                  noteKey: 'planning_procurement_notes',
                                  checkpoint: 'fep_procurement',
                                  description:
                                      'Capture procurement priorities, vendors, and approval constraints.',
                                ),
                                const SizedBox(height: 16),
                                _NotesCard(
                                  controller: _notes,
                                  onChanged: _handleNotesChanged,
                                ),
                                const SizedBox(height: 32),
                                _ProcurementTabBar(
                                  selectedTab: _selectedTab,
                                  onSelected: _handleTabSelected,
                                ),
                                const SizedBox(height: 24),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _buildTabContent(),
                                ),
                                const SizedBox(height: 24),
                                _buildNextSectionButton(),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _ProcurementTopBar extends StatelessWidget {
  const _ProcurementTopBar({required this.onBack, required this.onForward});

  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          _circleButton(
              icon: Icons.arrow_forward_ios_rounded, onTap: onForward),
          const SizedBox(width: 20),
          const Text(
            'Procurement',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          const _UserBadge(),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge();

  @override
  Widget build(BuildContext context) {
    final projectName = ProjectDataHelper.getData(context).projectName.trim();
    final displayName = projectName.isEmpty ? 'Procurement Team' : projectName;
    final roleLabel = projectName.isEmpty ? 'Procurement' : 'Procurement Plan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFD1D5DB),
            child: Icon(Icons.person, size: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Text(
            displayName,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(width: 6),
          Text(
            roleLabel,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: controller,
        minLines: 5,
        maxLines: 8,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Input your notes here...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _ProcurementTabBar extends StatelessWidget {
  const _ProcurementTabBar(
      {required this.selectedTab, required this.onSelected});

  final _ProcurementTab selectedTab;
  final ValueChanged<_ProcurementTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = _ProcurementTab.values;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 960;
          if (isCompact) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in tabs)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: 160,
                        child: _TabButton(
                          label: tab.label,
                          selected: tab == selectedTab,
                          onTap: () => onSelected(tab),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          final double tabWidth =
              (constraints.maxWidth - (tabs.length - 1) * 8) / tabs.length;
          return Row(
            children: [
              for (final tab in tabs) ...[
                SizedBox(
                  width: tabWidth,
                  child: _TabButton(
                    label: tab.label,
                    selected: tab == selectedTab,
                    onTap: () => onSelected(tab),
                  ),
                ),
                if (tab != tabs.last) const SizedBox(width: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? const Color(0xFF2563EB) : Colors.transparent,
            width: 1.2),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x0C1D4ED8),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.onItemListTap});

  final VoidCallback onItemListTap;

  @override
  Widget build(BuildContext context) {
    final projectName = ProjectDataHelper.getData(context).projectName.trim();
    final title = projectName.isEmpty
        ? 'Procurement Plan'
        : '$projectName Procurement Plan';

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline,
                  size: 18, color: Color(0xFF6B7280)),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onItemListTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            foregroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Item List'),
        ),
      ],
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard(
      {required this.onAccept, required this.onEdit, required this.onReject});

  final VoidCallback onAccept;
  final VoidCallback onEdit;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCF0E6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_circle_rounded, color: Color(0xFF0EA5E9)),
              SizedBox(width: 12),
              Text(
                'AI Suggestion',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on your scope, group items by category and delivery window to streamline sourcing and approvals.',
            style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onReject, child: const Text('Reject')),
              const SizedBox(width: 12),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsListView extends StatelessWidget {
  const _ItemsListView({
    super.key,
    required this.items,
    required this.trackableItems,
    required this.selectedIndex,
    required this.onSelectTrackable,
    required this.currencyFormat,
    required this.onAddItem,
  });

  final List<_ProcurementItem> items;
  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;
  final NumberFormat currencyFormat;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final totalItems = items.length;
    final criticalItems = items
        .where((item) => item.priority == _ProcurementPriority.critical)
        .length;
    final pendingApprovals = items
        .where((item) =>
            item.status == _ProcurementItemStatus.vendorSelection &&
            item.priority == _ProcurementPriority.critical)
        .length;
    final totalBudget =
        items.fold<int>(0, (value, item) => value + item.budget);
    final selectedTrackable =
        (selectedIndex >= 0 && selectedIndex < trackableItems.length)
            ? trackableItems[selectedIndex]
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryMetricsRow(
          totalItems: totalItems,
          criticalItems: criticalItems,
          pendingApprovals: pendingApprovals,
          totalBudgetLabel: currencyFormat.format(totalBudget),
        ),
        const SizedBox(height: 24),
        _ItemsToolbar(onAddItem: onAddItem),
        const SizedBox(height: 20),
        _ItemsTable(
            items: items, currencyFormat: currencyFormat, onAddItem: onAddItem),
        const SizedBox(height: 28),
        _TrackableAndTimeline(
          trackableItems: trackableItems,
          selectedIndex: selectedIndex,
          onSelectTrackable: onSelectTrackable,
          selectedItem: selectedTrackable,
        ),
      ],
    );
  }
}

class _SummaryMetricsRow extends StatelessWidget {
  const _SummaryMetricsRow({
    required this.totalItems,
    required this.criticalItems,
    required this.pendingApprovals,
    required this.totalBudgetLabel,
  });

  final int totalItems;
  final int criticalItems;
  final int pendingApprovals;
  final String totalBudgetLabel;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final cards = [
      _SummaryCard(
        icon: Icons.inventory_2_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$totalItems',
        label: 'Total Items',
      ),
      _SummaryCard(
        icon: Icons.warning_amber_rounded,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$criticalItems',
        label: 'Critical Items',
        valueColor: const Color(0xFFDC2626),
      ),
      _SummaryCard(
        icon: Icons.access_time,
        iconBackground: const Color(0xFFF5F3FF),
        value: '$pendingApprovals',
        label: 'Pending Approvals',
        valueColor: const Color(0xFF1F2937),
      ),
      _SummaryCard(
        icon: Icons.attach_money,
        iconBackground: const Color(0xFFECFEFF),
        value: totalBudgetLabel,
        label: 'Total Budget',
        valueColor: const Color(0xFF047857),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
          const SizedBox(height: 12),
          cards[3],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconBackground,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final Color iconBackground;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconBackground, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsToolbar extends StatelessWidget {
  const _ItemsToolbar({required this.onAddItem});

  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _DropdownField(label: 'All Categories')),
              SizedBox(width: 12),
              Expanded(child: _DropdownField(label: 'All Statuses')),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _AddItemButton(onPressed: onAddItem),
          ),
        ],
      );
    }

    return Row(
      children: [
        const SizedBox(width: 320, child: _SearchField()),
        const SizedBox(width: 16),
        const SizedBox(
            width: 190, child: _DropdownField(label: 'All Categories')),
        const SizedBox(width: 16),
        const SizedBox(
            width: 190, child: _DropdownField(label: 'All Statuses')),
        const Spacer(),
        _AddItemButton(onPressed: onAddItem),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
          hintText: 'Search items...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final options = label == 'All Categories'
        ? const ['All Categories', 'Materials', 'Equipment', 'Services']
        : const [
            'All Statuses',
            'Planning',
            'RFQ Review',
            'Vendor Selection',
            'Ordered',
            'Delivered'
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B)),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF334155))),
                ),
              )
              .toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: const Icon(Icons.add_rounded),
      label:
          const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable(
      {required this.items,
      required this.currencyFormat,
      required this.onAddItem});

  final List<_ProcurementItem> items;
  final NumberFormat currencyFormat;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyStateCard(
        icon: Icons.inventory_2_outlined,
        title: 'No procurement items yet',
        message:
            'Add items to track budgets, approvals, and delivery timelines.',
        actionLabel: 'Add Item',
        onAction: onAddItem,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: _ItemsTableHeader(),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          for (var i = 0; i < items.length; i++) ...[
            _ItemRow(item: items[i], currencyFormat: currencyFormat),
            if (i != items.length - 1)
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }
}

class _ItemsTableHeader extends StatelessWidget {
  const _ItemsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _HeaderCell(label: 'Item', flex: 4),
        _HeaderCell(label: 'Category', flex: 2),
        _HeaderCell(label: 'Status', flex: 2),
        _HeaderCell(label: 'Priority', flex: 2),
        _HeaderCell(label: 'Budget', flex: 2),
        _HeaderCell(label: 'Est. Delivery', flex: 2),
        _HeaderCell(label: 'Progress', flex: 2),
        _HeaderCell(label: 'Actions', flex: 2, alignEnd: true),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
      {required this.label, required this.flex, this.alignEnd = false});

  final String label;
  final int flex;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.currencyFormat});

  final _ProcurementItem item;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(item.estimatedDelivery);
    final dateLabel = DateFormat('M/d/yyyy').format(date);
    final progressLabel = '${(item.progress * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(item.category,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgePill(
                label: item.status.label,
                background: item.status.backgroundColor,
                border: item.status.borderColor,
                foreground: item.status.textColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgePill(
                label: item.priority.label,
                background: item.priority.backgroundColor,
                border: item.priority.borderColor,
                foreground: item.priority.textColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(item.budget),
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(dateLabel,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(progressLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.progress.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(item.progressColor),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                _ActionIcon(icon: Icons.remove_red_eye_outlined),
                SizedBox(width: 8),
                _ActionIcon(icon: Icons.edit_outlined),
                SizedBox(width: 8),
                _ActionIcon(icon: Icons.link_outlined),
                SizedBox(width: 8),
                _ActionIcon(icon: Icons.more_horiz_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF475569)),
      ),
    );
  }
}

class _TrackableAndTimeline extends StatelessWidget {
  const _TrackableAndTimeline({
    required this.trackableItems,
    required this.selectedIndex,
    required this.onSelectTrackable,
    required this.selectedItem,
  });

  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;
  final _TrackableItem? selectedItem;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrackableItemsCard(
            trackableItems: trackableItems,
            selectedIndex: selectedIndex,
            onSelectTrackable: onSelectTrackable,
          ),
          const SizedBox(height: 20),
          _TrackingTimelineCard(item: selectedItem),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _TrackableItemsCard(
            trackableItems: trackableItems,
            selectedIndex: selectedIndex,
            onSelectTrackable: onSelectTrackable,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _TrackingTimelineCard(item: selectedItem),
        ),
      ],
    );
  }
}

class _TrackableItemsCard extends StatelessWidget {
  const _TrackableItemsCard(
      {required this.trackableItems,
      required this.selectedIndex,
      required this.onSelectTrackable});

  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;

  @override
  Widget build(BuildContext context) {
    if (trackableItems.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.all(24),
        child: const _EmptyStateBody(
          icon: Icons.local_shipping_outlined,
          title: 'No trackable items yet',
          message: 'Add procurement items to begin shipment tracking.',
          compact: true,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Text(
              'Trackable Items',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          for (var i = 0; i < trackableItems.length; i++)
            _TrackableRow(
              item: trackableItems[i],
              selected: i == selectedIndex,
              onTap: () => onSelectTrackable(i),
              showDivider: i != trackableItems.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TrackableRow extends StatelessWidget {
  const _TrackableRow(
      {required this.item,
      required this.selected,
      required this.onTap,
      required this.showDivider});

  final _TrackableItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final lastUpdateLabel = item.lastUpdate != null
        ? DateFormat('M/d/yyyy').format(DateTime.parse(item.lastUpdate!))
        : 'Never';

    return Material(
      color: selected ? const Color(0xFFF8FAFC) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.description,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.orderStatus.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _BadgePill(
                        label: item.currentStatus.label,
                        background: item.currentStatus.backgroundColor,
                        border: item.currentStatus.borderColor,
                        foreground: item.currentStatus.textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(lastUpdateLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF334155))),
                  ),
                  const _UpdateButton(),
                ],
              ),
              if (showDivider) const SizedBox(height: 18),
              if (showDivider)
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF1F2937),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: const Text('Update',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _TrackingTimelineCard extends StatelessWidget {
  const _TrackingTimelineCard({required this.item});

  final _TrackableItem? item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: item == null
          ? const Center(
              child: Text(
                'Select an item to view tracking timeline.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Timeline',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                Text(
                  item!.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Click on an item to view its tracking timeline',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                _BadgePill(
                  label: item!.currentStatus.label,
                  background: item!.currentStatus.backgroundColor,
                  border: item!.currentStatus.borderColor,
                  foreground: item!.currentStatus.textColor,
                ),
                const SizedBox(height: 16),
                for (final event in item!.events) ...[
                  _TimelineEntry(event: event),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.event});

  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('M/d/yyyy').format(DateTime.parse(event.date));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.local_shipping_outlined,
              size: 18, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 6),
              Text(
                event.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Text(
                event.subtext,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StrategiesSection extends StatelessWidget {
  const _StrategiesSection(
      {required this.strategies,
      required this.expandedStrategies,
      required this.onToggle});

  final List<_ProcurementStrategy> strategies;
  final Set<int> expandedStrategies;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Procurement Strategies',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)),
            ),
            Text(
              '${strategies.length} ${strategies.length == 1 ? 'strategy' : 'strategies'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (strategies.isEmpty)
          const _EmptyStateCard(
            icon: Icons.insights_outlined,
            title: 'No strategies yet',
            message:
                'Capture your procurement approach or add a strategy to organize sourcing.',
          )
        else
          Column(
            children: [
              for (var i = 0; i < strategies.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: i == strategies.length - 1 ? 0 : 12),
                  child: _StrategyCard(
                    strategy: strategies[i],
                    expanded: expandedStrategies.contains(i),
                    onTap: () => onToggle(i),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  const _StrategyCard(
      {required this.strategy, required this.expanded, required this.onTap});

  final _ProcurementStrategy strategy;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: const Color(0x19000000),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strategy.title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${strategy.itemCount} items',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: strategy.status),
                  const SizedBox(width: 16),
                  Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: const Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
          if (expanded) const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text(
                strategy.description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final _StrategyStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == _StrategyStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8FFF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color:
                isActive ? const Color(0xFF34D399) : const Color(0xFFD1D5DB)),
      ),
      child: Text(
        isActive ? 'active' : 'draft',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _VendorsSection extends StatelessWidget {
  const _VendorsSection({
    required this.vendors,
    required this.allVendorsCount,
    required this.selectedVendorIds,
    required this.approvedOnly,
    required this.preferredOnly,
    required this.listView,
    required this.categoryFilter,
    required this.categoryOptions,
    required this.onApprovedChanged,
    required this.onPreferredChanged,
    required this.onCategoryChanged,
    required this.onViewModeChanged,
    required this.onToggleVendorSelected,
    required this.onEditVendor,
    required this.onDeleteVendor,
    this.onAddVendor,
  });

  final List<_VendorRow> vendors;
  final int allVendorsCount;
  final Set<String> selectedVendorIds;
  final bool approvedOnly;
  final bool preferredOnly;
  final bool listView;
  final String categoryFilter;
  final List<String> categoryOptions;
  final ValueChanged<bool> onApprovedChanged;
  final ValueChanged<bool> onPreferredChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onViewModeChanged;
  final void Function(String vendorId, bool selected) onToggleVendorSelected;
  final ValueChanged<_VendorRow> onEditVendor;
  final ValueChanged<String> onDeleteVendor;
  final VoidCallback? onAddVendor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vendors',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)),
            ),
            Text(
              '${vendors.length} of $allVendorsCount vendors',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined, size: 18),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            FilterChip(
              label: const Text('Approved Only'),
              selected: approvedOnly,
              onSelected: onApprovedChanged,
              selectedColor: const Color(0xFFEFF6FF),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: approvedOnly
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
            FilterChip(
              label: const Text('Preferred Only'),
              selected: preferredOnly,
              onSelected: onPreferredChanged,
              selectedColor: const Color(0xFFF1F5F9),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: preferredOnly
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: categoryFilter,
                  items: categoryOptions
                      .map((option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onCategoryChanged(value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            ToggleButtons(
              borderRadius: BorderRadius.circular(12),
              constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
              isSelected: [listView, !listView],
              onPressed: (index) => onViewModeChanged(index == 0),
              children: const [
                Icon(Icons.view_list_rounded, size: 20),
                Icon(Icons.grid_view_rounded, size: 20),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Company Approved Vendor List'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (vendors.isEmpty)
          _EmptyStateCard(
            icon: Icons.storefront_outlined,
            title: allVendorsCount == 0 ? 'No vendors yet' : 'No vendors match',
            message: allVendorsCount == 0
                ? 'Add your first vendor to track approvals, ratings, and performance.'
                : 'Adjust filters or add new vendors to expand coverage.',
            actionLabel: allVendorsCount == 0 ? 'Add Vendor' : null,
            onAction: onAddVendor,
          )
        else if (listView)
          _VendorDataTable(
            vendors: vendors,
            selectedVendorIds: selectedVendorIds,
            onToggleSelected: onToggleVendorSelected,
            onEditVendor: onEditVendor,
            onDeleteVendor: onDeleteVendor,
          )
        else
          _VendorGrid(
            vendors: vendors,
            selectedVendorIds: selectedVendorIds,
            onToggleSelected: onToggleVendorSelected,
            onEditVendor: onEditVendor,
            onDeleteVendor: onDeleteVendor,
          ),
      ],
    );
  }
}

class _VendorDataTable extends StatelessWidget {
  const _VendorDataTable({
    required this.vendors,
    required this.selectedVendorIds,
    required this.onToggleSelected,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  final List<_VendorRow> vendors;
  final Set<String> selectedVendorIds;
  final void Function(String vendorId, bool selected) onToggleSelected;
  final ValueChanged<_VendorRow> onEditVendor;
  final ValueChanged<String> onDeleteVendor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 24,
                headingTextStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569)),
                dataTextStyle:
                    const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                columns: const [
                  DataColumn(label: SizedBox(width: 24)),
                  DataColumn(label: Text('Vendor Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Rating')),
                  DataColumn(label: Text('Approved')),
                  DataColumn(label: Text('Preferred')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: vendors
                    .map(
                      (vendor) => DataRow(
                        cells: [
                          DataCell(
                            Checkbox(
                              value: selectedVendorIds.contains(vendor.id),
                              onChanged: (value) => onToggleSelected(
                                  vendor.id, value ?? false),
                            ),
                          ),
                          DataCell(_VendorNameCell(vendor: vendor)),
                          DataCell(Text(vendor.category)),
                          DataCell(_RatingStars(rating: vendor.rating)),
                          DataCell(_YesNoBadge(value: vendor.approved)),
                          DataCell(_YesNoBadge(
                              value: vendor.preferred, showStar: true)),
                          DataCell(_VendorActionsMenu(
                            vendor: vendor,
                            onEdit: () => onEditVendor(vendor),
                            onDelete: () => onDeleteVendor(vendor.id),
                          )),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VendorGrid extends StatelessWidget {
  const _VendorGrid({
    required this.vendors,
    required this.selectedVendorIds,
    required this.onToggleSelected,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  final List<_VendorRow> vendors;
  final Set<String> selectedVendorIds;
  final void Function(String vendorId, bool selected) onToggleSelected;
  final ValueChanged<_VendorRow> onEditVendor;
  final ValueChanged<String> onDeleteVendor;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3.2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: vendors.length,
      itemBuilder: (_, index) {
        final vendor = vendors[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Checkbox(
                  value: selectedVendorIds.contains(vendor.id),
                  onChanged: (value) =>
                      onToggleSelected(vendor.id, value ?? false),
                ),
              ),
              _VendorNameCell(vendor: vendor),
              const SizedBox(height: 8),
              Text(vendor.category,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              _RatingStars(rating: vendor.rating),
              const Spacer(),
              Row(
                children: [
                  _YesNoBadge(value: vendor.approved),
                  const SizedBox(width: 8),
                  _YesNoBadge(value: vendor.preferred, showStar: true),
                  const Spacer(),
                  _VendorActionsMenu(
                    vendor: vendor,
                    onEdit: () => onEditVendor(vendor),
                    onDelete: () => onDeleteVendor(vendor.id),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VendorActionsMenu extends StatelessWidget {
  const _VendorActionsMenu({
    required this.vendor,
    required this.onEdit,
    required this.onDelete,
  });

  final _VendorRow vendor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit vendor')),
        PopupMenuItem(value: 'delete', child: Text('Remove vendor')),
      ],
    );
  }
}

class _VendorNameCell extends StatelessWidget {
  const _VendorNameCell({required this.vendor});

  final _VendorRow vendor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE2E8F0),
          child: Text(
            vendor.initials,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              const Text(
                'View Company Approved Vendor List',
                style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFACC15),
          size: 18,
        ),
      ),
    );
  }
}

class _YesNoBadge extends StatelessWidget {
  const _YesNoBadge({required this.value, this.showStar = false});

  final bool value;
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    final Color background =
        value ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC);
    final Color foreground =
        value ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: value ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value ? 'Yes' : 'No',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground)),
          if (showStar) ...[
            const SizedBox(width: 6),
            Icon(value ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16, color: foreground),
          ],
        ],
      ),
    );
  }
}

class _VendorManagementView extends StatelessWidget {
  const _VendorManagementView({
    super.key,
    required this.vendors,
    required this.allVendors,
    required this.selectedVendorIds,
    required this.approvedOnly,
    required this.preferredOnly,
    required this.listView,
    required this.categoryFilter,
    required this.categoryOptions,
    required this.healthMetrics,
    required this.onboardingTasks,
    required this.riskItems,
    required this.onAddVendor,
    required this.onApprovedChanged,
    required this.onPreferredChanged,
    required this.onCategoryChanged,
    required this.onViewModeChanged,
    required this.onToggleVendorSelected,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  final List<_VendorRow> vendors;
  final List<_VendorRow> allVendors;
  final Set<String> selectedVendorIds;
  final bool approvedOnly;
  final bool preferredOnly;
  final bool listView;
  final String categoryFilter;
  final List<String> categoryOptions;
  final List<_VendorHealthMetric> healthMetrics;
  final List<_VendorOnboardingTask> onboardingTasks;
  final List<_VendorRiskItem> riskItems;
  final VoidCallback onAddVendor;
  final ValueChanged<bool> onApprovedChanged;
  final ValueChanged<bool> onPreferredChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onViewModeChanged;
  final void Function(String vendorId, bool selected) onToggleVendorSelected;
  final ValueChanged<_VendorRow> onEditVendor;
  final ValueChanged<String> onDeleteVendor;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final totalVendors = allVendors.length;
    final preferredCount =
        allVendors.where((vendor) => vendor.preferred).length;
    final avgRating = totalVendors == 0
        ? 0
        : allVendors.fold<int>(0, (sum, vendor) => sum + vendor.rating) /
            totalVendors;
    final preferredRate =
        totalVendors == 0 ? 0 : (preferredCount / totalVendors * 100).round();

    final metricCards = [
      _SummaryCard(
        icon: Icons.inventory_2_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$totalVendors',
        label: 'Active Vendors',
      ),
      _SummaryCard(
        icon: Icons.star_outline,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$preferredRate%',
        label: 'Preferred Coverage',
        valueColor: const Color(0xFFF97316),
      ),
      _SummaryCard(
        icon: Icons.thumb_up_alt_outlined,
        iconBackground: const Color(0xFFF1F5F9),
        value: avgRating.toStringAsFixed(1),
        label: 'Avg Rating',
      ),
      _SummaryCard(
        icon: Icons.shield_outlined,
        iconBackground: const Color(0xFFFFF1F2),
        value: '${riskItems.length}',
        label: 'Compliance Actions',
        valueColor: const Color(0xFFDC2626),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Vendor Management',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Invite Vendor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAddVendor,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Vendor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              metricCards[0],
              const SizedBox(height: 12),
              metricCards[1],
              const SizedBox(height: 12),
              metricCards[2],
              const SizedBox(height: 12),
              metricCards[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metricCards.length; i++) ...[
                Expanded(child: metricCards[i]),
                if (i != metricCards.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _VendorHealthCard(metrics: healthMetrics),
              const SizedBox(height: 16),
              _VendorOnboardingCard(tasks: onboardingTasks),
              const SizedBox(height: 16),
              _VendorRiskCard(riskItems: riskItems),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _VendorHealthCard(metrics: healthMetrics)),
              const SizedBox(width: 16),
              Expanded(child: _VendorOnboardingCard(tasks: onboardingTasks)),
              const SizedBox(width: 16),
              Expanded(child: _VendorRiskCard(riskItems: riskItems)),
            ],
          ),
        const SizedBox(height: 24),
        _VendorsSection(
          vendors: vendors,
          allVendorsCount: allVendors.length,
          selectedVendorIds: selectedVendorIds,
          approvedOnly: approvedOnly,
          preferredOnly: preferredOnly,
          listView: listView,
          categoryFilter: categoryFilter,
          categoryOptions: categoryOptions,
          onAddVendor: onAddVendor,
          onApprovedChanged: onApprovedChanged,
          onPreferredChanged: onPreferredChanged,
          onCategoryChanged: onCategoryChanged,
          onViewModeChanged: onViewModeChanged,
          onToggleVendorSelected: onToggleVendorSelected,
          onEditVendor: onEditVendor,
          onDeleteVendor: onDeleteVendor,
        ),
      ],
    );
  }
}

class _VendorHealthCard extends StatelessWidget {
  const _VendorHealthCard({required this.metrics});

  final List<_VendorHealthMetric> metrics;

  Color _scoreColor(double score) {
    if (score >= 0.85) return const Color(0xFF10B981);
    if (score >= 0.7) return const Color(0xFF2563EB);
    return const Color(0xFFF97316);
  }

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.health_and_safety_outlined,
        title: 'Vendor health by category',
        message:
            'Health metrics will appear once vendor performance is tracked.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendor health by category',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < metrics.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrics[i].category,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${(metrics[i].score * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: metrics[i].score,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                    _scoreColor(metrics[i].score)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              metrics[i].change,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            if (i != metrics.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VendorOnboardingCard extends StatelessWidget {
  const _VendorOnboardingCard({required this.tasks});

  final List<_VendorOnboardingTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Onboarding pipeline',
        message: 'No onboarding tasks yet. Add vendors to start the pipeline.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Onboarding pipeline',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tasks.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tasks[i].title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${tasks[i].owner} · Due ${DateFormat('M/d').format(DateTime.parse(tasks[i].dueDate))}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _VendorTaskStatusPill(status: tasks[i].status),
              ],
            ),
            if (i != tasks.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VendorRiskCard extends StatelessWidget {
  const _VendorRiskCard({required this.riskItems});

  final List<_VendorRiskItem> riskItems;

  @override
  Widget build(BuildContext context) {
    if (riskItems.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.shield_outlined,
        title: 'Risk watchlist',
        message: 'Risk items will appear once vendors are assessed.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk watchlist',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < riskItems.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riskItems[i].vendor,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        riskItems[i].risk,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last incident: ${DateFormat('M/d').format(DateTime.parse(riskItems[i].lastIncident))}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _RiskSeverityPill(severity: riskItems[i].severity),
              ],
            ),
            if (i != riskItems.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VendorTaskStatusPill extends StatelessWidget {
  const _VendorTaskStatusPill({required this.status});

  final _VendorTaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.borderColor),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: status.textColor),
      ),
    );
  }
}

class _RiskSeverityPill extends StatelessWidget {
  const _RiskSeverityPill({required this.severity});

  final _RiskSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: severity.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: severity.borderColor),
      ),
      child: Text(
        severity.label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: severity.textColor),
      ),
    );
  }
}

class _RfqWorkflowView extends StatelessWidget {
  const _RfqWorkflowView({
    super.key,
    required this.rfqs,
    required this.criteria,
    required this.currencyFormat,
    required this.onCreateRfq,
  });

  final List<_RfqItem> rfqs;
  final List<_RfqCriterion> criteria;
  final NumberFormat currencyFormat;
  final VoidCallback onCreateRfq;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final stages = const [
      _RfqStage(
          title: 'Draft',
          subtitle: 'Scope and requirements',
          status: _WorkflowStageStatus.complete),
      _RfqStage(
          title: 'Review',
          subtitle: 'Stakeholder alignment',
          status: _WorkflowStageStatus.complete),
      _RfqStage(
          title: 'In Market',
          subtitle: 'Vendor outreach',
          status: _WorkflowStageStatus.active),
      _RfqStage(
          title: 'Evaluation',
          subtitle: 'Score responses',
          status: _WorkflowStageStatus.upcoming),
      _RfqStage(
          title: 'Award',
          subtitle: 'Finalize supplier',
          status: _WorkflowStageStatus.upcoming),
    ];

    final totalInvited = rfqs.fold<int>(0, (sum, rfq) => sum + rfq.invited);
    final totalResponses = rfqs.fold<int>(0, (sum, rfq) => sum + rfq.responses);
    final responseRate =
        totalInvited == 0 ? 0 : (totalResponses / totalInvited * 100).round();
    final inEvaluation =
        rfqs.where((rfq) => rfq.status == _RfqStatus.evaluation).length;
    final pipelineValue = rfqs.fold<int>(0, (sum, rfq) => sum + rfq.budget);

    final metrics = [
      _SummaryCard(
        icon: Icons.assignment_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '${rfqs.length}',
        label: 'Open RFQs',
      ),
      _SummaryCard(
        icon: Icons.checklist_rounded,
        iconBackground: const Color(0xFFF1F5F9),
        value: '$inEvaluation',
        label: 'In Evaluation',
      ),
      _SummaryCard(
        icon: Icons.groups_outlined,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$responseRate%',
        label: 'Response Rate',
        valueColor: const Color(0xFFF97316),
      ),
      _SummaryCard(
        icon: Icons.account_balance_wallet_outlined,
        iconBackground: const Color(0xFFECFEFF),
        value: currencyFormat.format(pipelineValue),
        label: 'Pipeline Value',
        valueColor: const Color(0xFF047857),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'RFQ Workflow',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Templates'),
                ),
                ElevatedButton.icon(
                  onPressed: onCreateRfq,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create RFQ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final stage in stages) _RfqStageCard(stage: stage)],
        ),
        const SizedBox(height: 20),
        if (isMobile)
          Column(
            children: [
              metrics[0],
              const SizedBox(height: 12),
              metrics[1],
              const SizedBox(height: 12),
              metrics[2],
              const SizedBox(height: 12),
              metrics[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _RfqListCard(
                  rfqs: rfqs,
                  currencyFormat: currencyFormat,
                  onCreateRfq: onCreateRfq),
              const SizedBox(height: 16),
              _RfqSidebarCard(rfqs: rfqs, criteria: criteria),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _RfqListCard(
                      rfqs: rfqs,
                      currencyFormat: currencyFormat,
                      onCreateRfq: onCreateRfq)),
              const SizedBox(width: 24),
              SizedBox(
                  width: 320,
                  child: _RfqSidebarCard(rfqs: rfqs, criteria: criteria)),
            ],
          ),
      ],
    );
  }
}

class _RfqStageCard extends StatelessWidget {
  const _RfqStageCard({required this.stage});

  final _RfqStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: stage.status.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stage.status.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(stage.status.icon, size: 20, color: stage.status.iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.subtitle,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RfqListCard extends StatelessWidget {
  const _RfqListCard(
      {required this.rfqs,
      required this.currencyFormat,
      required this.onCreateRfq});

  final List<_RfqItem> rfqs;
  final NumberFormat currencyFormat;
  final VoidCallback onCreateRfq;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Active RFQs',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
              SizedBox(width: 8),
              Text(
                'Prioritized by due date',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rfqs.isEmpty)
            _EmptyStateBody(
              icon: Icons.request_quote_outlined,
              title: 'No active RFQs',
              message: 'Create an RFQ to begin vendor outreach.',
              actionLabel: 'Create RFQ',
              onAction: onCreateRfq,
              compact: true,
            )
          else
            for (var i = 0; i < rfqs.length; i++) ...[
              _RfqItemCard(rfq: rfqs[i], currencyFormat: currencyFormat),
              if (i != rfqs.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _RfqItemCard extends StatelessWidget {
  const _RfqItemCard({required this.rfq, required this.currencyFormat});

  final _RfqItem rfq;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double responseRate =
        rfq.invited == 0 ? 0.0 : rfq.responses / rfq.invited;
    final dueLabel = DateFormat('MMM d').format(DateTime.parse(rfq.dueDate));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
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
                    Text(
                      rfq.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rfq.category} · Owner ${rfq.owner}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RfqStatusPill(status: rfq.status),
              const SizedBox(width: 6),
              _BadgePill(
                label: rfq.priority.label,
                background: rfq.priority.backgroundColor,
                border: rfq.priority.borderColor,
                foreground: rfq.priority.textColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Column(
              children: [
                _RfqMeta(label: 'Due', value: dueLabel),
                const SizedBox(height: 8),
                _RfqMeta(
                    label: 'Responses',
                    value: '${rfq.responses}/${rfq.invited}'),
                const SizedBox(height: 8),
                _RfqMeta(
                    label: 'Budget', value: currencyFormat.format(rfq.budget)),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _RfqMeta(label: 'Due', value: dueLabel)),
                Expanded(
                    child: _RfqMeta(
                        label: 'Responses',
                        value: '${rfq.responses}/${rfq.invited}')),
                Expanded(
                    child: _RfqMeta(
                        label: 'Budget',
                        value: currencyFormat.format(rfq.budget))),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vendor response progress',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
              Text(
                '${(responseRate * 100).round()}%',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: responseRate,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RfqMeta extends StatelessWidget {
  const _RfqMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _RfqStatusPill extends StatelessWidget {
  const _RfqStatusPill({required this.status});

  final _RfqStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.borderColor),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: status.textColor),
      ),
    );
  }
}

class _RfqSidebarCard extends StatelessWidget {
  const _RfqSidebarCard({required this.rfqs, required this.criteria});

  final List<_RfqItem> rfqs;
  final List<_RfqCriterion> criteria;

  @override
  Widget build(BuildContext context) {
    final upcoming = [...rfqs]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final topUpcoming = upcoming.take(3).toList();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Evaluation criteria',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              if (criteria.isEmpty)
                const Text(
                  'Define evaluation criteria once the RFQ scope is approved.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                )
              else
                for (var i = 0; i < criteria.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          criteria[i].label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937)),
                        ),
                      ),
                      Text(
                        '${(criteria[i].weight * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: criteria[i].weight,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB)),
                    ),
                  ),
                  if (i != criteria.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming deadlines',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              if (topUpcoming.isEmpty)
                const Text(
                  'Deadlines will surface once RFQs are created.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                )
              else
                for (var i = 0; i < topUpcoming.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topUpcoming[i].title,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937)),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d')
                            .format(DateTime.parse(topUpcoming[i].dueDate)),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  if (i != topUpcoming.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseOrdersView extends StatelessWidget {
  const _PurchaseOrdersView({
    super.key,
    required this.orders,
    required this.currencyFormat,
    required this.onCreatePo,
  });

  final List<_PurchaseOrder> orders;
  final NumberFormat currencyFormat;
  final VoidCallback onCreatePo;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final awaitingApproval = orders
        .where((order) => order.status == _PurchaseOrderStatus.awaitingApproval)
        .length;
    final inTransit = orders
        .where((order) => order.status == _PurchaseOrderStatus.inTransit)
        .length;
    final openOrders = orders
        .where((order) => order.status != _PurchaseOrderStatus.received)
        .length;
    final totalSpend = orders.fold<int>(0, (sum, order) => sum + order.amount);

    final metrics = [
      _SummaryCard(
        icon: Icons.receipt_long_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$openOrders',
        label: 'Open Orders',
      ),
      _SummaryCard(
        icon: Icons.approval_outlined,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$awaitingApproval',
        label: 'Awaiting Approval',
        valueColor: const Color(0xFFF97316),
      ),
      _SummaryCard(
        icon: Icons.local_shipping_outlined,
        iconBackground: const Color(0xFFF1F5F9),
        value: '$inTransit',
        label: 'In Transit',
      ),
      _SummaryCard(
        icon: Icons.attach_money,
        iconBackground: const Color(0xFFECFEFF),
        value: currencyFormat.format(totalSpend),
        label: 'Total Spend',
        valueColor: const Color(0xFF047857),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Purchase Orders',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: onCreatePo,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create PO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              metrics[0],
              const SizedBox(height: 12),
              metrics[1],
              const SizedBox(height: 12),
              metrics[2],
              const SizedBox(height: 12),
              metrics[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (orders.isEmpty)
          _EmptyStateCard(
            icon: Icons.receipt_long_outlined,
            title: 'No purchase orders yet',
            message: 'Create a PO to track approvals, shipments, and invoices.',
            actionLabel: 'Create PO',
            onAction: onCreatePo,
          )
        else if (isMobile)
          Column(
            children: [
              for (var i = 0; i < orders.length; i++) ...[
                _PurchaseOrderCard(
                    order: orders[i], currencyFormat: currencyFormat),
                if (i != orders.length - 1) const SizedBox(height: 12),
              ],
            ],
          )
        else
          _PurchaseOrderTable(
              orders: orders,
              currencyFormat: currencyFormat,
              onCreatePo: onCreatePo),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _ApprovalQueueCard(orders: orders),
              const SizedBox(height: 16),
              _InvoiceMatchCard(orders: orders),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _ApprovalQueueCard(orders: orders)),
              const SizedBox(width: 16),
              Expanded(child: _InvoiceMatchCard(orders: orders)),
            ],
          ),
      ],
    );
  }
}

class _PurchaseOrderTable extends StatelessWidget {
  const _PurchaseOrderTable(
      {required this.orders,
      required this.currencyFormat,
      required this.onCreatePo});

  final List<_PurchaseOrder> orders;
  final NumberFormat currencyFormat;
  final VoidCallback onCreatePo;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyStateCard(
        icon: Icons.receipt_long_outlined,
        title: 'No purchase orders yet',
        message: 'Create a PO to track approvals, shipments, and invoices.',
        actionLabel: 'Create PO',
        onAction: onCreatePo,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: _PurchaseOrderHeaderRow(),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  for (var i = 0; i < orders.length; i++) ...[
                    _PurchaseOrderRow(
                        order: orders[i], currencyFormat: currencyFormat),
                    if (i != orders.length - 1)
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PurchaseOrderHeaderRow extends StatelessWidget {
  const _PurchaseOrderHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _HeaderCell(label: 'PO', flex: 2),
        _HeaderCell(label: 'Vendor', flex: 3),
        _HeaderCell(label: 'Category', flex: 2),
        _HeaderCell(label: 'Status', flex: 2),
        _HeaderCell(label: 'Amount', flex: 2),
        _HeaderCell(label: 'Expected', flex: 2),
        _HeaderCell(label: 'Progress', flex: 2),
        _HeaderCell(label: 'Actions', flex: 2, alignEnd: true),
      ],
    );
  }
}

class _PurchaseOrderRow extends StatelessWidget {
  const _PurchaseOrderRow({required this.order, required this.currencyFormat});

  final _PurchaseOrder order;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final expectedLabel =
        DateFormat('M/d/yyyy').format(DateTime.parse(order.expectedDate));
    final progressLabel = '${(order.progress * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(order.id,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A))),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.vendor,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('Owner ${order.owner}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(order.category,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _PurchaseOrderStatusPill(status: order.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(currencyFormat.format(order.amount),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A))),
          ),
          Expanded(
              flex: 2,
              child: Text(expectedLabel,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(progressLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: order.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                _ActionIcon(icon: Icons.visibility_outlined),
                SizedBox(width: 8),
                _ActionIcon(icon: Icons.more_horiz_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({required this.order, required this.currencyFormat});

  final _PurchaseOrder order;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final expectedLabel =
        DateFormat('M/d/yyyy').format(DateTime.parse(order.expectedDate));
    final progressLabel = '${(order.progress * 100).round()}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.id,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
              ),
              _PurchaseOrderStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.vendor,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text(order.category,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _RfqMeta(label: 'Expected', value: expectedLabel)),
              Expanded(
                  child: _RfqMeta(
                      label: 'Amount',
                      value: currencyFormat.format(order.amount))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _RfqMeta(label: 'Progress', value: progressLabel)),
              Expanded(child: _RfqMeta(label: 'Owner', value: order.owner)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: order.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderStatusPill extends StatelessWidget {
  const _PurchaseOrderStatusPill({required this.status});

  final _PurchaseOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.borderColor),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: status.textColor),
      ),
    );
  }
}

class _ApprovalQueueCard extends StatelessWidget {
  const _ApprovalQueueCard({required this.orders});

  final List<_PurchaseOrder> orders;

  @override
  Widget build(BuildContext context) {
    final approvals = orders
        .where((order) => order.status == _PurchaseOrderStatus.awaitingApproval)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approval queue',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          if (approvals.isEmpty)
            const Text('No approvals pending.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
          else
            for (var i = 0; i < approvals.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${approvals[i].id} · ${approvals[i].vendor}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937)),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d')
                        .format(DateTime.parse(approvals[i].orderedDate)),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              if (i != approvals.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _InvoiceMatchCard extends StatelessWidget {
  const _InvoiceMatchCard({required this.orders});

  final List<_PurchaseOrder> orders;

  @override
  Widget build(BuildContext context) {
    final completed = orders
        .where((order) => order.status == _PurchaseOrderStatus.received)
        .toList();
    final inProgress = orders
        .where((order) => order.status == _PurchaseOrderStatus.inTransit)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice matching',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Text(
            'Completed matches: ${completed.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Text(
            'In progress: ${inProgress.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open match workspace'),
          ),
        ],
      ),
    );
  }
}

class _ItemTrackingView extends StatelessWidget {
  const _ItemTrackingView({
    super.key,
    required this.trackableItems,
    required this.selectedIndex,
    required this.onSelectTrackable,
    required this.selectedItem,
    required this.alerts,
    required this.carriers,
  });

  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;
  final _TrackableItem? selectedItem;
  final List<_TrackingAlert> alerts;
  final List<_CarrierPerformance> carriers;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final inTransit = trackableItems
        .where((item) => item.currentStatus == _TrackableStatus.inTransit)
        .length;
    final delivered = trackableItems
        .where((item) => item.currentStatus == _TrackableStatus.delivered)
        .length;
    final highAlerts =
        alerts.where((alert) => alert.severity == _AlertSeverity.high).length;
    final onTimeRate = carriers.isEmpty
        ? 0
        : (carriers.fold<int>(0, (sum, carrier) => sum + carrier.onTimeRate) /
                carriers.length)
            .round();

    final metrics = [
      _SummaryCard(
        icon: Icons.local_shipping_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$inTransit',
        label: 'In Transit',
      ),
      _SummaryCard(
        icon: Icons.check_circle_outline,
        iconBackground: const Color(0xFFE8FFF4),
        value: '$delivered',
        label: 'Delivered',
        valueColor: const Color(0xFF047857),
      ),
      _SummaryCard(
        icon: Icons.warning_amber_rounded,
        iconBackground: const Color(0xFFFFF1F2),
        value: '$highAlerts',
        label: 'High Priority Alerts',
        valueColor: const Color(0xFFDC2626),
      ),
      _SummaryCard(
        icon: Icons.track_changes_outlined,
        iconBackground: const Color(0xFFF1F5F9),
        value: '$onTimeRate%',
        label: 'On-time Rate',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Item Tracking',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Update Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              metrics[0],
              const SizedBox(height: 12),
              metrics[1],
              const SizedBox(height: 12),
              metrics[2],
              const SizedBox(height: 12),
              metrics[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _TrackableItemsCard(
                trackableItems: trackableItems,
                selectedIndex: selectedIndex,
                onSelectTrackable: onSelectTrackable,
              ),
              const SizedBox(height: 16),
              _TrackingTimelineCard(item: selectedItem),
              const SizedBox(height: 16),
              _TrackingAlertsCard(alerts: alerts),
              const SizedBox(height: 16),
              _CarrierPerformanceCard(carriers: carriers),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _TrackableItemsCard(
                      trackableItems: trackableItems,
                      selectedIndex: selectedIndex,
                      onSelectTrackable: onSelectTrackable,
                    ),
                    const SizedBox(height: 16),
                    _TrackingAlertsCard(alerts: alerts),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _TrackingTimelineCard(item: selectedItem),
                    const SizedBox(height: 16),
                    _CarrierPerformanceCard(carriers: carriers),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TrackingAlertsCard extends StatelessWidget {
  const _TrackingAlertsCard({required this.alerts});

  final List<_TrackingAlert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.warning_amber_rounded,
        title: 'Logistics alerts',
        message: 'Alerts will surface once shipments are in motion.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logistics alerts',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < alerts.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerts[i].title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alerts[i].description,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('M/d')
                            .format(DateTime.parse(alerts[i].date)),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AlertSeverityPill(severity: alerts[i].severity),
              ],
            ),
            if (i != alerts.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AlertSeverityPill extends StatelessWidget {
  const _AlertSeverityPill({required this.severity});

  final _AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: severity.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: severity.borderColor),
      ),
      child: Text(
        severity.label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: severity.textColor),
      ),
    );
  }
}

class _CarrierPerformanceCard extends StatelessWidget {
  const _CarrierPerformanceCard({required this.carriers});

  final List<_CarrierPerformance> carriers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carrier performance',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < carriers.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    carriers[i].carrier,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${carriers[i].onTimeRate}%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Text(
                  '${carriers[i].avgDays}d avg',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: carriers[i].onTimeRate / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            if (i != carriers.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView({
    super.key,
    required this.kpis,
    required this.spendBreakdown,
    required this.leadTimeMetrics,
    required this.savingsOpportunities,
    required this.complianceMetrics,
    required this.currencyFormat,
  });

  final List<_ReportKpi> kpis;
  final List<_SpendBreakdown> spendBreakdown;
  final List<_LeadTimeMetric> leadTimeMetrics;
  final List<_SavingsOpportunity> savingsOpportunities;
  final List<_ComplianceMetric> complianceMetrics;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final hasData = kpis.isNotEmpty ||
        spendBreakdown.isNotEmpty ||
        leadTimeMetrics.isNotEmpty ||
        savingsOpportunities.isNotEmpty ||
        complianceMetrics.isNotEmpty;

    if (!hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Procurement Reports',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A)),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Share'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _EmptyStateCard(
            icon: Icons.insert_chart_outlined,
            title: 'No report data yet',
            message:
                'Reports will populate as procurement activity is recorded.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Procurement Reports',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Share'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              for (var i = 0; i < kpis.length; i++) ...[
                _ReportKpiCard(kpi: kpis[i]),
                if (i != kpis.length - 1) const SizedBox(height: 12),
              ],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < kpis.length; i++) ...[
                Expanded(child: _ReportKpiCard(kpi: kpis[i])),
                if (i != kpis.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _SpendBreakdownCard(
                  breakdown: spendBreakdown, currencyFormat: currencyFormat),
              const SizedBox(height: 16),
              _LeadTimePerformanceCard(metrics: leadTimeMetrics),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                  child: _SpendBreakdownCard(
                      breakdown: spendBreakdown,
                      currencyFormat: currencyFormat)),
              const SizedBox(width: 16),
              Expanded(
                  child: _LeadTimePerformanceCard(metrics: leadTimeMetrics)),
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _SavingsOpportunitiesCard(items: savingsOpportunities),
              const SizedBox(height: 16),
              _ComplianceSnapshotCard(metrics: complianceMetrics),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                  child:
                      _SavingsOpportunitiesCard(items: savingsOpportunities)),
              const SizedBox(width: 16),
              Expanded(
                  child: _ComplianceSnapshotCard(metrics: complianceMetrics)),
            ],
          ),
      ],
    );
  }
}

class _ReportKpiCard extends StatelessWidget {
  const _ReportKpiCard({required this.kpi});

  final _ReportKpi kpi;

  @override
  Widget build(BuildContext context) {
    final Color deltaColor =
        kpi.positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData deltaIcon = kpi.positive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kpi.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(kpi.value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(deltaIcon, size: 16, color: deltaColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kpi.delta,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: deltaColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendBreakdownCard extends StatelessWidget {
  const _SpendBreakdownCard(
      {required this.breakdown, required this.currencyFormat});

  final List<_SpendBreakdown> breakdown;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.pie_chart_outline,
        title: 'Spend by category',
        message: 'Category spend will appear after items and POs are logged.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spend by category',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < breakdown.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    breakdown[i].label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  currencyFormat.format(breakdown[i].amount),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: constraints.maxWidth * breakdown[i].percent,
                      decoration: BoxDecoration(
                        color: breakdown[i].color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (i != breakdown.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LeadTimePerformanceCard extends StatelessWidget {
  const _LeadTimePerformanceCard({required this.metrics});

  final List<_LeadTimeMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.schedule_outlined,
        title: 'Lead time performance',
        message: 'Lead time data will appear once deliveries are tracked.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lead time performance',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < metrics.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrics[i].label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${(metrics[i].onTimeRate * 100).round()}%',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: metrics[i].onTimeRate,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            if (i != metrics.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SavingsOpportunitiesCard extends StatelessWidget {
  const _SavingsOpportunitiesCard({required this.items});

  final List<_SavingsOpportunity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.savings_outlined,
        title: 'Savings opportunities',
        message: 'Savings will appear as sourcing insights are captured.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Savings opportunities',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner ${items[i].owner}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text(
                  items[i].value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A)),
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ComplianceSnapshotCard extends StatelessWidget {
  const _ComplianceSnapshotCard({required this.metrics});

  final List<_ComplianceMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.verified_outlined,
        title: 'Compliance snapshot',
        message:
            'Compliance tracking appears after vendors and orders are recorded.',
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compliance snapshot',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < metrics.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrics[i].label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${(metrics[i].value * 100).round()}%',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: metrics[i].value,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            if (i != metrics.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ProcurementDialogShell extends StatelessWidget {
  const _ProcurementDialogShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.contextChips,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> contextChips;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: 720, maxHeight: media.size.height * 0.88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1F0F172A),
                blurRadius: 30,
                offset: Offset(0, 18)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFF), Color(0xFFEFF6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE).withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x140F172A),
                                blurRadius: 10,
                                offset: Offset(0, 6)),
                          ],
                        ),
                        child: Icon(icon, color: const Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF475569)),
                            ),
                            if (contextChips.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: contextChips,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onSecondary,
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: child,
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                children: [
                  const Text(
                    'Saved to this workspace only.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(primaryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogSectionTitle extends StatelessWidget {
  const _DialogSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

class _EmptyStateBody extends StatelessWidget {
  const _EmptyStateBody({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 40 : 52;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon,
              color: const Color(0xFF2563EB), size: compact ? 20 : 24),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      padding:
          EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 24 : 32),
      child: _EmptyStateBody(
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        compact: compact,
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          const Text(
            'This section is under construction. Check back soon for the interactive experience.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

enum _ProcurementTab {
  procurementDashboard,
  itemsList,
  vendorManagement,
  rfqWorkflow,
  purchaseOrders,
  itemTracking,
  reports
}

extension _ProcurementTabExtension on _ProcurementTab {
  String get label {
    switch (this) {
      case _ProcurementTab.procurementDashboard:
        return 'Procurement Dashboard';
      case _ProcurementTab.itemsList:
        return 'Items List';
      case _ProcurementTab.vendorManagement:
        return 'Vendor Management';
      case _ProcurementTab.rfqWorkflow:
        return 'RFQ Workflow';
      case _ProcurementTab.purchaseOrders:
        return 'Purchase Orders';
      case _ProcurementTab.itemTracking:
        return 'Item Tracking';
      case _ProcurementTab.reports:
        return 'Reports';
    }
  }

  String get title {
    switch (this) {
      case _ProcurementTab.procurementDashboard:
        return 'Procurement Dashboard';
      case _ProcurementTab.itemsList:
        return 'Items List';
      case _ProcurementTab.vendorManagement:
        return 'Vendor Management';
      case _ProcurementTab.rfqWorkflow:
        return 'RFQ Workflow';
      case _ProcurementTab.purchaseOrders:
        return 'Purchase Orders';
      case _ProcurementTab.itemTracking:
        return 'Item Tracking';
      case _ProcurementTab.reports:
        return 'Reports';
    }
  }
}

class _ProcurementItem {
  const _ProcurementItem({
    required this.name,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.budget,
    required this.estimatedDelivery,
    required this.progress,
  });

  final String name;
  final String description;
  final String category;
  final _ProcurementItemStatus status;
  final _ProcurementPriority priority;
  final int budget;
  final String estimatedDelivery;
  final double progress;

  Color get progressColor {
    if (progress >= 1.0) return const Color(0xFF10B981);
    if (progress >= 0.5) return const Color(0xFF2563EB);
    if (progress == 0) return const Color(0xFFD1D5DB);
    return const Color(0xFF38BDF8);
  }
}

enum _ProcurementItemStatus {
  planning,
  rfqReview,
  vendorSelection,
  ordered,
  delivered
}

extension _ProcurementItemStatusExtension on _ProcurementItemStatus {
  String get label {
    switch (this) {
      case _ProcurementItemStatus.planning:
        return 'planning';
      case _ProcurementItemStatus.rfqReview:
        return 'rfq review';
      case _ProcurementItemStatus.vendorSelection:
        return 'vendor selection';
      case _ProcurementItemStatus.ordered:
        return 'ordered';
      case _ProcurementItemStatus.delivered:
        return 'delivered';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _ProcurementItemStatus.planning:
        return const Color(0xFFEFF6FF);
      case _ProcurementItemStatus.rfqReview:
        return const Color(0xFFFFF7ED);
      case _ProcurementItemStatus.vendorSelection:
        return const Color(0xFFEFF6FF);
      case _ProcurementItemStatus.ordered:
        return const Color(0xFFF1F5F9);
      case _ProcurementItemStatus.delivered:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _ProcurementItemStatus.planning:
        return const Color(0xFF2563EB);
      case _ProcurementItemStatus.rfqReview:
        return const Color(0xFFEA580C);
      case _ProcurementItemStatus.vendorSelection:
        return const Color(0xFF2563EB);
      case _ProcurementItemStatus.ordered:
        return const Color(0xFF1F2937);
      case _ProcurementItemStatus.delivered:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _ProcurementItemStatus.planning:
      case _ProcurementItemStatus.vendorSelection:
        return const Color(0xFFBFDBFE);
      case _ProcurementItemStatus.rfqReview:
        return const Color(0xFFFECF8F);
      case _ProcurementItemStatus.ordered:
        return const Color(0xFFE2E8F0);
      case _ProcurementItemStatus.delivered:
        return const Color(0xFFBBF7D0);
    }
  }
}

enum _ProcurementPriority { critical, high, medium, low }

extension _ProcurementPriorityExtension on _ProcurementPriority {
  String get label {
    switch (this) {
      case _ProcurementPriority.critical:
        return 'critical';
      case _ProcurementPriority.high:
        return 'high';
      case _ProcurementPriority.medium:
        return 'medium';
      case _ProcurementPriority.low:
        return 'low';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _ProcurementPriority.critical:
        return const Color(0xFFFFF1F2);
      case _ProcurementPriority.high:
        return const Color(0xFFEFF6FF);
      case _ProcurementPriority.medium:
        return const Color(0xFFF8FAFC);
      case _ProcurementPriority.low:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get textColor {
    switch (this) {
      case _ProcurementPriority.critical:
        return const Color(0xFFDC2626);
      case _ProcurementPriority.high:
        return const Color(0xFF1D4ED8);
      case _ProcurementPriority.medium:
        return const Color(0xFF475569);
      case _ProcurementPriority.low:
        return const Color(0xFF4B5563);
    }
  }

  Color get borderColor {
    switch (this) {
      case _ProcurementPriority.critical:
        return const Color(0xFFFECACA);
      case _ProcurementPriority.high:
        return const Color(0xFFBFDBFE);
      case _ProcurementPriority.medium:
        return const Color(0xFFE2E8F0);
      case _ProcurementPriority.low:
        return const Color(0xFFE2E8F0);
    }
  }
}

class _TrackableItem {
  const _TrackableItem({
    required this.name,
    required this.description,
    required this.orderStatus,
    required this.currentStatus,
    required this.lastUpdate,
    required this.events,
  });

  final String name;
  final String description;
  final String orderStatus;
  final _TrackableStatus currentStatus;
  final String? lastUpdate;
  final List<_TimelineEvent> events;
}

enum _TrackableStatus { inTransit, notTracked, delivered }

extension _TrackableStatusExtension on _TrackableStatus {
  String get label {
    switch (this) {
      case _TrackableStatus.inTransit:
        return 'in transit';
      case _TrackableStatus.notTracked:
        return 'Not Tracked';
      case _TrackableStatus.delivered:
        return 'delivered';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _TrackableStatus.inTransit:
        return const Color(0xFFEFF6FF);
      case _TrackableStatus.notTracked:
        return const Color(0xFFF1F5F9);
      case _TrackableStatus.delivered:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _TrackableStatus.inTransit:
        return const Color(0xFF2563EB);
      case _TrackableStatus.notTracked:
        return const Color(0xFF475569);
      case _TrackableStatus.delivered:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _TrackableStatus.inTransit:
        return const Color(0xFFBFDBFE);
      case _TrackableStatus.notTracked:
        return const Color(0xFFE2E8F0);
      case _TrackableStatus.delivered:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.title,
    required this.description,
    required this.subtext,
    required this.date,
  });

  final String title;
  final String description;
  final String subtext;
  final String date;
}

class _ProcurementStrategy {
  const _ProcurementStrategy({
    required this.title,
    required this.status,
    required this.itemCount,
    required this.description,
  });

  final String title;
  final _StrategyStatus status;
  final int itemCount;
  final String description;
}

enum _StrategyStatus { active, draft }

class _VendorRow {
  const _VendorRow({
    required this.id,
    required this.initials,
    required this.name,
    required this.category,
    required this.rating,
    required this.approved,
    required this.preferred,
  });

  final String id;
  final String initials;
  final String name;
  final String category;
  final int rating;
  final bool approved;
  final bool preferred;

  _VendorRow copyWith({
    String? id,
    String? initials,
    String? name,
    String? category,
    int? rating,
    bool? approved,
    bool? preferred,
  }) {
    return _VendorRow(
      id: id ?? this.id,
      initials: initials ?? this.initials,
      name: name ?? this.name,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      approved: approved ?? this.approved,
      preferred: preferred ?? this.preferred,
    );
  }
}

class _VendorHealthMetric {
  const _VendorHealthMetric(
      {required this.category, required this.score, required this.change});

  final String category;
  final double score;
  final String change;
}

class _VendorOnboardingTask {
  const _VendorOnboardingTask({
    required this.title,
    required this.owner,
    required this.dueDate,
    required this.status,
  });

  final String title;
  final String owner;
  final String dueDate;
  final _VendorTaskStatus status;
}

enum _VendorTaskStatus { pending, inReview, complete }

extension _VendorTaskStatusExtension on _VendorTaskStatus {
  String get label {
    switch (this) {
      case _VendorTaskStatus.pending:
        return 'pending';
      case _VendorTaskStatus.inReview:
        return 'in review';
      case _VendorTaskStatus.complete:
        return 'complete';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _VendorTaskStatus.pending:
        return const Color(0xFFF1F5F9);
      case _VendorTaskStatus.inReview:
        return const Color(0xFFFFF7ED);
      case _VendorTaskStatus.complete:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _VendorTaskStatus.pending:
        return const Color(0xFF64748B);
      case _VendorTaskStatus.inReview:
        return const Color(0xFFF97316);
      case _VendorTaskStatus.complete:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _VendorTaskStatus.pending:
        return const Color(0xFFE2E8F0);
      case _VendorTaskStatus.inReview:
        return const Color(0xFFFED7AA);
      case _VendorTaskStatus.complete:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _VendorRiskItem {
  const _VendorRiskItem({
    required this.vendor,
    required this.risk,
    required this.severity,
    required this.lastIncident,
  });

  final String vendor;
  final String risk;
  final _RiskSeverity severity;
  final String lastIncident;
}

enum _RiskSeverity { low, medium, high }

extension _RiskSeverityExtension on _RiskSeverity {
  String get label {
    switch (this) {
      case _RiskSeverity.low:
        return 'low';
      case _RiskSeverity.medium:
        return 'medium';
      case _RiskSeverity.high:
        return 'high';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _RiskSeverity.low:
        return const Color(0xFFF1F5F9);
      case _RiskSeverity.medium:
        return const Color(0xFFFFF7ED);
      case _RiskSeverity.high:
        return const Color(0xFFFFF1F2);
    }
  }

  Color get textColor {
    switch (this) {
      case _RiskSeverity.low:
        return const Color(0xFF64748B);
      case _RiskSeverity.medium:
        return const Color(0xFFF97316);
      case _RiskSeverity.high:
        return const Color(0xFFDC2626);
    }
  }

  Color get borderColor {
    switch (this) {
      case _RiskSeverity.low:
        return const Color(0xFFE2E8F0);
      case _RiskSeverity.medium:
        return const Color(0xFFFED7AA);
      case _RiskSeverity.high:
        return const Color(0xFFFECACA);
    }
  }
}

class _RfqItem {
  const _RfqItem({
    required this.title,
    required this.category,
    required this.owner,
    required this.dueDate,
    required this.invited,
    required this.responses,
    required this.budget,
    required this.status,
    required this.priority,
  });

  final String title;
  final String category;
  final String owner;
  final String dueDate;
  final int invited;
  final int responses;
  final int budget;
  final _RfqStatus status;
  final _ProcurementPriority priority;
}

enum _RfqStatus { draft, review, inMarket, evaluation, awarded }

extension _RfqStatusExtension on _RfqStatus {
  String get label {
    switch (this) {
      case _RfqStatus.draft:
        return 'draft';
      case _RfqStatus.review:
        return 'review';
      case _RfqStatus.inMarket:
        return 'in market';
      case _RfqStatus.evaluation:
        return 'evaluation';
      case _RfqStatus.awarded:
        return 'awarded';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _RfqStatus.draft:
        return const Color(0xFFF1F5F9);
      case _RfqStatus.review:
        return const Color(0xFFFFF7ED);
      case _RfqStatus.inMarket:
        return const Color(0xFFEFF6FF);
      case _RfqStatus.evaluation:
        return const Color(0xFFF5F3FF);
      case _RfqStatus.awarded:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _RfqStatus.draft:
        return const Color(0xFF64748B);
      case _RfqStatus.review:
        return const Color(0xFFF97316);
      case _RfqStatus.inMarket:
        return const Color(0xFF2563EB);
      case _RfqStatus.evaluation:
        return const Color(0xFF6D28D9);
      case _RfqStatus.awarded:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _RfqStatus.draft:
        return const Color(0xFFE2E8F0);
      case _RfqStatus.review:
        return const Color(0xFFFED7AA);
      case _RfqStatus.inMarket:
        return const Color(0xFFBFDBFE);
      case _RfqStatus.evaluation:
        return const Color(0xFFE9D5FF);
      case _RfqStatus.awarded:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _RfqStage {
  const _RfqStage(
      {required this.title, required this.subtitle, required this.status});

  final String title;
  final String subtitle;
  final _WorkflowStageStatus status;
}

enum _WorkflowStageStatus { complete, active, upcoming }

extension _WorkflowStageStatusExtension on _WorkflowStageStatus {
  Color get backgroundColor {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return const Color(0xFFE8FFF4);
      case _WorkflowStageStatus.active:
        return const Color(0xFFEFF6FF);
      case _WorkflowStageStatus.upcoming:
        return const Color(0xFFF8FAFC);
    }
  }

  Color get borderColor {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return const Color(0xFFBBF7D0);
      case _WorkflowStageStatus.active:
        return const Color(0xFFBFDBFE);
      case _WorkflowStageStatus.upcoming:
        return const Color(0xFFE2E8F0);
    }
  }

  Color get iconColor {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return const Color(0xFF047857);
      case _WorkflowStageStatus.active:
        return const Color(0xFF2563EB);
      case _WorkflowStageStatus.upcoming:
        return const Color(0xFF64748B);
    }
  }

  IconData get icon {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return Icons.check_circle_rounded;
      case _WorkflowStageStatus.active:
        return Icons.radio_button_checked_rounded;
      case _WorkflowStageStatus.upcoming:
        return Icons.radio_button_unchecked_rounded;
    }
  }
}

class _RfqCriterion {
  const _RfqCriterion({required this.label, required this.weight});

  final String label;
  final double weight;
}

class _PurchaseOrder {
  const _PurchaseOrder({
    required this.id,
    required this.vendor,
    required this.category,
    required this.owner,
    required this.orderedDate,
    required this.expectedDate,
    required this.amount,
    required this.progress,
    required this.status,
  });

  final String id;
  final String vendor;
  final String category;
  final String owner;
  final String orderedDate;
  final String expectedDate;
  final int amount;
  final double progress;
  final _PurchaseOrderStatus status;
}

enum _PurchaseOrderStatus { awaitingApproval, issued, inTransit, received }

extension _PurchaseOrderStatusExtension on _PurchaseOrderStatus {
  String get label {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return 'awaiting approval';
      case _PurchaseOrderStatus.issued:
        return 'issued';
      case _PurchaseOrderStatus.inTransit:
        return 'in transit';
      case _PurchaseOrderStatus.received:
        return 'received';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return const Color(0xFFFFF7ED);
      case _PurchaseOrderStatus.issued:
        return const Color(0xFFEFF6FF);
      case _PurchaseOrderStatus.inTransit:
        return const Color(0xFFF5F3FF);
      case _PurchaseOrderStatus.received:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return const Color(0xFFF97316);
      case _PurchaseOrderStatus.issued:
        return const Color(0xFF2563EB);
      case _PurchaseOrderStatus.inTransit:
        return const Color(0xFF6D28D9);
      case _PurchaseOrderStatus.received:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return const Color(0xFFFED7AA);
      case _PurchaseOrderStatus.issued:
        return const Color(0xFFBFDBFE);
      case _PurchaseOrderStatus.inTransit:
        return const Color(0xFFE9D5FF);
      case _PurchaseOrderStatus.received:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _TrackingAlert {
  const _TrackingAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.date,
  });

  final String title;
  final String description;
  final _AlertSeverity severity;
  final String date;
}

enum _AlertSeverity { low, medium, high }

extension _AlertSeverityExtension on _AlertSeverity {
  String get label {
    switch (this) {
      case _AlertSeverity.low:
        return 'low';
      case _AlertSeverity.medium:
        return 'medium';
      case _AlertSeverity.high:
        return 'high';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _AlertSeverity.low:
        return const Color(0xFFF1F5F9);
      case _AlertSeverity.medium:
        return const Color(0xFFFFF7ED);
      case _AlertSeverity.high:
        return const Color(0xFFFFF1F2);
    }
  }

  Color get textColor {
    switch (this) {
      case _AlertSeverity.low:
        return const Color(0xFF64748B);
      case _AlertSeverity.medium:
        return const Color(0xFFF97316);
      case _AlertSeverity.high:
        return const Color(0xFFDC2626);
    }
  }

  Color get borderColor {
    switch (this) {
      case _AlertSeverity.low:
        return const Color(0xFFE2E8F0);
      case _AlertSeverity.medium:
        return const Color(0xFFFED7AA);
      case _AlertSeverity.high:
        return const Color(0xFFFECACA);
    }
  }
}

class _CarrierPerformance {
  const _CarrierPerformance(
      {required this.carrier, required this.onTimeRate, required this.avgDays});

  final String carrier;
  final int onTimeRate;
  final int avgDays;
}

class _ReportKpi {
  const _ReportKpi(
      {required this.label,
      required this.value,
      required this.delta,
      required this.positive});

  final String label;
  final String value;
  final String delta;
  final bool positive;
}

class _SpendBreakdown {
  const _SpendBreakdown({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  final String label;
  final int amount;
  final double percent;
  final Color color;
}

class _LeadTimeMetric {
  const _LeadTimeMetric({required this.label, required this.onTimeRate});

  final String label;
  final double onTimeRate;
}

class _SavingsOpportunity {
  const _SavingsOpportunity(
      {required this.title, required this.value, required this.owner});

  final String title;
  final String value;
  final String owner;
}

class _ComplianceMetric {
  const _ComplianceMetric({required this.label, required this.value});

  final String label;
  final double value;
}

class _AddVendorDialog extends StatefulWidget {
  const _AddVendorDialog({
    required this.contextChips,
    required this.categoryOptions,
    this.initialVendor,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;
  final _VendorRow? initialVendor;

  @override
  State<_AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends State<_AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late String _category;
  double _rating = 4;
  bool _approved = true;
  bool _preferred = false;
  bool _isGenerating = false;

  final FocusNode _nameFocus = FocusNode();
  late final OpenAiServiceSecure _openAi;
  bool get _isEditing => widget.initialVendor != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.initialVendor?.name ?? '');
    _category = widget.initialVendor?.category ??
        widget.categoryOptions.first;
    _rating = (widget.initialVendor?.rating ?? 4).toDouble();
    _approved = widget.initialVendor?.approved ?? true;
    _preferred = widget.initialVendor?.preferred ?? false;
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();

    // SAFE FOCUS REQUEST: Wait for frame to be attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String _deriveInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _generateWithAI() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final projectData = ProjectDataHelper.getData(context);
      final projectName = projectData.projectName.trim().isEmpty
          ? 'Project'
          : projectData.projectName.trim();
      final solutionTitle = projectData.solutionTitle.trim().isEmpty
          ? 'Solution'
          : projectData.solutionTitle.trim();
      final notes = projectData.frontEndPlanning.procurement.trim();

      final result = await _openAi.generateVendorSuggestion(
        projectName: projectName,
        solutionTitle: solutionTitle,
        category: _category,
        contextNotes: notes,
      );

      if (mounted) {
        setState(() {
          _nameCtrl.text = result['name'] ?? '';
          _category = result['category'] ?? _category;
          _rating = (result['rating'] as int? ?? 4).toDouble();
          _approved = result['approved'] as bool? ?? true;
          _preferred = result['preferred'] as bool? ?? false;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate vendor: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildDecoration(Widget child,
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? errorText}) {
    return InputDecorator(
      decoration: _dialogDecoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
        errorText: errorText,
      ),
      child: child,
    );
  }

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? helperText,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = widget.categoryOptions.contains(_category)
        ? widget.categoryOptions
        : [_category, ...widget.categoryOptions];
    return _ProcurementDialogShell(
      title: _isEditing ? 'Edit Vendor' : 'Add Vendor Partner',
      subtitle: _isEditing
          ? 'Update vendor details and qualification.'
          : 'Build your trusted supplier network.',
      icon: Icons.storefront_outlined,
      contextChips: widget.contextChips,
      primaryLabel: _isEditing ? 'Save Changes' : 'Add Vendor',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        final name = _nameCtrl.text.trim();
        final vendorId = widget.initialVendor?.id ??
            'vendor_${DateTime.now().microsecondsSinceEpoch}';
        final vendor = _VendorRow(
          id: vendorId,
          initials: _deriveInitials(name),
          name: name,
          category: _category,
          rating: _rating.round().clamp(1, 5).toInt(),
          approved: _approved,
          preferred: _preferred,
        );
        Navigator.of(context).pop(vendor);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: _DialogSectionTitle(
                    title: 'Vendor identity',
                    subtitle: 'Capture the partner name and sourcing category.',
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _generateWithAI,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate with AI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              decoration: _dialogDecoration(
                  label: 'Vendor name', hint: 'e.g. Atlas Tech Supply'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Vendor name is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _dialogDecoration(label: 'Category'),
              items: categoryOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
              },
            ),
            const SizedBox(height: 18),
            const _DialogSectionTitle(
              title: 'Qualification',
              subtitle: 'Define rating and approval status.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rating',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569))),
                      Slider(
                        value: _rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _rating.round().toString(),
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (value) => setState(() => _rating = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _approved,
                          activeThumbColor: const Color(0xFF2563EB),
                          onChanged: (value) =>
                              setState(() => _approved = value),
                        ),
                        const Text('Approved'),
                      ],
                    ),
                    Row(
                      children: [
                        Switch(
                          value: _preferred,
                          activeThumbColor: const Color(0xFF2563EB),
                          onChanged: (value) =>
                              setState(() => _preferred = value),
                        ),
                        const Text('Preferred'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog({
    required this.contextChips,
    required this.categoryOptions,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _budgetCtrl;

  late String _category;
  _ProcurementItemStatus _status = _ProcurementItemStatus.planning;
  _ProcurementPriority _priority = _ProcurementPriority.medium;
  DateTime? _deliveryDate;
  bool _showDateError = false;
  bool _isGenerating = false;

  final FocusNode _nameFocus = FocusNode();
  late final OpenAiServiceSecure _openAi;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _budgetCtrl = TextEditingController();
    _category = widget.categoryOptions.first;
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();

    // SAFE FOCUS REQUEST
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatStoreDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
  String _formatDisplayDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  Future<void> _generateWithAI() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final projectData = ProjectDataHelper.getData(context);
      final projectName = projectData.projectName.trim().isEmpty
          ? 'Project'
          : projectData.projectName.trim();
      final solutionTitle = projectData.solutionTitle.trim().isEmpty
          ? 'Solution'
          : projectData.solutionTitle.trim();
      final notes = projectData.frontEndPlanning.procurement.trim();

      final result = await _openAi.generateProcurementItemSuggestion(
        projectName: projectName,
        solutionTitle: solutionTitle,
        category: _category,
        contextNotes: notes,
      );

      if (mounted) {
        final deliveryDays = result['estimatedDeliveryDays'] as int? ?? 90;
        final deliveryDate = DateTime.now().add(Duration(days: deliveryDays));

        _ProcurementPriority priority;
        final priorityStr = result['priority'] as String? ?? 'medium';
        switch (priorityStr.toLowerCase()) {
          case 'critical':
            priority = _ProcurementPriority.critical;
            break;
          case 'high':
            priority = _ProcurementPriority.high;
            break;
          case 'low':
            priority = _ProcurementPriority.low;
            break;
          default:
            priority = _ProcurementPriority.medium;
        }

        setState(() {
          _nameCtrl.text = result['name'] ?? '';
          _descCtrl.text = result['description'] ?? '';
          _category = result['category'] ?? _category;
          _budgetCtrl.text = (result['budget'] as int? ?? 50000).toString();
          _priority = priority;
          _deliveryDate = deliveryDate;
          _showDateError = false;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate item: ${e.toString()}')),
        );
      }
    }
  }

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? helperText,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProcurementDialogShell(
      title: 'Add Procurement Item',
      subtitle: 'Capture scope, budget, and delivery timing.',
      icon: Icons.inventory_2_outlined,
      contextChips: widget.contextChips,
      primaryLabel: 'Add Item',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        if (_deliveryDate == null) {
          setState(() => _showDateError = true);
          return;
        }
        final budget = _parseCurrency(_budgetCtrl.text);
        final item = _ProcurementItem(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          status: _status,
          priority: _priority,
          budget: budget,
          estimatedDelivery: _formatStoreDate(_deliveryDate!),
          progress: 0,
        );
        Navigator.of(context).pop(item);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: _DialogSectionTitle(
                    title: 'Item details',
                    subtitle: 'What are you sourcing for this project?',
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _generateWithAI,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate with AI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              decoration: _dialogDecoration(
                  label: 'Item name', hint: 'e.g. Network core switches'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Item name is required.'
                  : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: _dialogDecoration(
                  label: 'Description', hint: 'Short scope description'),
            ),
            const SizedBox(height: 18),
            const _DialogSectionTitle(
              title: 'Classification',
              subtitle: 'Align the item with sourcing workflow.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _dialogDecoration(label: 'Category'),
                    items: widget.categoryOptions
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<_ProcurementItemStatus>(
                    initialValue: _status,
                    decoration: _dialogDecoration(label: 'Status'),
                    items: _ProcurementItemStatus.values
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _status = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_ProcurementPriority>(
              initialValue: _priority,
              decoration: _dialogDecoration(label: 'Priority'),
              items: _ProcurementPriority.values
                  .map((option) => DropdownMenuItem(
                      value: option, child: Text(option.label)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 18),
            const _DialogSectionTitle(
              title: 'Budget and timing',
              subtitle: 'Estimate cost and delivery window.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogDecoration(
                        label: 'Budget',
                        hint: 'e.g. 85000',
                        prefixIcon: const Icon(Icons.attach_money)),
                    validator: (value) {
                      final amount = _parseCurrency(value ?? '');
                      return amount <= 0 ? 'Enter a budget amount.' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _deliveryDate ??
                            DateTime.now().add(const Duration(days: 14)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() {
                        _deliveryDate = picked;
                        _showDateError = false;
                      });
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                        label: 'Est. delivery',
                        hint: 'Select date',
                        prefixIcon: const Icon(Icons.event),
                        errorText: _showDateError ? 'Select a date.' : null,
                      ),
                      child: Text(
                        _deliveryDate == null
                            ? 'Select date'
                            : _formatDisplayDate(_deliveryDate!),
                        style: TextStyle(
                          color: _deliveryDate == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateRfqDialog extends StatefulWidget {
  const _CreateRfqDialog({
    required this.contextChips,
    required this.categoryOptions,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;

  @override
  State<_CreateRfqDialog> createState() => _CreateRfqDialogState();
}

class _CreateRfqDialogState extends State<_CreateRfqDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _budgetCtrl;
  late TextEditingController _invitedCtrl;
  late TextEditingController _responsesCtrl;

  late String _category;
  _RfqStatus _status = _RfqStatus.draft;
  _ProcurementPriority _priority = _ProcurementPriority.medium;
  DateTime? _dueDate;
  bool _showDateError = false;

  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _ownerCtrl = TextEditingController();
    _budgetCtrl = TextEditingController();
    _invitedCtrl = TextEditingController(text: '0');
    _responsesCtrl = TextEditingController(text: '0');
    _category = widget.categoryOptions.first;

    // SAFE FOCUS REQUEST
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ownerCtrl.dispose();
    _budgetCtrl.dispose();
    _invitedCtrl.dispose();
    _responsesCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatStoreDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
  String _formatDisplayDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProcurementDialogShell(
      title: 'Create RFQ',
      subtitle: 'Kick off a request for quote with clear scope and timing.',
      icon: Icons.request_quote_outlined,
      contextChips: widget.contextChips,
      primaryLabel: 'Create RFQ',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        if (_dueDate == null) {
          setState(() => _showDateError = true);
          return;
        }
        final budget = _parseCurrency(_budgetCtrl.text);
        final invited = int.tryParse(_invitedCtrl.text.trim()) ?? 0;
        final responses = int.tryParse(_responsesCtrl.text.trim()) ?? 0;
        final rfq = _RfqItem(
          title: _titleCtrl.text.trim(),
          category: _category,
          owner: _ownerCtrl.text.trim().isEmpty
              ? 'Unassigned'
              : _ownerCtrl.text.trim(),
          budget: budget,
          dueDate: _formatStoreDate(_dueDate!),
          invited: invited,
          responses: responses.clamp(0, invited).toInt(),
          status: _status,
          priority: _priority,
        );
        Navigator.of(context).pop(rfq);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DialogSectionTitle(
              title: 'RFQ overview',
              subtitle: 'Define the category and owner.',
            ),
            TextFormField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              decoration: _dialogDecoration(
                  label: 'RFQ title',
                  hint: 'e.g. Network infrastructure upgrade'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'RFQ title is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _dialogDecoration(label: 'Category'),
                    items: widget.categoryOptions
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ownerCtrl,
                    decoration: _dialogDecoration(
                        label: 'Owner', hint: 'e.g. J. Patel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _DialogSectionTitle(
              title: 'Budget and schedule',
              subtitle: 'Set a due date and target budget.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogDecoration(
                        label: 'Budget',
                        hint: 'e.g. 120000',
                        prefixIcon: const Icon(Icons.attach_money)),
                    validator: (value) {
                      final amount = _parseCurrency(value ?? '');
                      return amount <= 0 ? 'Enter a budget amount.' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ??
                            DateTime.now().add(const Duration(days: 21)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() {
                        _dueDate = picked;
                        _showDateError = false;
                      });
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                        label: 'Due date',
                        hint: 'Select date',
                        prefixIcon: const Icon(Icons.event),
                        errorText: _showDateError ? 'Select a date.' : null,
                      ),
                      child: Text(
                        _dueDate == null
                            ? 'Select date'
                            : _formatDisplayDate(_dueDate!),
                        style: TextStyle(
                          color: _dueDate == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _DialogSectionTitle(
              title: 'Vendor outreach',
              subtitle: 'Track invitations and responses.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invitedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogDecoration(label: 'Invited', hint: '0'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _responsesCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        _dialogDecoration(label: 'Responses', hint: '0'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<_RfqStatus>(
                    initialValue: _status,
                    decoration: _dialogDecoration(label: 'Status'),
                    items: _RfqStatus.values
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _status = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<_ProcurementPriority>(
                    initialValue: _priority,
                    decoration: _dialogDecoration(label: 'Priority'),
                    items: _ProcurementPriority.values
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _priority = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePoDialog extends StatefulWidget {
  const _CreatePoDialog({
    required this.contextChips,
    required this.categoryOptions,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;

  @override
  State<_CreatePoDialog> createState() => _CreatePoDialogState();
}

class _CreatePoDialogState extends State<_CreatePoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idCtrl;
  late TextEditingController _vendorCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _amountCtrl;

  late String _category;
  _PurchaseOrderStatus _status = _PurchaseOrderStatus.awaitingApproval;
  DateTime _orderedDate = DateTime.now();
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 21));
  double _progress = 0.0;

  final FocusNode _idFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController();
    _vendorCtrl = TextEditingController();
    _ownerCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _category = widget.categoryOptions.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _idFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _vendorCtrl.dispose();
    _ownerCtrl.dispose();
    _amountCtrl.dispose();
    _idFocus.dispose();
    super.dispose();
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatStoreDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
  String _formatDisplayDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProcurementDialogShell(
      title: 'Create Purchase Order',
      subtitle: 'Issue a PO with clear ownership and delivery timing.',
      icon: Icons.receipt_long_outlined,
      contextChips: widget.contextChips,
      primaryLabel: 'Create PO',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        final amount = _parseCurrency(_amountCtrl.text);
        final poId = _idCtrl.text.trim().isEmpty
            ? 'PO-${DateTime.now().millisecondsSinceEpoch % 10000}'
            : _idCtrl.text.trim();
        final po = _PurchaseOrder(
          id: poId,
          vendor: _vendorCtrl.text.trim(),
          category: _category,
          owner: _ownerCtrl.text.trim().isEmpty
              ? 'Unassigned'
              : _ownerCtrl.text.trim(),
          orderedDate: _formatStoreDate(_orderedDate),
          expectedDate: _formatStoreDate(_expectedDate),
          amount: amount,
          progress: _progress,
          status: _status,
        );
        Navigator.of(context).pop(po);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DialogSectionTitle(
              title: 'PO details',
              subtitle: 'Define vendor, owner, and category.',
            ),
            TextFormField(
              controller: _idCtrl,
              focusNode: _idFocus,
              decoration: _dialogDecoration(
                  label: 'PO number', hint: 'Auto-generated if left blank'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vendorCtrl,
              decoration: _dialogDecoration(
                  label: 'Vendor', hint: 'e.g. GreenLeaf Office'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Vendor is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _dialogDecoration(label: 'Category'),
                    items: widget.categoryOptions
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ownerCtrl,
                    decoration:
                        _dialogDecoration(label: 'Owner', hint: 'e.g. L. Chen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _DialogSectionTitle(
              title: 'Amounts and dates',
              subtitle: 'Track financials and delivery.',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _dialogDecoration(
                  label: 'Amount',
                  hint: 'e.g. 72000',
                  prefixIcon: const Icon(Icons.attach_money)),
              validator: (value) {
                final amount = _parseCurrency(value ?? '');
                return amount <= 0 ? 'Enter a PO amount.' : null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _orderedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() => _orderedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                          label: 'Ordered date',
                          prefixIcon: const Icon(Icons.event)),
                      child: Text(
                        _formatDisplayDate(_orderedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() => _expectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                          label: 'Expected date',
                          prefixIcon: const Icon(Icons.event_available)),
                      child: Text(
                        _formatDisplayDate(_expectedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_PurchaseOrderStatus>(
              initialValue: _status,
              decoration: _dialogDecoration(label: 'Status'),
              items: _PurchaseOrderStatus.values
                  .map((option) => DropdownMenuItem(
                      value: option, child: Text(option.label)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            const Text('Progress',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
            Slider(
              value: _progress,
              min: 0,
              max: 1,
              divisions: 10,
              label: '${(_progress * 100).round()}%',
              activeColor: const Color(0xFF2563EB),
              onChanged: (value) => setState(() => _progress = value),
            ),
          ],
        ),
      ),
    );
  }
}

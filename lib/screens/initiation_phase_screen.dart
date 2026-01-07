import 'dart:async';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import '../widgets/content_text.dart';
import '../services/auth_nav.dart';
import '../openai/openai_config.dart';
// Removed AppLogo from header per request
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/business_case_header.dart';
import 'package:ndu_project/widgets/business_case_navigation_buttons.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

class InitiationPhaseScreen extends StatefulWidget {
  final bool scrollToBusinessCase;
  const InitiationPhaseScreen({super.key, this.scrollToBusinessCase = false});

  @override
  State<InitiationPhaseScreen> createState() => _InitiationPhaseScreenState();
}

class _InitiationPhaseScreenState extends State<InitiationPhaseScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _businessCaseController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();
  final FocusNode _businessFocusNode = FocusNode();
    // Anchor key for sidebar navigation
    final GlobalKey _businessCaseSectionKey = GlobalKey();
  bool _initiationExpanded = true;
  
  bool get _isBusinessCaseValid =>
      _meetsBusinessMinimum(_businessCaseController.text.trim());

  void _requireBusinessCaseBefore(String destinationName, VoidCallback proceed) {
    // Blocks navigation to later sections until Business Case has content
    if (_isBusinessCaseValid) {
      proceed();
      return;
    }
    setState(() => _businessInvalid = true);
    _scrollToBusinessCase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please complete the Business Case (min $_businessWordMinimum words) before opening $destinationName.',
        ),
      ),
    );
  }

  void _openPotentialSolutions() async {
    final business = _businessCaseController.text.trim();
    _requireBusinessCaseBefore('Potential Solutions', () async {
      await ProjectDataHelper.saveAndNavigate(
        context: context,
        checkpoint: 'business_case',
        nextScreenBuilder: () => const PotentialSolutionsScreen(),
        dataUpdater: (data) => data.copyWith(
          notes: _notesController.text.trim(),
          businessCase: business,
        ),
      );
    });
  }

  void _openRiskIdentification() {
    _requireBusinessCaseBefore('Risk Identification', () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiskIdentificationScreen(
            notes: _notesController.text.trim(),
            solutions: const [],
            businessCase: _businessCaseController.text.trim(),
          ),
        ),
      );
    });
  }

  Timer? _notesDebounce;
  Timer? _businessDebounce;

  bool _notesSuggestLoading = false;
  bool _businessSuggestLoading = false;

  List<String> _notesSuggestions = [];
  List<String> _businessSuggestions = [];

  String? _notesSuggestionError;
  String? _businessSuggestionError;

  String _notesLastQuery = '';
  String _businessLastQuery = '';
  final List<String> _notesUndoStack = [];
  final List<String> _businessUndoStack = [];
  bool _notesInvalid = false;
  bool _businessInvalid = false;
  static const int _notesWordMinimum = 5;
  static const int _businessWordMinimum = 10;

  @override
  void initState() {
    super.initState();
    _notesFocusNode.addListener(_handleNotesFocusChange);
    _businessFocusNode.addListener(_handleBusinessFocusChange);
    
    // Load existing data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projectData = ProjectDataHelper.getData(context);
      if (projectData.notes.isNotEmpty) {
        _notesController.text = projectData.notes;
      }
      if (projectData.businessCase.isNotEmpty) {
        _businessCaseController.text = projectData.businessCase;
      }
      
      // If requested, scroll to Business Case
      if (widget.scrollToBusinessCase) {
        _scrollToBusinessCase();
      }
      
      if (mounted) setState(() {});
    });
  }

  void _handleNotesFocusChange() {
    if (!mounted) return;
    if (!_notesFocusNode.hasFocus) {
      _notesDebounce?.cancel();
    }
    setState(() {});
  }

  void _handleBusinessFocusChange() {
    if (!mounted) return;
    if (!_businessFocusNode.hasFocus) {
      _businessDebounce?.cancel();
    }
    setState(() {});
  }

  void _onNotesChanged(String value) {
    if (_notesInvalid && _meetsNotesMinimum(value)) {
      setState(() => _notesInvalid = false);
    }
    _scheduleNotesSuggestions(value);
  }

  void _onBusinessChanged(String value) {
    if (_businessInvalid && _meetsBusinessMinimum(value)) {
      setState(() => _businessInvalid = false);
    }
    _scheduleBusinessSuggestions(value);
    // Also rebuild so sidebar enable/disable state reflects current input
    setState(() {});
  }

  int _wordCount(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.length;
  }

  bool _meetsNotesMinimum(String text) => _wordCount(text) >= _notesWordMinimum;

  bool _meetsBusinessMinimum(String text) => _wordCount(text) >= _businessWordMinimum;

  bool _canRequestNotesSuggestions(String text) => text.trim().length >= 12;
  bool _canRequestBusinessSuggestions(String text) => text.trim().length >= 18;

  void _scheduleNotesSuggestions(String value) {
    _notesDebounce?.cancel();
    if (!_notesFocusNode.hasFocus) return;
    if (!_canRequestNotesSuggestions(value)) {
      setState(() {
        _notesSuggestions = [];
        _notesSuggestLoading = false;
        _notesSuggestionError = null;
        _notesLastQuery = '';
      });
      return;
    }

    _notesDebounce = Timer(const Duration(milliseconds: 600), () {
      _fetchNotesSuggestions(value.trim());
    });
  }

  void _scheduleBusinessSuggestions(String value) {
    _businessDebounce?.cancel();
    if (!_businessFocusNode.hasFocus) return;
    if (!_canRequestBusinessSuggestions(value)) {
      setState(() {
        _businessSuggestions = [];
        _businessSuggestLoading = false;
        _businessSuggestionError = null;
        _businessLastQuery = '';
      });
      return;
    }

    _businessDebounce = Timer(const Duration(milliseconds: 600), () {
      _fetchBusinessSuggestions(value.trim());
    });
  }

  Future<void> _fetchNotesSuggestions(String text) async {
    if (!_notesFocusNode.hasFocus || !_canRequestNotesSuggestions(text)) return;
    if (!_notesSuggestLoading && text == _notesLastQuery && _notesSuggestions.isNotEmpty) {
      return;
    }

    setState(() {
      _notesSuggestLoading = true;
      _notesSuggestionError = null;
    });

    try {
      final suggestions = await OpenAiAutocompleteService.instance.fetchSuggestions(
        fieldName: 'Initiation Notes',
        currentText: text,
        context: _businessCaseController.text,
      );
      if (!mounted) return;
      setState(() {
        _notesSuggestions = suggestions;
        _notesSuggestLoading = false;
        _notesLastQuery = text;
      });
    } on OpenAiNotConfiguredException catch (e) {
      if (!mounted) return;
      setState(() {
        _notesSuggestions = [];
        _notesSuggestLoading = false;
        _notesSuggestionError = _formatSuggestionError(e);
        _notesLastQuery = text;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notesSuggestions = [];
        _notesSuggestLoading = false;
        _notesSuggestionError = _formatSuggestionError(e);
        _notesLastQuery = text;
      });
    }
  }

  Future<void> _fetchBusinessSuggestions(String text) async {
    if (!_businessFocusNode.hasFocus || !_canRequestBusinessSuggestions(text)) return;
    if (!_businessSuggestLoading &&
        text == _businessLastQuery &&
        _businessSuggestions.isNotEmpty) {
      return;
    }

    setState(() {
      _businessSuggestLoading = true;
      _businessSuggestionError = null;
    });

    try {
      final suggestions = await OpenAiAutocompleteService.instance.fetchSuggestions(
        fieldName: 'Business Case',
        currentText: text,
        context: _notesController.text,
      );
      if (!mounted) return;
      setState(() {
        _businessSuggestions = suggestions;
        _businessSuggestLoading = false;
        _businessLastQuery = text;
      });
    } on OpenAiNotConfiguredException catch (e) {
      if (!mounted) return;
      setState(() {
        _businessSuggestions = [];
        _businessSuggestLoading = false;
        _businessSuggestionError = _formatSuggestionError(e);
        _businessLastQuery = text;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _businessSuggestions = [];
        _businessSuggestLoading = false;
        _businessSuggestionError = _formatSuggestionError(e);
        _businessLastQuery = text;
      });
    }
  }

  void _applySuggestion(TextEditingController controller, String suggestion,
      {bool isNotes = false}) {
    final replacement = suggestion.trim();
    if (replacement.isEmpty) return;

    _pushUndo(controller, isNotes: isNotes);

    controller.value = TextEditingValue(
      text: replacement,
      selection: TextSelection.collapsed(offset: replacement.length),
    );

    setState(() {
      if (isNotes) {
        _notesSuggestions = [];
        _notesLastQuery = replacement;
      } else {
        _businessSuggestions = [];
        _businessLastQuery = replacement;
      }
    });
  }

  void _insertSuggestion(TextEditingController controller, String suggestion,
      {bool isNotes = false}) {
    final insertion = suggestion.trim();
    if (insertion.isEmpty) return;
    final existing = controller.text.trim();
    final combined = existing.isEmpty ? insertion : '$existing\n$insertion';

    _pushUndo(controller, isNotes: isNotes);

    controller.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: combined.length),
    );

    setState(() {
      if (isNotes) {
        _notesLastQuery = combined;
      } else {
        _businessLastQuery = combined;
      }
    });
  }

  Future<void> _copySuggestion(String suggestion) async {
    final value = suggestion.trim();
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion copied to clipboard')),
    );
  }

  void _pushUndo(TextEditingController controller, {required bool isNotes}) {
    final stack = isNotes ? _notesUndoStack : _businessUndoStack;
    if (stack.isEmpty || stack.last != controller.text) {
      stack.add(controller.text);
    }
  }

  void _undoSuggestion(TextEditingController controller, {required bool isNotes}) {
    final stack = isNotes ? _notesUndoStack : _businessUndoStack;
    if (stack.isEmpty) return;
    final previous = stack.removeLast();
    controller.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    setState(() {});
  }

  void _retryNotesSuggestions() => _fetchNotesSuggestions(_notesController.text.trim());

  void _retryBusinessSuggestions() =>
      _fetchBusinessSuggestions(_businessCaseController.text.trim());

  Future<void> _handleNextPressed() async {
    final notes = _notesController.text.trim();
    final business = _businessCaseController.text.trim();
    // Notes are optional; no minimum word requirement.
    const notesValid = true;
    final businessValid = _meetsBusinessMinimum(business);

    if (!notesValid || !businessValid) {
      setState(() {
        // Ensure Notes never shows as invalid since it's optional.
        _notesInvalid = false;
        _businessInvalid = !businessValid;
      });
      final messageParts = <String>[
        if (!businessValid)
          'Business Case must include at least $_businessWordMinimum words.',
      ];
      if (messageParts.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageParts.join(' '))),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();

    // Save data to provider before navigation
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateInitiationData(
      notes: notes,
      businessCase: business,
    );
    
    // Save to Firebase
    await provider.saveToFirebase(checkpoint: 'business_case');

    // Show a 3-second loading experience before navigation
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const _RiskIdentificationTransitionDialog(),
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PotentialSolutionsScreen(),
      ),
    );
  }

  String _formatSuggestionError(Object error) {
    if (error is OpenAiNotConfiguredException) {
      return 'Add your OpenAI API key to enable AI suggestions.';
    }
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('timed out')) {
      return 'OpenAI request timed out. Try again in a moment.';
    }
    if (lower.contains('rate limit')) {
      return 'OpenAI rate limit reached. Try again shortly.';
    }
    if (lower.contains('api key')) {
      return 'OpenAI rejected the API key. Please verify it.';
    }
    final sanitized = message.replaceFirst(RegExp(r'^Exception: '), '').trim();
    if (sanitized.length > 180) {
      return '${sanitized.substring(0, 177)}…';
    }
    return sanitized;
  }

  Widget _buildSuggestionPanel({
    required bool show,
    required bool loading,
    required List<String> suggestions,
    required String? error,
    required String label,
    required VoidCallback onRefresh,
    VoidCallback? onUndo,
    bool canUndo = false,
    required ValueChanged<String> onSelect,
    ValueChanged<String>? onInsert,
    ValueChanged<String>? onCopy,
  }) {
    if (!show) return const SizedBox.shrink();
    final hasError = (error ?? '').trim().isNotEmpty;
    final hasSuggestions = suggestions.isNotEmpty;
    if (!loading && !hasError && !hasSuggestions) {
      return const SizedBox.shrink();
    }

    final borderColor = hasError
        ? Colors.red.withOpacity(0.2)
        : Colors.grey.withOpacity(0.2);
    final canRefresh = !loading && OpenAiConfig.isConfigured;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canRefresh)
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              if (canUndo && onUndo != null)
                TextButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Undo'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (!loading && hasError)
            Text(
              error!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[600],
              ),
            ),
          if (!loading && hasSuggestions) ...[
            const Text(
              'Tap a suggestion to replace, or use actions to insert or copy.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildSuggestionOption(
                  suggestion,
                  onTap: () => onSelect(suggestion),
                  onInsert: onInsert == null ? null : () => onInsert(suggestion),
                  onCopy: onCopy == null ? null : () => onCopy(suggestion),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionOption(
    String text, {
    required VoidCallback onTap,
    VoidCallback? onInsert,
    VoidCallback? onCopy,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
            if (onInsert != null || onCopy != null) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onInsert != null)
                    _buildSuggestionActionButton(
                      icon: Icons.content_paste_rounded,
                      tooltip: 'Insert into draft',
                      onPressed: onInsert,
                    ),
                  if (onCopy != null)
                    _buildSuggestionActionButton(
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy',
                      onPressed: onCopy,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Stack(
        children: [
          Column(
        children: [
          // Top Header
          BusinessCaseHeader(scaffoldKey: _scaffoldKey),
          Expanded(
            child: Row(
              children: [
                DraggableSidebar(
                  openWidth: sidebarWidth,
                  child: const InitiationLikeSidebar(activeItemLabel: 'Business Case Detail'),
                ),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
          ),
          const KazAiChatBubble(),
          const AdminEditToggle(),
        ],
      ),
    );
  }

  // Sidebar to match PreferredSolutionAnalysisScreen structure and add right border
  Widget _buildSidebar() {
    final isMobile = AppBreakpoints.isMobile(context);
    final double bannerHeight = isMobile ? 72 : 96;
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withValues(alpha: 0.25), width: 0.8),
        ),
      ),
      child: Column(
        children: [
          // Full-width banner image above "StackOne"
          SizedBox(
            width: double.infinity,
            height: bannerHeight,
            child: Center(child: AppLogo(height: 64)),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFFFD700), width: 1),
              ),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFFD700),
                  child: Icon(Icons.person_outline, color: Colors.black87),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('StackOne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItem(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context)),
                _buildExpandableHeader(
                  Icons.flag_outlined,
                  'Initiation Phase',
                  expanded: _initiationExpanded,
                  onTap: () => setState(() => _initiationExpanded = !_initiationExpanded),
                  isActive: true,
                ),
                if (_initiationExpanded) ...[
                  _buildSubMenuItem('Scope Statement', onTap: _scrollToBusinessCase, isActive: true),
                  _buildSubMenuItem('Potential Solutions', onTap: _openPotentialSolutions, disabled: !_isBusinessCaseValid),
                  _buildSubMenuItem('Risk Identification', onTap: _openRiskIdentification, disabled: !_isBusinessCaseValid),
                  _buildSubMenuItem('IT Considerations', onTap: _openITConsiderations, disabled: !_isBusinessCaseValid),
                  _buildSubMenuItem('Infrastructure Considerations', onTap: _openInfrastructureConsiderations, disabled: !_isBusinessCaseValid),
                  _buildSubMenuItem('Core Stakeholders', onTap: _openCoreStakeholders, disabled: !_isBusinessCaseValid),
                  _buildSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: _openCostAnalysis, disabled: !_isBusinessCaseValid),
                  _buildSubMenuItem('Preferred Solution Analysis', onTap: _openPreferredSolutionAnalysis, disabled: !_isBusinessCaseValid),
                ],
                _buildMenuItem(Icons.timeline, 'Initiation: Front End Planning'),
                _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
                _buildMenuItem(Icons.flash_on, 'Agile Roadmap'),
                _buildMenuItem(Icons.description_outlined, 'Contracting'),
                _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () => SettingsScreen.open(context)),
                _buildMenuItem(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFD700),
                child: Icon(Icons.person_outline, color: Colors.black87),
              ),
              title: Text('StackOne'),
            ),
            const Divider(height: 1),
            _buildMenuItem(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context)),
            _buildExpandableHeader(
              Icons.flag_outlined,
              'Initiation Phase',
              expanded: _initiationExpanded,
              onTap: () => setState(() => _initiationExpanded = !_initiationExpanded),
              isActive: true,
            ),
            if (_initiationExpanded) ...[
              _buildSubMenuItem(
                'Business Case',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _scrollToBusinessCase();
                },
                isActive: true,
              ),
              _buildSubMenuItem(
                'Potential Solutions',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _openPotentialSolutions();
                },
              ),
              _buildSubMenuItem(
                'Risk Identification',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _openRiskIdentification();
                },
              ),
              _buildSubMenuItem(
                'IT Considerations',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _openITConsiderations();
                },
              ),
              _buildSubMenuItem(
                'Infrastructure Considerations',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _openInfrastructureConsiderations();
                },
              ),
              _buildSubMenuItem(
                'Core Stakeholders',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _openCoreStakeholders();
                },
              ),
              _buildSubMenuItem(
                'Cost Benefit Analysis & Financial Metrics',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _openCostAnalysis();
                },
              ),
              _buildSubMenuItem(
                'Preferred Solution Analysis',
                onTap: () {
                  Navigator.of(_scaffoldKey.currentContext!).maybePop();
                  _openPreferredSolutionAnalysis();
                },
              ),
            ],
            _buildMenuItem(Icons.timeline, 'Initiation: Front End Planning'),
            _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
            _buildMenuItem(Icons.flash_on, 'Agile Roadmap'),
            _buildMenuItem(Icons.description_outlined, 'Contracting'),
            _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
            const Divider(height: 1),
            _buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () {
              Navigator.of(_scaffoldKey.currentContext!).maybePop();
              SettingsScreen.open(context);
            }),
            _buildMenuItem(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isActive ? primary : Colors.black87),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? primary : Colors.black87,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(String title,
      {VoidCallback? onTap, bool isActive = false, bool disabled = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 24, top: 2, bottom: 2),
      child: InkWell(
        onTap: () {
          if (disabled) {
            // Intercept taps when disabled and guide the user back
            _requireBusinessCaseBefore(title, () {});
            return;
          }
          onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: isActive
                    ? primary
                    : (disabled ? Colors.grey[300] : Colors.grey[500]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive
                        ? primary
                        : (disabled ? Colors.black45 : Colors.black87),
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableHeader(IconData icon, String title, {required bool expanded, required VoidCallback onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isActive ? primary : Colors.black87),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? primary : Colors.black87,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[700], size: 20),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMainContent() {
    final isMobile = AppBreakpoints.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes section
          const EditableContentText(
            contentKey: 'business_case_notes_heading',
            fallback: 'Notes',
            category: 'business_case',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _notesInvalid ? Colors.red : Colors.grey.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: _notesController,
              focusNode: _notesFocusNode,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              decoration: InputDecoration(
                hintText: 'Input your notes here...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              // Auto-expand as the user types; no internal scroll
              minLines: 1,
              maxLines: null,
              onChanged: _onNotesChanged,
            ),
          ),
          if (_notesInvalid)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please enter at least 5 words for Notes.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _buildSuggestionPanel(
              show: _notesFocusNode.hasFocus,
              loading: _notesSuggestLoading,
              suggestions: _notesSuggestions,
              error: _notesSuggestionError,
              label: 'AI suggestions for notes',
              onRefresh: _retryNotesSuggestions,
              onUndo: _notesUndoStack.isEmpty
                  ? null
                  : () => _undoSuggestion(
                        _notesController,
                        isNotes: true,
                      ),
              canUndo: _notesUndoStack.isNotEmpty,
              onSelect: (value) => _applySuggestion(
                _notesController,
                value,
                isNotes: true,
              ),
              onInsert: (value) => _insertSuggestion(
                _notesController,
                value,
                isNotes: true,
              ),
              onCopy: _copySuggestion,
            ),
          ),
          SizedBox(height: AppBreakpoints.sectionGap(context)),
          // Business Case section
          EditableContentText(
            contentKey: 'business_case_heading',
            fallback: 'Scope Statement',
            category: 'business_case',
            key: _businessCaseSectionKey,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          EditableContentText(
            contentKey: 'business_case_description',
            fallback: '(Describe the aim of this project)',
            category: 'business_case',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppBreakpoints.fieldGap(context)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _businessInvalid ? Colors.red : Colors.grey.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: _businessCaseController,
              focusNode: _businessFocusNode,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              decoration: InputDecoration(
                hintText: '(Describe the aim of this project)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              // Start tall, then grow with content; no internal scroll
              minLines: isMobile ? 6 : 10,
              maxLines: null,
              onChanged: _onBusinessChanged,
            ),
          ),
          if (_businessInvalid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Please enter at least $_businessWordMinimum words for the Business Case.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _buildSuggestionPanel(
              show: _businessFocusNode.hasFocus,
              loading: _businessSuggestLoading,
              suggestions: _businessSuggestions,
              error: _businessSuggestionError,
              label: 'AI suggestions for the business case',
              onRefresh: _retryBusinessSuggestions,
              onUndo: _businessUndoStack.isEmpty
                  ? null
                  : () => _undoSuggestion(
                        _businessCaseController,
                        isNotes: false,
                      ),
              canUndo: _businessUndoStack.isNotEmpty,
              onSelect: (value) => _applySuggestion(
                _businessCaseController,
                value,
              ),
              onInsert: (value) => _insertSuggestion(
                _businessCaseController,
                value,
              ),
              onCopy: _copySuggestion,
            ),
          ),
          SizedBox(height: AppBreakpoints.sectionGap(context)),
          // Navigation Buttons
          BusinessCaseNavigationButtons(
            currentScreen: 'Business Case',
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
            onNext: _handleNextPressed,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _businessDebounce?.cancel();
    _notesFocusNode
      ..removeListener(_handleNotesFocusChange)
      ..dispose();
    _businessFocusNode
      ..removeListener(_handleBusinessFocusChange)
      ..dispose();
    _notesController.dispose();
    _businessCaseController.dispose();
    super.dispose();
  }

  void _scrollToBusinessCase() {
    final ctx = _businessCaseSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _openITConsiderations() {
    _requireBusinessCaseBefore('IT Considerations', () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ITConsiderationsScreen(
            notes: _notesController.text.trim(),
            solutions: const [],
          ),
        ),
      );
    });
  }

  void _openInfrastructureConsiderations() {
    _requireBusinessCaseBefore('Infrastructure Considerations', () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InfrastructureConsiderationsScreen(
            notes: _notesController.text.trim(),
            solutions: const [],
          ),
        ),
      );
    });
  }

  void _openCoreStakeholders() {
    _requireBusinessCaseBefore('Core Stakeholders', () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoreStakeholdersScreen(
            notes: _notesController.text.trim(),
            solutions: const [],
          ),
        ),
      );
    });
  }

  void _openCostAnalysis() {
    _requireBusinessCaseBefore('Cost Benefit Analysis & Financial Metrics', () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CostAnalysisScreen(
            notes: _notesController.text.trim(),
            solutions: const [],
          ),
        ),
      );
    });
  }

  void _openPreferredSolutionAnalysis() {
    _requireBusinessCaseBefore('Preferred Solution Analysis', () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreferredSolutionAnalysisScreen(
            notes: _notesController.text.trim(),
            solutions: const [],
            businessCase: _businessCaseController.text.trim(),
          ),
        ),
      );
    });
  }
}

class _RiskIdentificationTransitionDialog extends StatefulWidget {
  const _RiskIdentificationTransitionDialog();

  @override
  State<_RiskIdentificationTransitionDialog> createState() =>
      _RiskIdentificationTransitionDialogState();
}

class _RiskIdentificationTransitionDialogState
    extends State<_RiskIdentificationTransitionDialog> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    // Keep the dialog for 3 seconds, then proceed
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(seconds: 10),
          builder: (context, progress, _) {
            final percent = (progress * 100).clamp(0, 100).toInt();
            return AnimatedScale(
              scale: 1.0 + (_pulseController.value * 0.02),
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 30,
                      offset: Offset(0, 24),
                    ),
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.6),
                    radius: 1.2,
                    colors: [
                      const Color(0xFFFFF5B0).withValues(alpha: 0.40),
                      Colors.white,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RotationTransition(
                            turns: _rotationController,
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Preparing Workspace',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ShimmerText(
                      text: 'Transferring initiation notes and context…',
                      baseColor: const Color(0xFF3A3C41),
                      highlightColor: const Color(0xFF90939A),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size.square(160),
                            painter: _RingPainter(progress: progress),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2F3136),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Optimizing',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF666A71),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This will take about 10 seconds…',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8D93),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerText extends StatefulWidget {
  const _ShimmerText({required this.text, required this.baseColor, required this.highlightColor});

  final String text;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final width = bounds.width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor.withValues(alpha: 0.6),
                widget.highlightColor,
                widget.baseColor.withValues(alpha: 0.6),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              transform: GradientRotation(0),
            ).createShader(Rect.fromLTWH(0, 0, width, bounds.height));
          },
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFF0F1F4)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc with sweep gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -90 * 3.1415926535 / 180; // -90 degrees
    final sweep = progress * 2 * 3.1415926535;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * 3.1415926535,
      colors: const [
        Color(0xFFFFD700),
        Color(0xFFFFA800),
        Color(0xFFFFD700),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweep, false, progressPaint);

    // Small moving dot at the end of arc
    final endX = center.dx + radius * MathCos(startAngle + sweep);
    final endY = center.dy + radius * MathSin(startAngle + sweep);
    final dotPaint = Paint()..color = const Color(0xFFFFA800);
    canvas.drawCircle(Offset(endX, endY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// Simple wrappers since dart:math isn't imported at top of file
double MathSin(double v) => Math.sin(v);
double MathCos(double v) => Math.cos(v);

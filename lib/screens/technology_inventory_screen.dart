import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/utils/text_sanitizer.dart';
import 'package:ndu_project/widgets/ai_regenerate_undo_buttons.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class TechnologyInventoryScreen extends StatefulWidget {
  const TechnologyInventoryScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TechnologyInventoryScreen()));
  }

  @override
  State<TechnologyInventoryScreen> createState() => _TechnologyInventoryScreenState();
}

class _TechnologyInventoryScreenState extends State<TechnologyInventoryScreen> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _seeding = false;
  List<Map<String, dynamic>>? _undoBeforeAi;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) return setState(() => _loading = false);
    final stored = provider.projectData.technologyInventory;
    setState(() {
      _items
        ..clear()
        ..addAll(stored);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) return;
    provider.updateField((data) => data.copyWith(technologyInventory: _items));
    await provider.saveToFirebase(checkpoint: 'technology_inventory');
  }

  Future<void> _seedFromAi() async {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) return;
    if (_seeding) return;
    setState(() => _seeding = true);
    _undoBeforeAi = _items.map((e) => Map<String, dynamic>.from(e)).toList();
    final ai = OpenAiServiceSecure();
    final ctx = '${provider.projectData.projectName}\n${provider.projectData.solutionTitle}\n${provider.projectData.projectObjective}';
    try {
  final text = await ai.generateFepSectionText(section: 'Technology Inventory', context: ctx, maxTokens: 600);
  // Expect newline-separated CSV-ish lines: name | category | notes
  final sanitized = TextSanitizer.sanitizeAiText(text);
  final lines = sanitized.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final parsed = <Map<String, dynamic>>[];
      for (final line in lines) {
        final parts = line.split('|').map((p) => p.trim()).toList();
        parsed.add({
          'name': parts.isNotEmpty ? parts[0] : line,
          'category': parts.length > 1 ? parts[1] : 'Uncategorized',
          'notes': parts.length > 2 ? parts.sublist(2).join(' | ') : '',
        });
      }
      if (parsed.isNotEmpty) {
        setState(() {
          _items.clear();
          _items.addAll(parsed);
        });
        await _save();
      }
    } catch (e) {
      debugPrint('AI seed failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Regenerate failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _undoSeed() async {
    final prev = _undoBeforeAi;
    if (prev == null) return;
    setState(() {
      _items
        ..clear()
        ..addAll(prev.map((e) => Map<String, dynamic>.from(e)));
      _undoBeforeAi = null;
    });
    await _save();
  }

  void _openAddDialog() {
    final name = TextEditingController();
    final category = TextEditingController();
    final notes = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add technology'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
          TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final entry = {'name': name.text.trim(), 'category': category.text.trim(), 'notes': notes.text.trim()};
              setState(() => _items.add(entry));
              await _save();
              Navigator.of(c).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      activeItemLabel: 'Technology Inventory',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Technology Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  Row(children: [
                    AiRegenerateUndoButtons(
                      isLoading: _seeding,
                      canUndo: _undoBeforeAi != null,
                      onRegenerate: _seedFromAi,
                      onUndo: () {
                        _undoSeed();
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _openAddDialog, child: const Text('Add')),
                  ])
                ]),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Notes')),
                          ],
                          rows: _items.map((it) {
                            return DataRow(cells: [
                              DataCell(Text(it['name'] ?? '')),
                              DataCell(Text(it['category'] ?? '')),
                              DataCell(Text(it['notes'] ?? '')),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
      ),
    );
  }
}

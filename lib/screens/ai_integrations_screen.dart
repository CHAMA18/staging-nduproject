import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class AiIntegrationsScreen extends StatefulWidget {
  const AiIntegrationsScreen({super.key});
  static void open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiIntegrationsScreen()));
  @override
  State<AiIntegrationsScreen> createState() => _AiIntegrationsScreenState();
}

class _AiIntegrationsScreenState extends State<AiIntegrationsScreen> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) return setState(() => _loading = false);
    setState(() {
      _items..clear()..addAll(provider.projectData.aiIntegrations);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) return;
    provider.updateField((d) => d.copyWith(aiIntegrations: _items));
    await provider.saveToFirebase(checkpoint: 'ai_integrations');
  }

  Future<void> _seed() async {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) return;
    final ai = OpenAiServiceSecure();
    final ctx = '${provider.projectData.projectName} - ${provider.projectData.solutionTitle}';
    try {
      final text = await ai.generateFepSectionText(section: 'AI Integrations', context: ctx, maxTokens: 600);
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final parsed = lines.map((l) => {'name': l.trim(), 'notes': ''}).toList();
      setState(() => _items..clear()..addAll(parsed));
      await _save();
    } catch (e) {
      debugPrint('AI seed failed: $e');
    }
  }

  void _openAdd() {
    final name = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('Add integration'),
      content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
      actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () async { setState(() => _items.add({'name': name.text.trim()})); await _save(); Navigator.of(c).pop(); }, child: const Text('Add'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(activeItemLabel: 'AI Integrations', body: Padding(
      padding: const EdgeInsets.all(20),
      child: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('AI Integrations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), Row(children: [TextButton(onPressed: _seed, child: const Text('Auto-populate (AI)')), const SizedBox(width: 8), ElevatedButton(onPressed: _openAdd, child: const Text('Add'))])]),
        const SizedBox(height: 12), Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: ListView(children: _items.map((it) => ListTile(title: Text(it['name'] ?? ''), subtitle: Text(it['notes'] ?? ''))).toList()))))
      ]),
    ));
  }
}

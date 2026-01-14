import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/text_sanitizer.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});
  static void open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiRecommendationsScreen()));

  @override
  State<AiRecommendationsScreen> createState() => _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final p = ProjectDataInherited.maybeOf(context);
    if (p == null) return setState(() => _loading = false);
    setState(() {
      _items..clear()..addAll(p.projectData.aiRecommendations);
    });
  }

  Future<void> _save() async {
    final p = ProjectDataInherited.maybeOf(context);
    if (p == null) return;
    p.updateField((d) => d.copyWith(aiRecommendations: _items));
    await p.saveToFirebase(checkpoint: 'ai_recommendations');
  }

  Future<void> _generate() async {
    final p = ProjectDataInherited.maybeOf(context);
    if (p == null) return;
    final ai = OpenAiServiceSecure();
    final ctx = '${p.projectData.projectName}\n${p.projectData.solutionTitle}\n${p.projectData.projectObjective}';
    try {
  final text = await ai.generateFepSectionText(section: 'AI Recommendations', context: ctx, maxTokens: 800);
  final sanitized = TextSanitizer.sanitizeAiText(text);
  final lines = sanitized.split('\n').where((l) => l.trim().isNotEmpty).toList();
      setState(() => _items..clear()..addAll(lines.map((l) => {'recommendation': l.trim()})));
      await _save();
    } catch (e) {
      debugPrint('AI gen failed: $e');
    }
  }

  void _openAdd() {
    final t = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add recommendation'),
        content: TextField(controller: t, decoration: const InputDecoration(labelText: 'Recommendation')),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              setState(() => _items.add({'recommendation': t.text.trim()}));
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
      activeItemLabel: 'AI Recommendations',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('AI Recommendations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  Row(children: [
                    TextButton(onPressed: _generate, child: const Text('Auto-generate (AI)')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _openAdd, child: const Text('Add')),
                  ])
                ]),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ListView(children: _items.map((it) => ListTile(title: Text(it['recommendation'] ?? ''))).toList()),
                    ),
                  ),
                ),
              ]),
      ),
    );
  }
}

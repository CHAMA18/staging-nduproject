import 'package:flutter/material.dart';

class LaunchEntry {
  const LaunchEntry({
    required this.title,
    this.details = '',
    this.status,
  });

  final String title;
  final String details;
  final String? status;
}

/// Reusable section that starts empty and is filled through an add dialog.
class LaunchEditableSection extends StatelessWidget {
  const LaunchEditableSection({
    super.key,
    required this.title,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
    this.description,
    this.emptyLabel = 'No entries yet. Add details to get started.',
    this.showStatusChip = true,
  });

  final String title;
  final String? description;
  final List<LaunchEntry> entries;
  final Future<void> Function() onAdd;
  final void Function(int index) onRemove;
  final String emptyLabel;
  final bool showStatusChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF9CA3AF), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      emptyLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  _LaunchEntryCard(
                    entry: entries[i],
                    showStatusChip: showStatusChip,
                    onRemove: () => onRemove(i),
                  ),
                  if (i != entries.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _LaunchEntryCard extends StatelessWidget {
  const _LaunchEntryCard({
    required this.entry,
    required this.onRemove,
    required this.showStatusChip,
  });

  final LaunchEntry entry;
  final VoidCallback onRemove;
  final bool showStatusChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
                tooltip: 'Remove',
              ),
            ],
          ),
          if (entry.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.details,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
          if (showStatusChip && (entry.status ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                entry.status!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4338CA),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<LaunchEntry?> showLaunchEntryDialog(
  BuildContext context, {
  String titleLabel = 'Title',
  String detailsLabel = 'Details',
  bool includeStatus = true,
}) {
  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final statusController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<LaunchEntry>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Add entry'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: titleLabel),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a $titleLabel' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: detailsController,
                decoration: InputDecoration(labelText: detailsLabel),
                maxLines: 3,
              ),
              if (includeStatus) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status (optional)'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop(
                LaunchEntry(
                  title: titleController.text.trim(),
                  details: detailsController.text.trim(),
                  status: includeStatus && statusController.text.trim().isNotEmpty ? statusController.text.trim() : null,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

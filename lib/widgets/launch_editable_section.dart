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

  Map<String, dynamic> toJson() => {
        'title': title,
        'details': details,
        'status': status,
      };

  factory LaunchEntry.fromJson(Map<String, dynamic> json) {
    return LaunchEntry(
      title: json['title']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTableLayout = constraints.maxWidth >= 760;

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
              if (useTableLayout) _buildTable(context) else _buildCardList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardList() {
    if (entries.isEmpty) {
      return Container(
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
      );
    }

    return Column(
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
    );
  }

  Widget _buildTable(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF6B7280),
      letterSpacing: 0.2,
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111827),
    );
    const detailStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.4,
    );

    final columns = showStatusChip
        ? const [
            _TableColumn(label: 'Item', flex: 4),
            _TableColumn(label: 'Details', flex: 6),
            _TableColumn(label: 'Status', flex: 3),
            _TableColumn(label: 'Action', flex: 2, align: TextAlign.center),
          ]
        : const [
            _TableColumn(label: 'Item', flex: 5),
            _TableColumn(label: 'Details', flex: 7),
            _TableColumn(label: 'Action', flex: 2, align: TextAlign.center),
          ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final column in columns)
                Expanded(
                  flex: column.flex,
                  child: Text(column.label, style: headerStyle, textAlign: column.align),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < entries.length; i++) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: columns[0].flex,
                            child: Text(
                              entries[i].title,
                              style: cellStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: columns[1].flex,
                            child: Text(
                              entries[i].details.isNotEmpty ? entries[i].details : '—',
                              style: detailStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showStatusChip)
                            Expanded(
                              flex: columns[2].flex,
                              child: (entries[i].status ?? '').isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        entries[i].status!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4338CA),
                                        ),
                                      ),
                                    )
                                  : Text('—', style: detailStyle),
                            ),
                          Expanded(
                            flex: columns.last.flex,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: IconButton(
                                onPressed: () => onRemove(i),
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
                                tooltip: 'Remove',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != entries.length - 1)
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                  ],
                ],
              ),
            ),
          ),
      ],
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

class _TableColumn {
  const _TableColumn({
    required this.label,
    required this.flex,
    this.align = TextAlign.left,
  });

  final String label;
  final int flex;
  final TextAlign align;
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
      final media = MediaQuery.of(ctx);
      final dialogWidth = media.size.width < 600 ? media.size.width * 0.92 : 560.0;
      final fieldDecoration = InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Text('Add entry'),
        content: SizedBox(
          width: dialogWidth,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: fieldDecoration.copyWith(labelText: titleLabel),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a $titleLabel' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: detailsController,
                    decoration: fieldDecoration.copyWith(labelText: detailsLabel),
                    maxLines: 3,
                  ),
                  if (includeStatus) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: statusController,
                      decoration: fieldDecoration.copyWith(labelText: 'Status (optional)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

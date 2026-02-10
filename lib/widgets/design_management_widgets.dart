import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

class DesignSpecificationsCard extends StatelessWidget {
  const DesignSpecificationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = ProjectDataInherited.of(context);
    final specifications =
        provider.projectData.designManagementData?.specifications ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Design Specifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF6366F1)),
                onPressed: () => _showAddSpecificationDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (specifications.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No specifications defined.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: specifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final spec = specifications[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(spec.description),
                  trailing: _buildStatusChip(context, spec, provider),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, DesignSpecification spec,
      ProjectDataProvider provider) {
    Color color;
    switch (spec.status) {
      case 'Validated':
        color = Colors.green;
        break;
      case 'Implemented':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return InkWell(
      onTap: () => _showStatusDialog(context, spec, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          spec.status,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddSpecificationDialog(
      BuildContext context, ProjectDataProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Specification'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Enter specification details'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newSpec =
                    DesignSpecification(description: controller.text);
                final currentData = provider.projectData.designManagementData ??
                    DesignManagementData();
                currentData.specifications.add(newSpec);

                provider.updateProjectData(
                  provider.projectData
                      .copyWith(designManagementData: currentData),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, DesignSpecification spec,
      ProjectDataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update Status'),
        children: ['Defined', 'Validated', 'Implemented'].map((status) {
          return SimpleDialogOption(
            onPressed: () {
              spec.status = status;
              // Trigger update
              final currentData = provider.projectData.designManagementData!;
              // The list is already mutated, but we need to notify listeners
              provider.updateProjectData(
                provider.projectData
                    .copyWith(designManagementData: currentData),
              );
              Navigator.pop(context);
            },
            child: Text(status),
          );
        }).toList(),
      ),
    );
  }
}

class DesignDocumentsCard extends StatelessWidget {
  const DesignDocumentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = ProjectDataInherited.of(context);
    final documents =
        provider.projectData.designManagementData?.documents ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description,
                    color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Design Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (documents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.folder_open,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No documents linked',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showAddDocumentDialog(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Document'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: documents.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: Colors.blue, size: 20),
                      ),
                      title: Text(doc.title,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(doc.type,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      trailing: doc.url != null && doc.url!.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.open_in_new,
                                  size: 18, color: Colors.grey.shade600),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening ${doc.url}')),
                                );
                              },
                            )
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _showAddDocumentDialog(context, provider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Document'),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog(
      BuildContext context, ProjectDataProvider provider) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String type = 'Output';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Document Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Document Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL (Optional)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['Input', 'Output', 'Reference'].map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) => setState(() => type = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newDoc = DesignDocument(
                    title: titleController.text,
                    url: urlController.text,
                    type: type,
                  );
                  final currentData =
                      provider.projectData.designManagementData ??
                          DesignManagementData();
                  currentData.documents.add(newDoc);

                  provider.updateProjectData(
                    provider.projectData
                        .copyWith(designManagementData: currentData),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class DesignToolsCard extends StatelessWidget {
  const DesignToolsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = ProjectDataInherited.of(context);
    final tools = provider.projectData.designManagementData?.tools ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.construction,
                    color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Design Tools',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tools.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.handyman, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No tools configured',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showAddToolDialog(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Tool'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tools.map((tool) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening ${tool.url}')),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: tool.isInternal
                                ? Colors.blue.shade50
                                : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tool.isInternal
                                  ? Colors.blue.shade200
                                  : Colors.purple.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tool.isInternal ? Icons.dns : Icons.public,
                                size: 16,
                                color: tool.isInternal
                                    ? Colors.blue.shade700
                                    : Colors.purple.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tool.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: tool.isInternal
                                      ? Colors.blue.shade900
                                      : Colors.purple.shade900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  final currentData = provider
                                      .projectData.designManagementData!;
                                  currentData.tools.remove(tool);
                                  provider.updateProjectData(
                                    provider.projectData.copyWith(
                                        designManagementData: currentData),
                                  );
                                },
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _showAddToolDialog(context, provider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Tool'),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddToolDialog(BuildContext context, ProjectDataProvider provider) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    bool isInternal = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Design Tool'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tool Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Internal Tool'),
                value: isInternal,
                onChanged: (val) => setState(() => isInternal = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  final newTool = DesignToolLink(
                    name: nameController.text,
                    url: urlController.text,
                    isInternal: isInternal,
                  );
                  final currentData =
                      provider.projectData.designManagementData ??
                          DesignManagementData();
                  currentData.tools.add(newTool);

                  provider.updateProjectData(
                    provider.projectData
                        .copyWith(designManagementData: currentData),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

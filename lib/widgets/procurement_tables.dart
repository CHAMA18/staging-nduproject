import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/widgets/expandable_text.dart';

class ContractsTable extends StatelessWidget {
  final List<ContractModel> contracts;
  final Function(ContractModel)? onEdit;
  final Function(ContractModel)? onDelete;

  const ContractsTable({
    super.key,
    required this.contracts,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (contracts.isEmpty) {
      return _EmptyState(label: 'contracts');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 16,
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              dataRowMinHeight: 56, // Enterprise standard height
              dataRowMaxHeight: 72,
              border: TableBorder(
                bottom: BorderSide(color: Colors.grey[200]!),
                verticalInside: BorderSide.none,
              ),
              columns: const [
                DataColumn(
                    label: Text('CONTRACT ITEM',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 12,
                            color: Color(0xFF64748B)))),
                DataColumn(
                    label: Text('VENDOR',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 12,
                            color: Color(0xFF64748B)))),
                DataColumn(
                    label: Text('VALUE',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 12,
                            color: Color(0xFF64748B)))),
                DataColumn(
                    label: Text('TIMELINE',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 12,
                            color: Color(0xFF64748B)))),
                DataColumn(
                    label: Text('OWNER',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 12,
                            color: Color(0xFF64748B)))),
                DataColumn(
                    label: Text('STATUS',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 12,
                            color: Color(0xFF64748B)))),
                DataColumn(label: Text('')), // Actions
              ],
              rows: contracts.map((contract) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contract.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(contract.description,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    DataCell(_TextCell(contract.contractorName)),
                    DataCell(_PriceCell(contract.estimatedCost)),
                    DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contract.startDate != null)
                          Text(
                              'Start: ${DateFormat('MMM dd, yyyy').format(contract.startDate!)}',
                              style: const TextStyle(fontSize: 11)),
                        if (contract.endDate != null)
                          Text(
                              'End: ${DateFormat('MMM dd, yyyy').format(contract.endDate!)}',
                              style: const TextStyle(fontSize: 11)),
                        if (contract.startDate == null &&
                            contract.endDate == null)
                          const Text('-', style: TextStyle(color: Colors.grey)),
                      ],
                    )),
                    DataCell(_OwnerBadge(name: contract.owner)),
                    DataCell(_ContractStatusBadge(status: contract.status)),
                    DataCell(
                      PopupMenuButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.grey),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit Contract'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) {
                            onEdit!(contract);
                          } else if (value == 'delete' && onDelete != null) {
                            onDelete!(contract);
                          }
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class ProcurementTable extends StatelessWidget {
  final List<ProcurementItemModel> items;

  const ProcurementTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(label: 'vendors/items');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 12,
              headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
              border: TableBorder.all(
                  color: Colors.grey[300]!,
                  width: 0.5,
                  borderRadius: BorderRadius.circular(8)),
              columns: const [
                DataColumn(
                    label: Text('Item / Equipment',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Stage',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Responsible',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Est. Price',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Comments',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(_TextCell(item.name, bold: true)),
                    DataCell(_TextCell(item.projectPhase.isNotEmpty
                        ? item.projectPhase
                        : 'Planning')),
                    DataCell(_TextCell(item.responsibleMember.isNotEmpty
                        ? item.responsibleMember
                        : 'Unassigned')),
                    DataCell(_PriceCell(item.budget)),
                    DataCell(_StatusCell(item.status.name)),
                    DataCell(_ExpandableCell(item.comments)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          'No $label added yet.',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;
  final bool bold;
  const _TextCell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: bold ? const TextStyle(fontWeight: FontWeight.w600) : null,
      ),
    );
  }
}

class _ExpandableCell extends StatelessWidget {
  final String text;
  const _ExpandableCell(this.text);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const Text('-');
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      child: ExpandableText(
        text: text,
        maxLines: 1,
        style: const TextStyle(fontSize: 13),
        expandButtonColor: Colors.blue,
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final double amount;
  const _PriceCell(this.amount);

  @override
  Widget build(BuildContext context) {
    return Text(
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
      style:
          const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  final String name;
  const _OwnerBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty || name == 'Unassigned') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Unassigned',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      );
    }
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.blue[100],
          child: Text(name[0].toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ContractStatusBadge extends StatelessWidget {
  final ContractStatus status;
  const _ContractStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label = status.name.replaceAll('_', ' ').toUpperCase();

    switch (status) {
      case ContractStatus.draft:
        color = Colors.grey[700]!;
        bg = Colors.grey[100]!;
        break;
      case ContractStatus.under_review:
        color = Colors.blue[700]!;
        bg = Colors.blue[50]!;
        break;
      case ContractStatus.approved:
        color = Colors.purple[700]!;
        bg = Colors.purple[50]!;
        break;
      case ContractStatus.executed:
        color = Colors.green[700]!;
        bg = Colors.green[50]!;
        break;
      case ContractStatus.expired:
        color = Colors.orange[800]!;
        bg = Colors.orange[50]!;
        break;
      case ContractStatus.terminated:
        color = Colors.red[800]!;
        bg = Colors.red[50]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final String status;
  const _StatusCell(this.status);
  // ... existing implementation for Procurement Items ...
  @override
  Widget build(BuildContext context) {
    // ... existing logic ...
    final s = status.toLowerCase();
    Color color = Colors.grey;
    if (s.contains('planning') || s.contains('draft')) color = Colors.blue;
    if (s.contains('active') || s.contains('issued')) color = Colors.green;
    if (s.contains('ordered') || s.contains('transit')) color = Colors.orange;
    if (s.contains('delivered') || s.contains('received')) color = Colors.teal;
    if (s.contains('cancelled')) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

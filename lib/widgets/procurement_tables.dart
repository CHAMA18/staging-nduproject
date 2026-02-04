import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/widgets/expandable_text.dart';

class ContractsTable extends StatelessWidget {
  final List<ContractModel> contracts;

  const ContractsTable({super.key, required this.contracts});

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
              horizontalMargin: 12,
              headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
              border: TableBorder.all(
                  color: Colors.grey[300]!,
                  width: 0.5,
                  borderRadius: BorderRadius.circular(8)),
              columns: const [
                DataColumn(
                    label: Text('Contract Item',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Description',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Contractor',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Duration',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Cost',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: contracts.map((contract) {
                return DataRow(
                  cells: [
                    DataCell(_TextCell(contract.title, bold: true)),
                    DataCell(_ExpandableCell(contract.description)),
                    DataCell(_TextCell(contract.contractorName)),
                    DataCell(_TextCell(contract.duration)),
                    DataCell(_PriceCell(contract.estimatedCost)),
                    DataCell(_StatusCell(contract.status)),
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
        style:
            bold ? const TextStyle(fontWeight: FontWeight.w600) : null,
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

class _StatusCell extends StatelessWidget {
  final String status;
  const _StatusCell(this.status);

  @override
  Widget build(BuildContext context) {
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

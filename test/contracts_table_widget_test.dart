import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/services/contract_service.dart';
import 'package:ndu_project/widgets/contracts_table_widget.dart';

void main() {
  testWidgets('ContractsTableWidget renders blank and custom contract types',
      (tester) async {
    final contracts = [
      _contract(id: 'blank-type', contractType: ''),
      _contract(id: 'custom-type', contractType: 'Master Services Agreement'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContractsTableWidget(
            contracts: contracts,
            onContractUpdated: (_) {},
            onContractDeleted: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Vendor/Party Name'), findsOneWidget);
    expect(find.text('Master Services Agreement'), findsOneWidget);
    expect(find.text('Select type'), findsOneWidget);
  });
}

ContractModel _contract({
  required String id,
  required String contractType,
}) {
  return ContractModel(
    id: id,
    projectId: 'project-1',
    name: 'Vendor $id',
    description: 'Contract description',
    contractType: contractType,
    paymentType: 'Fixed',
    status: 'Active',
    estimatedValue: 100000,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
    scope: '',
    discipline: '',
    notes: '',
    createdById: 'user-1',
    createdByEmail: 'user@example.com',
    createdByName: 'User',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

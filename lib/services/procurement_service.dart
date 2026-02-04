import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';

class ProcurementService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Collection References ---

  static CollectionReference<Map<String, dynamic>> _itemsCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('procurement_items');

  static CollectionReference<Map<String, dynamic>> _strategiesCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('procurement_strategies');

  static CollectionReference<Map<String, dynamic>> _rfqsCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('rfqs');

  static CollectionReference<Map<String, dynamic>> _posCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('purchase_orders');

  static CollectionReference<Map<String, dynamic>> _contractsCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('contracts');

  // --- Procurement Items ---

  static Stream<List<ProcurementItemModel>> streamItems(String projectId) {
    return _itemsCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProcurementItemModel.fromDoc).toList());
  }

  static Future<String> createItem(ProcurementItemModel item) async {
    // Note: Creating with auto-ID if item.id is empty, but usually model creation generates ID or we wait for Firestore.
    // Ideally we let Firestore generate ID.
    final ref = _itemsCol(item.projectId).doc();
    // Re-create map to inject server timestamp if needed, but model has it.
    // We update the ID in the payload to match the doc ID.
    final payload = item.toMap();
    // Ensure we don't save empty ID if we want doc ID in the field (optional but good practice)
    
    await ref.set(payload);
    return ref.id;
  }

  static Future<void> updateItem(String projectId, String itemId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _itemsCol(projectId).doc(itemId).update(data);
  }

  static Future<void> deleteItem(String projectId, String itemId) async {
    await _itemsCol(projectId).doc(itemId).delete();
  }

  // --- Strategies ---

  static Stream<List<ProcurementStrategyModel>> streamStrategies(String projectId) {
    return _strategiesCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProcurementStrategyModel.fromDoc).toList());
  }

  static Future<void> createStrategy(ProcurementStrategyModel strategy) async {
    await _strategiesCol(strategy.projectId).add(strategy.toMap());
  }

  static Future<void> updateStrategy(String projectId, String strategyId, Map<String, dynamic> data) async {
    await _strategiesCol(projectId).doc(strategyId).update(data);
  }

  static Future<void> deleteStrategy(String projectId, String strategyId) async {
    await _strategiesCol(projectId).doc(strategyId).delete();
  }

  // --- RFQs ---

  static Stream<List<RfqModel>> streamRfqs(String projectId) {
    return _rfqsCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RfqModel.fromDoc).toList());
  }

  static Future<void> createRfq(RfqModel rfq) async {
    await _rfqsCol(rfq.projectId).add(rfq.toMap());
  }

  static Future<void> updateRfq(String projectId, String rfqId, Map<String, dynamic> data) async {
    await _rfqsCol(projectId).doc(rfqId).update(data);
  }

  static Future<void> deleteRfq(String projectId, String rfqId) async {
    await _rfqsCol(projectId).doc(rfqId).delete();
  }

  // --- Purchase Orders ---

  static Stream<List<PurchaseOrderModel>> streamPos(String projectId) {
    return _posCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PurchaseOrderModel.fromDoc).toList());
  }

  static Future<void> createPo(PurchaseOrderModel po) async {
    await _posCol(po.projectId).add(po.toMap());
  }

  static Future<void> updatePo(String projectId, String poId, Map<String, dynamic> data) async {
    await _posCol(projectId).doc(poId).update(data);
  }

  static Future<void> deletePo(String projectId, String poId) async {
    await _posCol(projectId).doc(poId).delete();
  }

  // --- Contracts ---

  static Stream<List<ContractModel>> streamContracts(String projectId) {
    return _contractsCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ContractModel.fromDoc).toList());
  }

  static Future<void> createContract(ContractModel contract) async {
    await _contractsCol(contract.projectId).add(contract.toMap());
  }

  static Future<void> updateContract(String projectId, String contractId, Map<String, dynamic> data) async {
    await _contractsCol(projectId).doc(contractId).update(data);
  }

  static Future<void> deleteContract(String projectId, String contractId) async {
    await _contractsCol(projectId).doc(contractId).delete();
  }
}

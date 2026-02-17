import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';

class ProcurementService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int _defaultQueryLimit = 80;
  static const int _maxQueryLimit = 500;

  static int _sanitizeLimit(int limit) {
    if (limit < 1) return 1;
    if (limit > _maxQueryLimit) return _maxQueryLimit;
    return limit;
  }

  // --- Collection References ---

  static CollectionReference<Map<String, dynamic>> _itemsCol(
          String projectId) =>
      _db.collection('projects').doc(projectId).collection('procurement_items');

  static CollectionReference<Map<String, dynamic>> _strategiesCol(
          String projectId) =>
      _db
          .collection('projects')
          .doc(projectId)
          .collection('procurement_strategies');

  static CollectionReference<Map<String, dynamic>> _rfqsCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('rfqs');

  static CollectionReference<Map<String, dynamic>> _posCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('purchase_orders');

  static CollectionReference<Map<String, dynamic>> _contractsCol(
          String projectId) =>
      _db.collection('projects').doc(projectId).collection('contracts');

  static Query<ProcurementItemModel> _itemsQuery(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _itemsCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(_sanitizeLimit(limit))
        .withConverter<ProcurementItemModel>(
          fromFirestore: (snapshot, _) =>
              ProcurementItemModel.fromDoc(snapshot),
          toFirestore: (model, _) => model.toMap(),
        );
  }

  static Query<ProcurementStrategyModel> _strategiesQuery(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _strategiesCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(_sanitizeLimit(limit))
        .withConverter<ProcurementStrategyModel>(
          fromFirestore: (snapshot, _) =>
              ProcurementStrategyModel.fromDoc(snapshot),
          toFirestore: (model, _) => model.toMap(),
        );
  }

  static Query<RfqModel> _rfqsQuery(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _rfqsCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(_sanitizeLimit(limit))
        .withConverter<RfqModel>(
          fromFirestore: (snapshot, _) => RfqModel.fromDoc(snapshot),
          toFirestore: (model, _) => model.toMap(),
        );
  }

  static Query<PurchaseOrderModel> _posQuery(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _posCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(_sanitizeLimit(limit))
        .withConverter<PurchaseOrderModel>(
          fromFirestore: (snapshot, _) => PurchaseOrderModel.fromDoc(snapshot),
          toFirestore: (model, _) => model.toMap(),
        );
  }

  static Query<ContractModel> _contractsQuery(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _contractsCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(_sanitizeLimit(limit))
        .withConverter<ContractModel>(
          fromFirestore: (snapshot, _) => ContractModel.fromDoc(snapshot),
          toFirestore: (model, _) => model.toMap(),
        );
  }

  // --- Procurement Items ---

  static Stream<List<ProcurementItemModel>> streamItems(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _itemsQuery(projectId, limit: limit).snapshots().map(
          (snap) => snap.docs.map((doc) => doc.data()).toList(),
        );
  }

  static Future<bool> hasAnyItems(String projectId) async {
    final snap = await _itemsCol(projectId).limit(1).get();
    return snap.docs.isNotEmpty;
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

  static Future<void> updateItem(
      String projectId, String itemId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _itemsCol(projectId).doc(itemId).update(data);
  }

  static Future<void> deleteItem(String projectId, String itemId) async {
    await _itemsCol(projectId).doc(itemId).delete();
  }

  // --- Strategies ---

  static Stream<List<ProcurementStrategyModel>> streamStrategies(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _strategiesQuery(projectId, limit: limit).snapshots().map(
          (snap) => snap.docs.map((doc) => doc.data()).toList(),
        );
  }

  static Future<void> createStrategy(ProcurementStrategyModel strategy) async {
    await _strategiesCol(strategy.projectId).add(strategy.toMap());
  }

  static Future<void> updateStrategy(
      String projectId, String strategyId, Map<String, dynamic> data) async {
    await _strategiesCol(projectId).doc(strategyId).update(data);
  }

  static Future<void> deleteStrategy(
      String projectId, String strategyId) async {
    await _strategiesCol(projectId).doc(strategyId).delete();
  }

  // --- RFQs ---

  static Stream<List<RfqModel>> streamRfqs(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _rfqsQuery(projectId, limit: limit).snapshots().map(
          (snap) => snap.docs.map((doc) => doc.data()).toList(),
        );
  }

  static Future<void> createRfq(RfqModel rfq) async {
    await _rfqsCol(rfq.projectId).add(rfq.toMap());
  }

  static Future<void> updateRfq(
      String projectId, String rfqId, Map<String, dynamic> data) async {
    await _rfqsCol(projectId).doc(rfqId).update(data);
  }

  static Future<void> deleteRfq(String projectId, String rfqId) async {
    await _rfqsCol(projectId).doc(rfqId).delete();
  }

  // --- Purchase Orders ---

  static Stream<List<PurchaseOrderModel>> streamPos(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _posQuery(projectId, limit: limit).snapshots().map(
          (snap) => snap.docs.map((doc) => doc.data()).toList(),
        );
  }

  static Future<void> createPo(PurchaseOrderModel po) async {
    await _posCol(po.projectId).add(po.toMap());
  }

  static Future<void> updatePo(
      String projectId, String poId, Map<String, dynamic> data) async {
    await _posCol(projectId).doc(poId).update(data);
  }

  static Future<void> deletePo(String projectId, String poId) async {
    await _posCol(projectId).doc(poId).delete();
  }

  // --- Contracts ---

  static Stream<List<ContractModel>> streamContracts(
    String projectId, {
    int limit = _defaultQueryLimit,
  }) {
    return _contractsQuery(projectId, limit: limit).snapshots().map(
          (snap) => snap.docs.map((doc) => doc.data()).toList(),
        );
  }

  static Future<bool> hasAnyContracts(String projectId) async {
    final snap = await _contractsCol(projectId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  static Future<void> createContract(ContractModel contract) async {
    await _contractsCol(contract.projectId).add(contract.toMap());
  }

  static Future<void> updateContract(
      String projectId, String contractId, Map<String, dynamic> data) async {
    await _contractsCol(projectId).doc(contractId).update(data);
  }

  static Future<void> deleteContract(
      String projectId, String contractId) async {
    await _contractsCol(projectId).doc(contractId).delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChangeRequest {
  final String id; // Firestore document id
  final String displayId; // e.g., CR-001
  final String title;
  final String type;
  final String impact;
  final String status;
  final String requester;
  final String? description;
  final String? justification;
  final DateTime requestDate;
  final DateTime createdAt;

  ChangeRequest({
    required this.id,
    required this.displayId,
    required this.title,
    required this.type,
    required this.impact,
    required this.status,
    required this.requester,
    required this.requestDate,
    required this.createdAt,
    this.description,
    this.justification,
  });

  static ChangeRequest fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseDate(dynamic value, {required String fieldName}) {
      try {
        if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) return parsed;
        }
        if (value is int) {
          // Assume ms since epoch if value is large enough, else seconds
          if (value > 100000000000) {
            return DateTime.fromMillisecondsSinceEpoch(value);
          }
          return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
        // Firestore can sometimes return map-like timestamp on web SDKs
        if (value is Map) {
          final seconds = value['seconds'] ?? value['_seconds'];
          final nanos = value['nanoseconds'] ?? value['_nanoseconds'] ?? 0;
          final intSec = seconds is int
              ? seconds
              : (seconds is double
                  ? seconds.toInt()
                  : (seconds is num ? seconds.toInt() : 0));
          final intNanos = nanos is int
              ? nanos
              : (nanos is double
                  ? nanos.toInt()
                  : (nanos is num ? nanos.toInt() : 0));
          if (intSec != 0 || intNanos != 0) {
            return DateTime.fromMillisecondsSinceEpoch(intSec * 1000 + (intNanos ~/ 1000000));
          }
        }
      } catch (e, st) {
        debugPrint('ChangeRequest parse error for field "$fieldName": $e\n$st');
      }
      debugPrint('ChangeRequest warning: Unrecognized date value for "$fieldName" -> $value (type: ${value.runtimeType}), defaulting to now');
      return DateTime.now();
    }

    final requestDate = parseDate(data['requestDate'], fieldName: 'requestDate');
    final createdAt = parseDate(data['createdAt'], fieldName: 'createdAt');

    return ChangeRequest(
      id: doc.id,
      displayId: data['displayId'] as String? ?? 'CR-${doc.id.substring(0, 6).toUpperCase()}',
      title: data['title'] as String? ?? '',
      type: data['type'] as String? ?? '',
      impact: data['impact'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
      requester: data['requester'] as String? ?? '',
      description: data['description'] as String?,
      justification: data['justification'] as String?,
      requestDate: requestDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'displayId': displayId,
      'title': title,
      'type': type,
      'impact': impact,
      'status': status,
      'requester': requester,
      'description': description,
      'justification': justification,
      'requestDate': Timestamp.fromDate(requestDate),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChangeRequestService {
  static CollectionReference<Map<String, dynamic>>? _tryCollection() {
    try {
      return FirebaseFirestore.instance.collection('change_requests');
    } catch (e, st) {
      debugPrint('ChangeRequestService: Firestore not ready ($e)\n$st');
      return null;
    }
  }

  static CollectionReference<Map<String, dynamic>> _requireCollection() {
    final col = _tryCollection();
    if (col == null) {
      throw StateError('Firestore is not initialized');
    }
    return col;
  }

  // Generates a displayId like CR-001 based on current count; not transaction-safe but fine for demo.
  static Future<String> _generateDisplayId() async {
    final snapshot = await _requireCollection().count().get();
    final next = (snapshot.count ?? 0) + 1;
    String pad(int n) => n.toString().padLeft(3, '0');
    return 'CR-${pad(next)}';
  }

  static Future<String> createChangeRequest({
    required String title,
    required String type,
    required String impact,
    required String status,
    required String requester,
    required DateTime requestDate,
    String? description,
    String? justification,
  }) async {
    final displayId = await _generateDisplayId();
    final data = {
      'displayId': displayId,
      'title': title,
      'type': type,
      'impact': impact,
      'status': status,
      'requester': requester,
      'description': description,
      'justification': justification,
      'requestDate': Timestamp.fromDate(requestDate),
      'createdAt': FieldValue.serverTimestamp(),
    };
    final ref = await _requireCollection().add(data);
    return ref.id;
  }

  static Stream<List<ChangeRequest>> streamChangeRequests() {
    final col = _tryCollection();
    if (col == null) {
      return Stream<List<ChangeRequest>>.value(const []);
    }
    try {
      return col
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => ChangeRequest.fromDoc(d)).toList());
    } catch (e, st) {
      debugPrint('ChangeRequestService: stream failure ($e)\n$st');
      return Stream<List<ChangeRequest>>.value(const []);
    }
  }

  static Future<void> updateChangeRequest(ChangeRequest request) async {
    try {
      await _requireCollection().doc(request.id).update({
        'title': request.title,
        'type': request.type,
        'impact': request.impact,
        'status': request.status,
        'requester': request.requester,
        'description': request.description,
        'justification': request.justification,
        'requestDate': Timestamp.fromDate(request.requestDate),
      });
    } catch (e) {
      debugPrint('Failed to update change request (${request.id}): $e');
      rethrow;
    }
  }

  static Future<void> deleteChangeRequest(String id) async {
    try {
      await _requireCollection().doc(id).delete();
    } catch (e) {
      debugPrint('Failed to delete change request ($id): $e');
    }
  }
}

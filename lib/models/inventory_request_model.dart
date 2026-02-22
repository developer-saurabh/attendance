import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryPurchaseRequest {
  final String id;
  final String facultyId;
  final String facultyName;
  final String itemName;
  final String category;
  final int quantity;
  final String justification;
  final String priority;
  final String status;
  final DateTime requestDate;

  InventoryPurchaseRequest({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.justification,
    required this.priority,
    required this.status,
    required this.requestDate,
  });

  factory InventoryPurchaseRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryPurchaseRequest(
      id: doc.id,
      facultyId: data['facultyId'],
      facultyName: data['facultyName'],
      itemName: data['itemName'],
      category: data['category'],
      quantity: data['quantity'],
      justification: data['justification'],
      priority: data['priority'],
      status: data['status'],
      requestDate: (data['requestDate'] as Timestamp).toDate(),
    );
  }
}
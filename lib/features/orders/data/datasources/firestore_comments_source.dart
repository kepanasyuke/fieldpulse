import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fieldpulse/features/orders/data/dto/order_comment_dto.dart';
import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';

class FirestoreCommentsSource {
  FirestoreCommentsSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _comments(String orderId) =>
      _firestore
          .collection('orders')
          .doc(orderId)
          .collection('comments');

  Stream<OrderComment> watch(String orderId) => _comments(orderId)
      .orderBy('createdAt', descending: false)
      .limitToLast(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => OrderCommentDto.fromFirestore(
                orderId,
                _normalize(doc.data()),
              ).toDomain(),
            )
            .toList(growable: false),
      )
      .expand((comments) => comments);

  Future<void> add({
    required String orderId,
    required String author,
    required String text,
  }) => _comments(orderId).add({
    'author': author,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return {...data, 'createdAt': createdAt.toDate().toIso8601String()};
    }
    if (createdAt is DateTime) {
      return {...data, 'createdAt': createdAt.toIso8601String()};
    }
    return data;
  }
}

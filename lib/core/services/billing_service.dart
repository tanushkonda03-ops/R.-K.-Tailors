import 'package:cloud_firestore/cloud_firestore.dart';

class BillingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Atomically generates the next bill number (0001-9999, cycling).
  Future<String> generateBillNumber() async {
    final counterRef = _firestore.collection('counters').doc('billNumber');

    return _firestore.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int current;
      if (!snapshot.exists) {
        current = 1;
        transaction.set(counterRef, {'current': 1});
      } else {
        current = (snapshot.data()?['current'] as int? ?? 0) + 1;
        if (current > 9999) {
          current = 1;
        }
        transaction.update(counterRef, {'current': current});
      }

      return current.toString().padLeft(4, '0');
    });
  }

  /// Save a complete bill document to Firestore.
  Future<void> saveBill(Map<String, dynamic> billData) async {
    final billNo = billData['billNo'] as String;
    await _firestore.collection('bills').doc(billNo).set(billData);
  }

  /// Update an existing bill.
  Future<void> updateBill(String billNo, Map<String, dynamic> billData) async {
    await _firestore.collection('bills').doc(billNo).update(billData);
  }

  /// Fetch a single bill by its number.
  Future<Map<String, dynamic>?> getBillByNumber(String billNo) async {
    final doc = await _firestore.collection('bills').doc(billNo).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  /// Fetch all active bills for a specific user.
  Future<List<Map<String, dynamic>>> getActiveBillsForUser(String uid) async {
    final snapshot = await _firestore
        .collection('bills')
        .where('customerUid', isEqualTo: uid)
        .get();

    final docs = snapshot.docs.map((doc) => doc.data()).toList();

    // Sort locally by date descending to avoid requiring a Firestore composite index
    docs.sort((a, b) {
      final dateA = a['date'] as Timestamp?;
      final dateB = b['date'] as Timestamp?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return docs;
  }

  /// Permanently delete a bill from the database.
  Future<void> deleteBill(String billNo) async {
    await _firestore.collection('bills').doc(billNo).delete();
  }
}

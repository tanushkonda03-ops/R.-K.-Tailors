import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save measurements for a customer. Handles multiple reference images per garment.
  Future<void> saveMeasurements(String uid, Map<String, Map<String, dynamic>> measurements) async {
    final batch = _firestore.batch();

    for (var entry in measurements.entries) {
      final garment = entry.key;
      final payload = Map<String, dynamic>.from(entry.value);

      // Handle multiple reference images (List<String> of local paths)
      if (payload.containsKey('referenceImages') && payload['referenceImages'] != null) {
        final List<dynamic> imagePaths = payload['referenceImages'];
        final List<String> base64Images = [];

        for (var path in imagePaths) {
          if (path is String && path.isNotEmpty) {
            if (path.startsWith('data:image')) {
              // Already encoded (from DB fetch), keep as-is
              base64Images.add(path);
            } else {
              // Local file path — encode to base64
              final file = File(path);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                final base64 = base64Encode(bytes);
                base64Images.add('data:image/jpeg;base64,$base64');
              }
            }
          }
        }

        payload['referenceImagesBase64'] = base64Images;
        payload.remove('referenceImages');
      }

      final docRef = _firestore.collection('users').doc(uid).collection('measurements').doc(garment);
      payload['timestamp'] = FieldValue.serverTimestamp();
      batch.set(docRef, payload, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Fetch all saved measurements for a customer by UID.
  Future<Map<String, Map<String, dynamic>>> getMeasurements(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .get();

    final Map<String, Map<String, dynamic>> result = {};
    for (var doc in snapshot.docs) {
      result[doc.id] = doc.data();
    }
    return result;
  }

  /// Fetch a single garment's measurement by UID and garment name.
  Future<Map<String, dynamic>?> getGarmentMeasurement(String uid, String garment) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .doc(garment)
        .get();

    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}

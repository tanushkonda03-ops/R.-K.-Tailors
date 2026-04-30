import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // ----------------------------------------------------------------------
    // IMPORTANT: To test Google Sign-In on Web/Edge, get your Web Client ID
    // from Google Cloud Console -> APIs & Services -> Credentials
    // It looks like: 'xxxxxxx-yyyyyyy.apps.googleusercontent.com'
    // Paste it below, overwriting the placeholder string:
    // ----------------------------------------------------------------------
    clientId: kIsWeb
        ? '566312450956-k85hvemm427v816cev2r1mpa0j71hs12.apps.googleusercontent.com'
        : null,
  );

  /// Sign Up with Email, Password and Username
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'customerId': (10000 + Random().nextInt(90000)).toString(),
          'email': email,
          'username': username,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'email',
        });
      }
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  /// Log In with Email and Password
  Future<UserCredential?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In with Google
  /// Returns a Map: {'user': UserCredential, 'isNew': bool}
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Used cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userCred.user!.uid)
          .get();

      return {'user': userCred, 'isNew': !doc.exists};
    } catch (e) {
      rethrow;
    }
  }

  /// Complete Google Profile
  Future<void> completeGoogleProfile({
    required String uid,
    required String email,
    required String username,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'customerId': (10000 + Random().nextInt(90000)).toString(),
      'email': email,
      'username': username,
      'isAdmin': false,
      'createdAt': FieldValue.serverTimestamp(),
      'provider': 'google',
    });
  }

  /// Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

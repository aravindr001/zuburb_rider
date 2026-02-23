import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  Future<String> verifyPhoneNumber(String phoneNumber) {
    final completer = Completer<String>();

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(
          credential,
        );

        if (!completer.isCompleted) {
          completer.complete("AUTO_VERIFIED");
        }
      },

      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e.message ?? "Verification failed");
        }
      },

      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },

      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential> signInWithOtp(
    String verificationId,
    String smsCode,
  ) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    final user = userCredential.user;

    if (user == null) {
      throw Exception("User is null after login");
    }

    final riderRef = FirebaseFirestore.instance
        .collection("riders")
        .doc(user.uid);

    final doc = await riderRef.get();

    if (!doc.exists) {
      await riderRef.set({
        "phone": user.phoneNumber,
        "isOnline": true,
        "isAvailable": true,
        "currentRideId": null,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  User? get currentUser => _auth.currentUser;
}

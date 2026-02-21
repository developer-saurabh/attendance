import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AppUser?> get userStream async* {
    await for (final firebaseUser in _auth.authStateChanges()) {
      if (firebaseUser == null) {
        yield null;
      } else {
        final doc =
            await _db.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) {
          yield null;
        } else {
          yield AppUser.fromMap(firebaseUser.uid, doc.data()!);
        }
      }
    }
  }

  Future<AppUser?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(user.uid, doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();

  // Master will create faculty using this
  Future<void> createFaculty({
    required String email,
    required String password,
    required String name,
  }) async {
    // Create user with secondary app or cloud function IRL.
    // For demo, we just create a Firestore doc and ask master to share creds.
    // WARNING: This does NOT create real Firebase Auth user.
    // For a real app, you'd use Admin SDK / Cloud Function.

    final docRef = _db.collection('users').doc();
    await docRef.set({
      'email': email,
      'name': name,
      'role': 'faculty',
    });
  }
}

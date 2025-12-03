import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling Firebase Anonymous Authentication.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current authenticated user.
  User? get currentUser => _auth.currentUser;

  /// Get the current user's ID, or null if not authenticated.
  String? get userId => _auth.currentUser?.uid;

  /// Check if user is currently authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in anonymously.
  /// Returns the User if successful, throws exception on failure.
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Authentication failed',
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Ensure user is authenticated.
  /// Signs in anonymously if not already authenticated.
  /// Returns the user ID.
  Future<String> ensureAuthenticated() async {
    if (isAuthenticated) {
      return userId!;
    }

    final user = await signInAnonymously();
    if (user == null) {
      throw AuthException(
        code: 'auth-failed',
        message: 'Failed to authenticate anonymously',
      );
    }

    return user.uid;
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'AuthException($code): $message';
}

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/logger.dart';
import '../local/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

/// Repository for Authentication operations
/// Handles Firebase Auth and local user data
class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  final FirebaseFirestore _firestore;
  final AppDatabase _database;

  AuthRepository({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FlutterSecureStorage secureStorage,
    required FirebaseFirestore firestore,
    required AppDatabase database,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _secureStorage = secureStorage,
        _firestore = firestore,
        _database = database;

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.read(key: 'user_token');
      return token != null && _firebaseAuth.currentUser != null;
    } catch (e) {
      AppLogger.error('Error checking login status', e);
      return false;
    }
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      return _firebaseAuth.currentUser?.uid;
    } catch (e) {
      AppLogger.error('Error getting current user ID', e);
      return null;
    }
  }

  /// Send OTP to phone number
  Future<Either<Failure, String>> sendOTP(String phoneNumber) async {
    try {
      String? verificationId;
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          throw AuthException(message: e.message ?? 'Verification failed', code: e.code);
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait for verification ID
      await Future.delayed(const Duration(seconds: 2));
      
      if (verificationId != null) {
        AppLogger.info('OTP sent successfully');
        return Right(verificationId!);
      } else {
        return const Left(AuthFailure(message: 'Failed to send OTP'));
      }
    } on AuthException catch (e) {
      AppLogger.error('Auth error sending OTP', e);
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error sending OTP', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Verify OTP and sign in
  Future<Either<Failure, firebase_auth.User>> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        return const Left(AuthFailure(message: 'Sign in failed'));
      }

      // Save user token
      final token = await userCredential.user!.getIdToken();
      await _secureStorage.write(key: 'user_token', value: token);
      await _secureStorage.write(key: 'user_id', value: userCredential.user!.uid);

      // Create/update user profile
      await _createOrUpdateUserProfile(userCredential.user!);

      AppLogger.info('User signed in successfully');
      return Right(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Firebase auth error', e);
      return Left(AuthFailure(message: e.message ?? 'Verification failed'));
    } catch (e) {
      AppLogger.error('Unexpected error verifying OTP', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Sign in with Google
  Future<Either<Failure, firebase_auth.User>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return const Left(AuthFailure(message: 'Google sign in cancelled'));
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        return const Left(AuthFailure(message: 'Google sign in failed'));
      }

      // Save user token
      final token = await userCredential.user!.getIdToken();
      await _secureStorage.write(key: 'user_token', value: token);
      await _secureStorage.write(key: 'user_id', value: userCredential.user!.uid);

      // Create/update user profile
      await _createOrUpdateUserProfile(userCredential.user!);

      AppLogger.info('Google sign in successful');
      return Right(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Firebase auth error', e);
      return Left(AuthFailure(message: e.message ?? 'Google sign in failed'));
    } catch (e) {
      AppLogger.error('Unexpected error with Google sign in', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Create or update user profile in Firestore and local DB
  Future<void> _createOrUpdateUserProfile(firebase_auth.User firebaseUser) async {
    final now = DateTime.now();
    
    // Create user profile in Firestore
    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'phoneNumber': firebaseUser.phoneNumber,
      'email': firebaseUser.email,
      'name': firebaseUser.displayName ?? 'User',
      'photoUrl': firebaseUser.photoURL,
      'language': 'en',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save to local database
    final user = UsersCompanion(
      id: drift.Value(firebaseUser.uid),
      phoneNumber: drift.Value(firebaseUser.phoneNumber),
      email: drift.Value(firebaseUser.email),
      name: drift.Value(firebaseUser.displayName ?? 'User'),
      photoUrl: drift.Value(firebaseUser.photoURL),
      language: const drift.Value('en'),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
      isSynced: const drift.Value(true),
    );

    await _database.insertUser(user);
    AppLogger.info('User profile created/updated');
  }

  /// Sign out
  Future<Either<Failure, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _secureStorage.deleteAll();
      
      AppLogger.info('User signed out');
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error signing out', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get current user from local DB
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        return const Right(null);
      }

      final user = await _database.getUserById(userId);
      return Right(user);
    } catch (e) {
      AppLogger.error('Error getting current user', e);
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Update user profile
  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? photoUrl,
    String? language,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        return const Left(UnauthorizedFailure());
      }

      // Update in Firestore
      await _firestore.collection('users').doc(userId).update({
        if (name != null) 'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (language != null) 'language': language,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update in local DB
      final user = UsersCompanion(
        id: drift.Value(userId),
        name: name != null ? drift.Value(name) : const drift.Value.absent(),
        photoUrl: photoUrl != null ? drift.Value(photoUrl) : const drift.Value.absent(),
        language: language != null ? drift.Value(language) : const drift.Value.absent(),
        updatedAt: drift.Value(DateTime.now()),
        isSynced: const drift.Value(true),
      );

      await _database.updateUser(user);
      AppLogger.info('User profile updated');
      
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error updating profile', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }
}

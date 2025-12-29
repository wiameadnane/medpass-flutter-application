import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/user_model.dart';
import '../models/medical_file_model.dart';

/// Check if demo mode is enabled via .env
bool get _isDemoMode => dotenv.env['DEMO_MODE']?.toLowerCase() == 'true';

class UserProvider with ChangeNotifier {
  // Lazy initialization to avoid accessing Firebase when in demo mode
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAuth get _auth {
    _authInstance ??= FirebaseAuth.instance;
    return _authInstance!;
  }

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  UserModel? _user;
  List<MedicalFileModel> _medicalFiles = [];
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  List<MedicalFileModel> get medicalFiles => _medicalFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn {
    if (_isDemoMode) return _user != null;
    return _user != null && _auth.currentUser != null;
  }
  User? get firebaseUser => _isDemoMode ? null : _auth.currentUser;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    // In demo mode, don't check Firebase - just let user go to login screen
    if (_isDemoMode) {
      debugPrint('Demo mode - skipping Firebase auth check');
      return;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser.uid);
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = UserModel.fromJson({...doc.data()!, 'id': uid});
        await _loadMedicalFiles(uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Load medical files from Firestore
  Future<void> _loadMedicalFiles(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medical_files')
          .orderBy('uploadedAt', descending: true)
          .get();

      _medicalFiles = snapshot.docs
          .map((doc) => MedicalFileModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // If no files exist yet, use empty list
      _medicalFiles = [];
      debugPrint('Error loading medical files: $e');
    }
  }

  // Auth methods
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    // Demo mode - bypass Firebase authentication
    if (_isDemoMode) {
      debugPrint('Demo mode enabled - using demo user');
      _user = UserModel.demoUser;
      _medicalFiles = MedicalFileModel.demoFiles;
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      // Authenticate with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
        _setLoading(false);
        return true;
      }

      _setError('Login failed. Please try again.');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

      // Fallback for Windows/desktop where Firebase Auth may not work
      if (e.code == 'unknown-error' || e.code == 'configuration-not-found') {
        return _fallbackLogin(email, password);
      }

      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Login error: $e');

      // Fallback for platforms where Firebase Auth is not supported
      if (e.toString().contains('unknown-error') ||
          e.toString().contains('internal error') ||
          e.toString().contains('configuration-not-found')) {
        return _fallbackLogin(email, password);
      }

      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Fallback login for platforms where Firebase Auth doesn't work (Windows/Linux)
  Future<bool> _fallbackLogin(String email, String password) async {
    debugPrint('Using fallback login for desktop platform');
    try {
      // Try to find user in Firestore by email
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        _user = UserModel.fromJson({...userDoc.docs.first.data(), 'id': userDoc.docs.first.id});
        await _loadMedicalFiles(_user!.id);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('No account found with this email.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('Fallback login error: $e');
      _setError('Login failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    DateTime? dateOfBirth,
    String? gender,
    String? nationality,
    String preferredLanguage = 'en',
  }) async {
    _setLoading(true);
    _clearError();

    // Demo mode - bypass Firebase authentication
    if (_isDemoMode) {
      debugPrint('Demo mode enabled - creating demo user');
      _user = UserModel(
        id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        email: email.trim(),
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        nationality: nationality,
        preferredLanguage: preferredLanguage,
        createdAt: DateTime.now(),
      );
      _medicalFiles = [];
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        // Create user model
        _user = UserModel(
          id: uid,
          fullName: fullName,
          email: email.trim(),
          phoneNumber: phoneNumber,
          dateOfBirth: dateOfBirth,
          gender: gender,
          nationality: nationality,
          preferredLanguage: preferredLanguage,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await _firestore.collection('users').doc(uid).set(_user!.toJson());

        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(fullName);

        _medicalFiles = [];
        _setLoading(false);
        notifyListeners();
        return true;
      }

      _setError('Sign up failed. Please try again.');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException on signup: ${e.code} - ${e.message}');

      // Fallback for Windows/desktop where Firebase Auth may not work
      if (e.code == 'unknown-error' || e.code == 'configuration-not-found') {
        return _fallbackSignUp(fullName, email, phoneNumber, dateOfBirth, gender, nationality, preferredLanguage);
      }

      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('SignUp error: $e');

      // Fallback for platforms where Firebase Auth is not supported
      if (e.toString().contains('unknown-error') ||
          e.toString().contains('internal error') ||
          e.toString().contains('configuration-not-found')) {
        return _fallbackSignUp(fullName, email, phoneNumber, dateOfBirth, gender, nationality, preferredLanguage);
      }

      _setError('Sign up failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Fallback signup for platforms where Firebase Auth doesn't work (Windows/Linux)
  Future<bool> _fallbackSignUp(String fullName, String email, String phoneNumber, DateTime? dateOfBirth, String? gender, String? nationality, String preferredLanguage) async {
    debugPrint('Using fallback signup for desktop platform');
    try {
      // Check if user already exists
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        _setError('An account already exists with this email.');
        _setLoading(false);
        return false;
      }

      // Create new user in Firestore only
      final newId = _firestore.collection('users').doc().id;
      _user = UserModel(
        id: newId,
        fullName: fullName,
        email: email.trim(),
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        nationality: nationality,
        preferredLanguage: preferredLanguage,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(newId).set(_user!.toJson());
      _medicalFiles = [];
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Fallback signup error: $e');
      _setError('Sign up failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (!_isDemoMode) {
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    _user = null;
    _medicalFiles = [];
    notifyListeners();
  }

  // Password reset
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to send reset email. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Profile methods
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bloodType,
    double? height,
    double? weight,
    String? nationality,
    String? gender,
    String? preferredLanguage,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    List<EmergencyContact>? additionalEmergencyContacts,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      _user = _user!.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        bloodType: bloodType,
        height: height,
        weight: weight,
        nationality: nationality,
        gender: gender,
        preferredLanguage: preferredLanguage,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        emergencyContactRelation: emergencyContactRelation,
        additionalEmergencyContacts: additionalEmergencyContacts,
        allergies: allergies,
        medicalConditions: medicalConditions,
        currentMedications: currentMedications,
      );

      // Persist the update to Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        ..._user!.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update display name if changed (only if not demo mode)
      if (fullName != null && !_isDemoMode && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(fullName);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Update failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Medical files methods
  Future<bool> addMedicalFile(MedicalFileModel file) async {
    // Allow operation if we have either a Firestore-backed _user (from fallback)
    // or an authenticated Firebase user. Use whichever uid is available.
    if (_user == null && _auth.currentUser == null) return false;

    final uid = _auth.currentUser?.uid ?? _user!.id;

    _setLoading(true);
    _clearError();

    try {
      // Add to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medical_files')
          .add(file.toJson());

      // Add to local list with the generated ID
      final newFile = MedicalFileModel(
        id: docRef.id,
        name: file.name,
        category: file.category,
        description: file.description,
        fileUrl: file.fileUrl,
        uploadedAt: file.uploadedAt,
        isImportant: file.isImportant,
      );
      _medicalFiles.insert(0, newFile);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('addMedicalFile error: $e');
      _setError('Failed to add file. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeMedicalFile(String fileId) async {
    if (_user == null && _auth.currentUser == null) return false;

    final uid = _auth.currentUser?.uid ?? _user!.id;

    _setLoading(true);
    _clearError();

    try {
      // Find the file to get its URL for storage deletion
      final file = _medicalFiles.firstWhere(
        (f) => f.id == fileId,
        orElse: () => MedicalFileModel(id: '', name: '', category: FileCategory.other),
      );

      // Delete from Firebase Storage if file has a URL
      if (file.fileUrl != null && file.fileUrl!.isNotEmpty) {
        try {
          // Extract the storage path from the URL
          final ref = FirebaseStorage.instance.refFromURL(file.fileUrl!);
          await ref.delete();
          debugPrint('Deleted file from Storage: ${ref.fullPath}');
        } catch (storageError) {
          // Log but don't fail if storage deletion fails (file might not exist)
          debugPrint('Storage deletion error (continuing): $storageError');
        }
      }

      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('medical_files')
          .doc(fileId)
          .delete();

      // Remove from local list
      _medicalFiles.removeWhere((file) => file.id == fileId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('removeMedicalFile error: $e');
      _setError('Failed to remove file. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> toggleFileImportant(String fileId) async {
    if (_user == null && _auth.currentUser == null) return false;

    final uid = _auth.currentUser?.uid ?? _user!.id;

    try {
      final fileIndex = _medicalFiles.indexWhere((f) => f.id == fileId);
      if (fileIndex == -1) return false;

      final file = _medicalFiles[fileIndex];
      final newImportant = !file.isImportant;

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('medical_files')
          .doc(fileId)
          .update({'isImportant': newImportant});

      // Update local list
      _medicalFiles[fileIndex] = file.copyWith(isImportant: newImportant);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('toggleFileImportant error: $e');
      return false;
    }
  }

  List<MedicalFileModel> getFilesByCategory(FileCategory category) {
    return _medicalFiles.where((file) => file.category == category).toList();
  }

  List<MedicalFileModel> get importantFiles {
    return _medicalFiles.where((file) => file.isImportant).toList();
  }

  // Search files
  List<MedicalFileModel> searchFiles(String query) {
    if (query.isEmpty) return _medicalFiles;
    final lowerQuery = query.toLowerCase();
    return _medicalFiles.where((file) {
      return file.name.toLowerCase().contains(lowerQuery) ||
          (file.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          file.categoryName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Subscription methods
  Future<bool> upgradeToPremium() async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      _user = _user!.copyWith(isPremium: true);

      // Update in Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'is_premium': true,
        'premium_since': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Upgrade failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelPremium() async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      _user = _user!.copyWith(isPremium: false);

      // Update in Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'is_premium': false,
        'premium_cancelled_at': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Cancellation failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Scan count tracking methods

  /// Check if the user can perform a scan (within monthly limit for free users)
  bool canPerformScan() {
    if (_user == null) return false;
    if (_user!.isPremium) return true;

    // Check if month has reset
    final shouldReset = _shouldResetScanCount();
    final currentCount = shouldReset ? 0 : _user!.monthlyScanCount;

    return currentCount < 10; // Free limit is 10 scans/month
  }

  /// Get remaining scans for the current month
  int getRemainingScans() {
    if (_user == null) return 0;
    if (_user!.isPremium) return -1; // Unlimited

    final shouldReset = _shouldResetScanCount();
    final currentCount = shouldReset ? 0 : _user!.monthlyScanCount;

    return (10 - currentCount).clamp(0, 10);
  }

  /// Get current monthly scan count
  int get monthlyScanCount {
    if (_user == null) return 0;
    final shouldReset = _shouldResetScanCount();
    return shouldReset ? 0 : _user!.monthlyScanCount;
  }

  bool _shouldResetScanCount() {
    if (_user?.lastScanResetDate == null) return true;
    final now = DateTime.now();
    final lastReset = _user!.lastScanResetDate!;
    return now.year > lastReset.year || now.month > lastReset.month;
  }

  /// Increment scan count after a successful scan
  Future<void> incrementScanCount() async {
    if (_user == null) return;
    if (_user!.isPremium) return; // Premium users don't track scans

    try {
      final shouldReset = _shouldResetScanCount();
      final newCount = shouldReset ? 1 : _user!.monthlyScanCount + 1;
      final now = DateTime.now();

      _user = _user!.copyWith(
        monthlyScanCount: newCount,
        lastScanResetDate: shouldReset ? now : _user!.lastScanResetDate,
      );

      // Update in Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'monthly_scan_count': newCount,
        if (shouldReset) 'last_scan_reset_date': Timestamp.fromDate(now),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update scan count: $e');
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_isDemoMode) {
      _setError('Password change is not available in demo mode');
      return false;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email == null) {
      _setError('No user logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(newPassword);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException on password change: ${e.code}');
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Password change error: $e');
      if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        _setError('Current password is incorrect');
      } else {
        _setError('Failed to change password. Please try again.');
      }
      _setLoading(false);
      return false;
    }
  }

  // Delete account permanently
  Future<bool> deleteAccount({required String password}) async {
    if (_isDemoMode) {
      _setError('Account deletion is not available in demo mode');
      return false;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email == null) {
      _setError('No user logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Re-authenticate user before deletion
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);

      final uid = currentUser.uid;

      // Delete all medical files from Storage
      for (final file in _medicalFiles) {
        if (file.fileUrl != null && file.fileUrl!.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(file.fileUrl!);
            await ref.delete();
          } catch (e) {
            debugPrint('Error deleting file from storage: $e');
          }
        }
      }

      // Delete medical files collection from Firestore
      final filesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medical_files')
          .get();

      for (final doc in filesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete Firebase Auth account
      await currentUser.delete();

      // Clear local data
      _user = null;
      _medicalFiles = [];

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException on account deletion: ${e.code}');
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Account deletion error: $e');
      if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        _setError('Password is incorrect');
      } else {
        _setError('Failed to delete account. Please try again.');
      }
      _setLoading(false);
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (!_isDemoMode && _auth.currentUser != null) {
      await _loadUserData(_auth.currentUser!.uid);
    }
  }

  // Refresh all data (user + files) - for pull-to-refresh
  Future<void> refreshData() async {
    if (_user != null) {
      final uid = _auth.currentUser?.uid ?? _user!.id;
      await _loadUserData(uid);
      await _loadMedicalFiles(uid);
      notifyListeners();
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Demo login for quick testing (development only)
  void loginWithDemoUser() {
    _user = UserModel.demoUser;
    _medicalFiles = MedicalFileModel.demoFiles;
    notifyListeners();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

enum SupabaseAuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class SupabaseAuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  StreamSubscription<AuthState>? _authStateSubscription;
  
  SupabaseAuthStatus _status = SupabaseAuthStatus.uninitialized;
  User? _user;
  UserProfile? _userProfile;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  SupabaseAuthStatus get status => _status;
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == SupabaseAuthStatus.authenticated;
  String? get currentUserId => _user?.id;
  String get displayName => _user?.userMetadata?['name'] ?? _user?.email?.split('@').first ?? 'User';

  SupabaseAuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Set up the listener first
      _authStateSubscription = _supabase.auth.onAuthStateChange.listen(_onAuthStateChanged);
      
      // Check current session
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _onAuthStateChanged(AuthState(AuthChangeEvent.signedIn, session));
      } else {
        _setStatus(SupabaseAuthStatus.unauthenticated);
      }
      
      debugPrint('✅ SupabaseAuthProvider initialized');
    } catch (e) {
      debugPrint('❌ SupabaseAuthProvider initialization failed: $e');
      _setStatus(SupabaseAuthStatus.unauthenticated);
    }
  }

  void _onAuthStateChanged(AuthState authState) {
    debugPrint('🔄 Supabase Auth state changed: ${authState.event}');
    _user = authState.session?.user;
    _clearError();

    if (_user == null) {
      debugPrint('👤 No user, setting unauthenticated status');
      _userProfile = null;
      _setStatus(SupabaseAuthStatus.unauthenticated);
    } else {
      debugPrint('👤 User found: ${_user!.email}');
      _loadUserProfile(_user!);
      _setStatus(SupabaseAuthStatus.authenticated);
    }
  }

  Future<void> _loadUserProfile(User user) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (response != null) {
        _userProfile = UserProfile(
          uid: user.id,
          name: response['name'] ?? user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          department: response['department'] ?? 'Computer Science',
          year: response['year'] ?? 2024,
          photoUrl: response['photo_url'],
          bio: response['bio'] ?? 'MarketISM user',
          createdAt: DateTime.parse(response['created_at'] ?? DateTime.now().toIso8601String()),
          role: UserRole.values.firstWhere(
            (role) => role.toString() == 'UserRole.${response['role'] ?? 'user'}',
            orElse: () => UserRole.user,
          ),
        );
      } else {
        // Create default profile
        _userProfile = UserProfile(
          uid: user.id,
          name: user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          department: 'Computer Science',
          year: 2024,
          photoUrl: null,
          bio: 'MarketISM user',
          createdAt: DateTime.now(),
          role: UserRole.user,
        );
        
        // Save to Supabase
        await _createUserProfile(_userProfile!);
      }
      
      debugPrint('👤 User profile loaded: ${_userProfile!.name}');
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
      // Create a basic profile even if database fails
      _userProfile = UserProfile(
        uid: user.id,
        name: user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
        department: 'Computer Science',
        year: 2024,
        photoUrl: null,
        bio: 'MarketISM user',
        createdAt: DateTime.now(),
        role: UserRole.user,
      );
    }
  }

  // Authentication methods
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('🔐 Starting Supabase sign in for: $email');
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('✅ Supabase sign in successful');
        return true;
      } else {
        _setError('Sign in failed. Please try again.');
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase sign in failed: ${e.message}');
      _setError(_getSupabaseErrorMessage(e));
      return false;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      debugPrint('🔐 Starting Supabase sign up for: $email');
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.user != null) {
        debugPrint('✅ Supabase sign up successful');
        return true;
      } else {
        _setError('Sign up failed. Please try again.');
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase sign up failed: ${e.message}');
      _setError(_getSupabaseErrorMessage(e));
      return false;
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      _setError(_getSupabaseErrorMessage(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('🚪 Starting Supabase sign out');
      _setLoading(true);
      _clearError();

      await _supabase.auth.signOut();
      
      debugPrint('✅ Supabase sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      _setError('Failed to sign out. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Profile management methods
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        return UserProfile(
          uid: userId,
          name: response['name'] ?? 'User',
          email: response['email'] ?? '',
          department: response['department'] ?? 'Computer Science',
          year: response['year'] ?? 2024,
          photoUrl: response['photo_url'],
          bio: response['bio'] ?? 'MarketISM user',
          createdAt: DateTime.parse(response['created_at'] ?? DateTime.now().toIso8601String()),
          role: UserRole.values.firstWhere(
            (role) => role.toString() == 'UserRole.${response['role'] ?? 'user'}',
            orElse: () => UserRole.user,
          ),
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get user profile failed: $e');
      _setError(e.toString());
      return null;
    }
  }

  Future<String?> uploadProfileImage(dynamic imageFile) async {
    try {
      // TODO: Implement Supabase Storage upload
      await Future.delayed(const Duration(milliseconds: 1000));
      return 'https://via.placeholder.com/150';
    } catch (e) {
      debugPrint('❌ Upload profile image failed: $e');
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    try {
      _setLoading(true);
      _clearError();

      if (_user == null) {
        _setError('No authenticated user');
        return false;
      }

      // Update Supabase table
      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', _user!.id);

      // Update local profile
      if (_userProfile != null) {
        _userProfile = UserProfile(
          uid: _userProfile!.uid,
          name: updateData['name'] ?? _userProfile!.name,
          email: _userProfile!.email,
          department: updateData['department'] ?? _userProfile!.department,
          year: updateData['year'] ?? _userProfile!.year,
          photoUrl: updateData['photo_url'] ?? _userProfile!.photoUrl,
          bio: updateData['bio'] ?? _userProfile!.bio,
          createdAt: _userProfile!.createdAt,
          role: _userProfile!.role,
        );
        notifyListeners();
      }

      debugPrint('✅ Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Update profile failed: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _createUserProfile(UserProfile profile) async {
    try {
      await _supabase.from('users').insert({
        'id': profile.uid,
        'name': profile.name,
        'email': profile.email,
        'department': profile.department,
        'year': profile.year,
        'photo_url': profile.photoUrl,
        'bio': profile.bio,
        'role': profile.role.toString().split('.').last,
        'created_at': profile.createdAt.toIso8601String(),
      });

      debugPrint('✅ User profile created in Supabase');
      return true;
    } catch (e) {
      debugPrint('❌ Create user profile failed: $e');
      return false;
    }
  }

  // Helper methods
  void _setStatus(SupabaseAuthStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    _clearError();
  }

  String _getSupabaseErrorMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password.';
      case 'Email not confirmed':
        return 'Please check your email and click the confirmation link.';
      case 'User already registered':
        return 'An account already exists with this email address.';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
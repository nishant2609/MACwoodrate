import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/company.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final CompanyService _companyService = CompanyService();

  AppUser? _currentUser;
  Company? _currentCompany;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get hasCompany => _currentCompany != null;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData();
      } else {
        _currentUser = null;
        _currentCompany = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = await _authService.getCurrentUserData();

      if (_currentUser?.companyId != null) {
        _currentCompany =
        await _companyService.getCompany(_currentUser!.companyId!);
      }

      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Sign up
  Future<Map<String, dynamic>> signUp(
      String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signUp(
      email: email,
      password: password,
      name: name,
    );

    if (result['success']) {
      await _loadUserData();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Sign in
  Future<Map<String, dynamic>> signIn(
      String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signIn(
      email: email,
      password: password,
    );

    if (result['success']) {
      await _loadUserData();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Google sign in
  Future<Map<String, dynamic>> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signInWithGoogle();

    if (result['success']) {
      await _loadUserData();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _currentUser = null;
    _currentCompany = null;

    _isLoading = false;
    notifyListeners();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    return await _authService.resetPassword(email: email);
  }

  // Set company
  Future<void> setCurrentCompany(Company company) async {
    _currentCompany = company;

    if (_currentUser != null) {
      await _authService.updateUserCompany(company.id);
      _currentUser = _currentUser!.copyWith(companyId: company.id);
    }

    notifyListeners();
  }

  // Refresh company data
  Future<void> refreshCompanyData() async {
    if (_currentUser?.companyId != null) {
      _currentCompany =
      await _companyService.getCompany(_currentUser!.companyId!);
      notifyListeners();
    }
  }
}
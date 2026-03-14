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
  bool _isReady = false;

  AppUser? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
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
      }
      _isReady = true;
      notifyListeners();
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

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _currentUser = null;
    _currentCompany = null;
    _isReady = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    return await _authService.resetPassword(email: email);
  }

  Future<void> setCurrentCompany(Company company) async {
    _currentCompany = company;
    if (_currentUser != null) {
      await _authService.updateUserCompany(company.id);
      _currentUser = _currentUser!.copyWith(companyId: company.id);
    }
    notifyListeners();
  }

  Future<void> refreshCompanyData() async {
    if (_currentUser?.companyId != null) {
      _currentCompany =
      await _companyService.getCompany(_currentUser!.companyId!);
      notifyListeners();
    }
  }
}
import '../models/user.dart';

abstract class AuthService {
  Future<User?> getCurrentUser();
  Future<User> signIn(String email, String password);
  Future<void> signOut();
}

class MockAuthService implements AuthService {
  User _currentUser = const User(
    id: 'USR-8821',
    name: 'Security Officer',
    email: 'officer@scamshield.io',
    role: 'Lead SecOps Officer',
    isSecOpsAdmin: true,
  );

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<User> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _currentUser = User(
      id: 'USR-8821',
      name: email.split('@').first.toUpperCase(),
      email: email,
      role: 'Security Analyst',
      isSecOpsAdmin: true,
    );
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

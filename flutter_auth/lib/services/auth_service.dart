import 'package:auth0_flutter/auth0_flutter.dart';
import '../auth0_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:local_auth/local_auth.dart' as local_auth;

class AuthService {
  late final Auth0 auth0;
  final localAuth = local_auth.LocalAuthentication();
  Timer? _sessionTimer;
  final _sessionTimeout = const Duration(minutes: 30);
  final _sessionWarning = const Duration(minutes: 5);
  bool _isRememberMe = false;
  bool _isBiometricEnabled = false;

  AuthService() {
    auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);
    debugPrint('AuthService initialized with domain: ${Auth0Config.domain}');
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      _isBiometricEnabled = canCheckBiometrics && isDeviceSupported;
      debugPrint('Biometric authentication available: $_isBiometricEnabled');
    } catch (e) {
      debugPrint('Error checking biometric support: $e');
      _isBiometricEnabled = false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!_isBiometricEnabled) {
        throw Exception('Biometric authentication is not available on this device');
      }

      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const local_auth.AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        debugPrint('Biometric authentication successful');
        return true;
      } else {
        debugPrint('Biometric authentication failed');
        return false;
      }
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  void setRememberMe(bool value) {
    _isRememberMe = value;
    debugPrint('Remember Me set to: $value');
  }

  Future<void> _startSessionTimer() async {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      debugPrint('Session timeout reached');
      logout();
    });
  }

  Future<void> _checkSessionExpiry() async {
    try {
      final credentials = await auth0.credentialsManager.credentials();
      if (credentials == null) return;

      final expiryTime = DateTime.fromMillisecondsSinceEpoch(
        credentials.expiresAt.millisecondsSinceEpoch,
      );
      final timeUntilExpiry = expiryTime.difference(DateTime.now());

      if (timeUntilExpiry <= _sessionWarning) {
        debugPrint('Session expiring soon: ${timeUntilExpiry.inMinutes} minutes remaining');
        // You can emit an event or callback here to show a warning to the user
      }
    } catch (e) {
      debugPrint('Error checking session expiry: $e');
    }
  }

  Future<Credentials> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting login for email: $email');
      debugPrint('Using Auth0 configuration - Domain: ${Auth0Config.domain}');
      
      // Try native password realm authentication
      try {
        final credentials = await auth0.api.login(
          usernameOrEmail: email,
          password: password,
          connectionOrRealm: 'Username-Password-Authentication',
          scopes: {'openid', 'profile', 'email'},
        );
        
        debugPrint('Native login successful!');
        debugPrint('Access token received: ${credentials.accessToken.substring(0, 10)}...');
        if (credentials.idToken != null) {
          debugPrint('ID token received');
        }

        if (_isRememberMe) {
          await auth0.credentialsManager.storeCredentials(credentials);
          debugPrint('Credentials saved for remember me');
        }
        
        _startSessionTimer();
        return credentials;
      } catch (nativeError) {
        debugPrint('Native login failed: $nativeError');
        throw Exception('Login failed: Invalid credentials');
      }
    } catch (e) {
      debugPrint('Login failed with error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to login: $e');
    }
  }

  Future<Credentials> loginWithGoogle() async {
    try {
      debugPrint('Attempting Google login');
      debugPrint('Using Auth0 configuration - Domain: ${Auth0Config.domain}');
      
      final credentials = await auth0.webAuthentication(
        scheme: 'parkenstein.88.flutter-auth'
      ).login(
        parameters: {
          'connection': 'google-oauth2',
          'scope': 'openid profile email',
        },
      );
      
      debugPrint('Google login successful!');
      debugPrint('Access token received: ${credentials.accessToken.substring(0, 10)}...');
      if (credentials.idToken != null) {
        debugPrint('ID token received');
      }

      if (_isRememberMe) {
        await auth0.credentialsManager.storeCredentials(credentials);
        debugPrint('Credentials saved for remember me');
      }
      
      _startSessionTimer();
      return credentials;
    } catch (e) {
      debugPrint('Google login failed with error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to login with Google: $e');
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('Attempting logout');
      
      // First try to clear any web authentication session
      try {
        await auth0.webAuthentication(
          scheme: 'parkenstein.88.flutter-auth'
        ).logout();
        debugPrint('Web authentication session cleared');
      } catch (e) {
        debugPrint('Error clearing web authentication session: $e');
      }
      
      // Then try to clear any API session
      try {
        await auth0.credentialsManager.clearCredentials();
        debugPrint('API credentials cleared');
      } catch (e) {
        debugPrint('Error clearing API credentials: $e');
      }
      
      _sessionTimer?.cancel();
      debugPrint('Session timer cancelled');
      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout failed with error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Even if there's an error, we'll consider the logout successful
      // as we're just clearing the local session
      debugPrint('Continuing with logout despite error');
    }
  }

  Future<Credentials> signup({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting signup for email: $email');
      debugPrint('Using Auth0 configuration - Domain: ${Auth0Config.domain}');
      
      // Create user and sign them in
      final user = await auth0.api.signup(
        email: email,
        password: password,
        connection: 'Username-Password-Authentication',
      );
      
      debugPrint('User created successfully, now logging in');
      
      // After signup, we need to log in to get the credentials
      final credentials = await auth0.api.login(
        usernameOrEmail: email,
        password: password,
        connectionOrRealm: 'Username-Password-Authentication',
        scopes: {'openid', 'profile', 'email'},
      );
      
      debugPrint('Signup and login successful!');
      debugPrint('Access token received: ${credentials.accessToken.substring(0, 10)}...');
      if (credentials.idToken != null) {
        debugPrint('ID token received');
      }

      if (_isRememberMe) {
        await auth0.credentialsManager.storeCredentials(credentials);
        debugPrint('Credentials saved for remember me');
      }
      
      _startSessionTimer();
      return credentials;
    } catch (e) {
      debugPrint('Signup failed with error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to signup: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final credentials = await auth0.credentialsManager.credentials();
      if (credentials == null) return null;

      final userProfile = await auth0.api.userProfile(
        accessToken: credentials.accessToken,
      );

      return {
        'email': userProfile.email,
        'name': userProfile.name,
        'picture': userProfile.pictureUrl,
        'emailVerified': userProfile.isEmailVerified,
        'updatedAt': userProfile.updatedAt,
      };
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? picture,
  }) async {
    try {
      final credentials = await auth0.credentialsManager.credentials();
      if (credentials == null) throw Exception('No active session');

      // For now, we'll just show a message that profile updates are not supported
      // To implement profile updates, you would need to:
      // 1. Set up an Auth0 Management API token
      // 2. Create a backend API to handle profile updates
      // 3. Call your backend API from here
      
      throw Exception('Profile updates are not supported in this version. Please contact support for assistance.');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
} 
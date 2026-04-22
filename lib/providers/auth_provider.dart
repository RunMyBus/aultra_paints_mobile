import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_token_store.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _userId;
  String? _userFullName;
  String? _userMobileNumber;
  String? _userAccountType;
  String? _userEmail;
  String? _userParentDealerCode;
  String? _userParentDealerMobile;
  String? _userParentDealerName;
  bool _isInitialized = false;

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get userFullName => _userFullName;
  String? get userMobileNumber => _userMobileNumber;
  String? get userAccountType => _userAccountType;
  String? get userEmail => _userEmail;
  String? get userParentDealerCode => _userParentDealerCode;
  String? get userParentDealerMobile => _userParentDealerMobile;
  String? get userParentDealerName => _userParentDealerName;
  bool get isInitialized => _isInitialized;

  // Initialize auth state from storage. Token lives in secure storage now;
  // non-sensitive profile fields stay in SharedPreferences.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _accessToken = await SecureTokenStore.instance.readToken();
    _userId = prefs.getString('USER_ID');
    _userFullName = prefs.getString('USER_FULL_NAME');
    _userMobileNumber = prefs.getString('USER_MOBILE_NUMBER');
    _userAccountType = prefs.getString('USER_ACCOUNT_TYPE');
    _userEmail = prefs.getString('USER_EMAIL');
    _userParentDealerCode = prefs.getString('USER_PARENT_DEALER_CODE');
    _userParentDealerMobile = prefs.getString('userParentDealerMobile');
    _userParentDealerName = prefs.getString('userParentDealerName');
    _isInitialized = true;
    notifyListeners();
  }

  // Set auth data
  Future<void> setAuthData({
    required String accessToken,
    required String userId,
    required String userFullName,
    required String userMobileNumber,
    required String userAccountType,
    required String userEmail,
    required String userParentDealerCode,
    required String userParentDealerMobile,
    required String userParentDealerName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Token goes to secure storage; profile fields to plain prefs.
    await SecureTokenStore.instance.writeToken(accessToken);
    await prefs.remove('accessToken'); // clear any legacy plaintext copy
    await prefs.setString('USER_ID', userId);
    await prefs.setString('USER_FULL_NAME', userFullName);
    await prefs.setString('USER_MOBILE_NUMBER', userMobileNumber);
    await prefs.setString('USER_ACCOUNT_TYPE', userAccountType);
    await prefs.setString('USER_EMAIL', userEmail);
    await prefs.setString('USER_PARENT_DEALER_CODE', userParentDealerCode);
    await prefs.setString('userParentDealerMobile', userParentDealerMobile);
    await prefs.setString('userParentDealerName', userParentDealerName);

    _accessToken = accessToken;
    _userId = userId;
    _userFullName = userFullName;
    _userMobileNumber = userMobileNumber;
    _userAccountType = userAccountType;
    _userEmail = userEmail;
    _userParentDealerCode = userParentDealerCode;
    _userParentDealerMobile = userParentDealerMobile;
    _userParentDealerName = userParentDealerName;
    _isInitialized = true;

    notifyListeners();
  }

  // Clear auth data (logout)
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();

    await SecureTokenStore.instance.clear();
    await prefs.remove('accessToken');
    await prefs.remove('USER_ID');
    await prefs.remove('USER_FULL_NAME');
    await prefs.remove('USER_MOBILE_NUMBER');
    await prefs.remove('USER_ACCOUNT_TYPE');
    await prefs.remove('USER_EMAIL');
    await prefs.remove('USER_PARENT_DEALER_CODE');
    await prefs.remove('userParentDealerMobile');
    await prefs.remove('userParentDealerName');

    _accessToken = null;
    _userId = null;
    _userFullName = null;
    _userMobileNumber = null;
    _userAccountType = null;
    _userEmail = null;
    _userParentDealerCode = null;
    _userParentDealerMobile = null;
    _userParentDealerName = null;

    notifyListeners();
  }

  // Check if user is authenticated
  bool get isAuthenticated {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  // Get headers for API requests
  Map<String, String> get authHeaders {
    return {
      "Content-Type": "application/json",
      if (_accessToken != null && _accessToken!.isNotEmpty)
        "Authorization": _accessToken!,
    };
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyIsVerified = 'is_verified'; 
  static const String _keyHasOrganization = 'has_organization'; 
  
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyOrganizationId = 'organization_id';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveAuthData({
    required String token,
    required String userId,
    required String email,
    required String fullName,
    required String expireAt,
    String? refreshToken,
  }) async {
    await _prefs.setString(_keyToken, token);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserFullName, fullName);
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyTokenExpiry, expireAt);
    if (refreshToken != null) {
      await _prefs.setString(_keyRefreshToken, refreshToken);
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_keyToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<void> saveOrganizationId(String orgId) async {
    await _prefs.setString(_keyOrganizationId, orgId);
  }

  // ✅ حفظ حالة وجود منظمة
  Future<void> saveHasOrganization(bool value) async {
    await _prefs.setBool(_keyHasOrganization, value);
  }

  // ✅ حفظ حالة التحقق
  Future<void> saveIsVerified(bool value) async {
    await _prefs.setBool(_keyIsVerified, value);
  }

  String? get token => _prefs.getString(_keyToken);
  String? get userId => _prefs.getString(_keyUserId);
  String? get userEmail => _prefs.getString(_keyUserEmail);
  String? get userFullName => _prefs.getString(_keyUserFullName);
  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  String? get tokenExpiry => _prefs.getString(_keyTokenExpiry);
  String? get refreshToken => _prefs.getString(_keyRefreshToken);
  String? get organizationId => _prefs.getString(_keyOrganizationId);

  // ✅ قراءة حالة التحقق
  bool get isVerified => _prefs.getBool(_keyIsVerified) ?? false;
  
  bool get hasOrganization => _prefs.getBool(_keyHasOrganization) ?? false;

  bool get isGuest => token == null || token!.isEmpty;
  String? get currentUserOrgId => organizationId;

  Future<void> logout() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserFullName);
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyTokenExpiry);
    await _prefs.remove(_keyIsVerified); // ✅ إضافة
    await _prefs.remove(_keyHasOrganization);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyOrganizationId);
  }

  bool get isTokenValid {
    final expiry = tokenExpiry;
    if (expiry == null) return false;

    try {
      final expiryDate = DateTime.parse(expiry);
      return expiryDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}

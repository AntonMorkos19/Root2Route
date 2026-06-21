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
  static const String _keyIsFirstTime = 'is_first_time';
  static const String _keyIsExplicitGuest = 'is_explicit_guest';

  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyOrganizationId = 'organization_id';
  static const String _keyOrganizationType = 'organization_type';
  static const String _keyOrganizationStatus = 'organization_status';

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
    await _prefs.remove(_keyIsExplicitGuest);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_keyToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await _prefs.remove(_keyIsExplicitGuest);
  }

  Future<void> saveOrganizationId(String orgId) async {
    await _prefs.setString(_keyOrganizationId, orgId);
  }

  Future<void> saveHasOrganization(bool value) async {
    await _prefs.setBool(_keyHasOrganization, value);
  }

  Future<void> saveOrganizationDetails({
    required String orgId,
    required int orgType,
    int status = 0,
  }) async {
    await _prefs.setString(_keyOrganizationId, orgId);
    await _prefs.setInt(_keyOrganizationType, orgType);
    await _prefs.setBool(_keyHasOrganization, true);
    await _prefs.setInt(_keyOrganizationStatus, status);
  }

  // Save organization status (0 = Pending, 1 = Approved)
  Future<void> saveOrganizationStatus(int status) async {
    await _prefs.setInt(_keyOrganizationStatus, status);
  }

  // ✅ Save organization type
  Future<void> saveOrganizationType(int type) async {
    await _prefs.setInt(_keyOrganizationType, type);
  }

  // ✅ Save is first time status
  Future<void> saveIsFirstTime(bool value) async {
    await _prefs.setBool(_keyIsFirstTime, value);
  }

  // ✅ Save explicit guest status
  Future<void> saveIsExplicitGuest(bool value) async {
    await _prefs.setBool(_keyIsExplicitGuest, value);
  }

  // ✅ Save verification status
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
  int? get organizationType => _prefs.getInt(_keyOrganizationType);
  // 0 = Pending, 1 = Approved
  int get organizationStatus => _prefs.getInt(_keyOrganizationStatus) ?? 1;

  // ✅ Read verification status
  bool get isVerified => _prefs.getBool(_keyIsVerified) ?? false;

  bool get hasOrganization => _prefs.getBool(_keyHasOrganization) ?? false;

  bool get isFirstTime => _prefs.getBool(_keyIsFirstTime) ?? true;

  bool get isExplicitGuest => _prefs.getBool(_keyIsExplicitGuest) ?? false;

  bool get isGuest => token == null || token!.isEmpty;
  String? get currentUserOrgId => organizationId;
  String? get currentUserId => userId;

  /// Clears the active organization data (used when the last org is deleted).
  Future<void> clearActiveOrganization() async {
    await _prefs.remove(_keyOrganizationId);
    await _prefs.remove(_keyOrganizationType);
    await _prefs.remove(_keyOrganizationStatus);
    await _prefs.setBool(_keyHasOrganization, false);
  }

  Future<void> logout() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserFullName);
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyTokenExpiry);
    await _prefs.remove(_keyIsVerified);
    await _prefs.remove(_keyHasOrganization);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyOrganizationId);
    await _prefs.remove(_keyOrganizationType);
    await _prefs.remove(_keyOrganizationStatus);
    await _prefs.remove(_keyIsExplicitGuest);
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

import 'dart:convert';
import 'dart:io';

import '../supabase/supabase_client.dart';

class AccountsApiException implements Exception {
  const AccountsApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CreatedAccount {
  const CreatedAccount({required this.loginId, this.studentId});
  final String loginId;
  final String? studentId;
}

/// Account management (create student / teacher, reset password) goes
/// through the web app's /api/accounts endpoint, which holds the Supabase
/// service key server-side. The phone only ever sends its own access token -
/// the service key never ships inside the APK - and the permission rules are
/// the exact same code the web dashboard uses.
class AccountsApi {
  static const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://bustan-alquran.com');

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final token = AppSupabase.client.auth.currentSession?.accessToken;
    if (token == null) throw const AccountsApiException('انتهت الجلسة، سجّل الدخول من جديد');

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(Uri.parse('$_baseUrl/api/accounts'));
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close().timeout(const Duration(seconds: 40));
      final text = await response.transform(utf8.decoder).join();
      final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw AccountsApiException((decoded['error'] as String?) ?? 'تعذّر تنفيذ الطلب');
      }
      return decoded;
    } on AccountsApiException {
      rethrow;
    } catch (_) {
      throw const AccountsApiException('تعذّر الاتصال بالخادم، تأكد من الإنترنت وحاول مرة أخرى');
    } finally {
      client.close();
    }
  }

  Future<CreatedAccount> createStudent({
    required String orgId,
    required String fullName,
    required String studentCode,
    required String circleId,
    required String password,
    String? email,
    String? birthDate,
    String? phone,
    String? whatsapp,
    String? address,
  }) async {
    final result = await _post({
      'action': 'create_student',
      'orgId': orgId,
      'fullName': fullName,
      'studentCode': studentCode,
      'circleId': circleId,
      'password': password,
      'email': email,
      'birthDate': birthDate,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
    });
    return CreatedAccount(loginId: result['loginId'] as String, studentId: result['studentId'] as String?);
  }

  Future<CreatedAccount> createTeacher({
    required String orgId,
    required String fullName,
    required String identifier,
    required String password,
    String? phone,
  }) async {
    final result = await _post({
      'action': 'create_teacher',
      'orgId': orgId,
      'fullName': fullName,
      'identifier': identifier,
      'password': password,
      'phone': phone,
    });
    return CreatedAccount(loginId: identifier, studentId: result['userId'] as String?);
  }

  Future<CreatedAccount> createGuardian({
    required String orgId,
    required String studentId,
    required String fullName,
    required String identifier,
    required String password,
    String? phone,
  }) async {
    await _post({
      'action': 'create_guardian',
      'orgId': orgId,
      'studentId': studentId,
      'fullName': fullName,
      'identifier': identifier,
      'password': password,
      'phone': phone,
    });
    return CreatedAccount(loginId: identifier);
  }

  /// Links an existing guardian to a student; a null [guardianMemberId] unlinks.
  Future<void> linkGuardian({required String orgId, required String studentId, String? guardianMemberId}) async {
    await _post({
      'action': 'link_guardian',
      'orgId': orgId,
      'studentId': studentId,
      'guardianMemberId': guardianMemberId,
    });
  }

  Future<void> resetPassword({required String orgId, required String memberId, required String password}) async {
    await _post({'action': 'reset_password', 'orgId': orgId, 'memberId': memberId, 'password': password});
  }
}

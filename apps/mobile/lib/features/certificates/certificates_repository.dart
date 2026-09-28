import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';

Map<String, String> get kCertificateKindLabels => currentStrings.labels.certKind;

class CertificateRow {
  const CertificateRow({required this.id, required this.serial, required this.kind, required this.title, required this.recipient, required this.issuedAt, required this.revoked});

  factory CertificateRow.fromJson(Map<String, dynamic> j) => CertificateRow(
        id: j['id'] as String,
        serial: j['serial'] as String,
        kind: j['kind'] as String,
        title: j['title'] as String,
        recipient: j['recipient_name'] as String,
        issuedAt: DateTime.parse(j['issued_at'] as String),
        revoked: j['revoked_at'] != null,
      );

  final String id;
  final String serial;
  final String kind;
  final String title;
  final String recipient;
  final DateTime issuedAt;
  final bool revoked;
}

class CertificateList {
  const CertificateList({required this.canIssue, required this.rows});
  final bool canIssue;
  final List<CertificateRow> rows;
}

class CertificateSettings {
  const CertificateSettings({this.signerName, this.signerTitle, this.footer, required this.serdTitle, required this.autoSerd});

  factory CertificateSettings.fromJson(Map<String, dynamic> j) => CertificateSettings(
        signerName: j['signer_name'] as String?,
        signerTitle: j['signer_title'] as String?,
        footer: j['footer'] as String?,
        serdTitle: j['serd_title'] as String,
        autoSerd: j['auto_serd'] == true,
      );

  final String? signerName;
  final String? signerTitle;
  final String? footer;
  final String serdTitle;
  final bool autoSerd;
}

/// Certificates are issued and frozen in SQL (name, wording and signer are
/// stamped at issue time); the phone only asks and displays.
class CertificatesRepository {
  CertificatesRepository(this._client);

  final SupabaseClient _client;

  Future<CertificateList> list(String orgId) {
    // cached so a family can show a certificate without signal
    return SyncService.instance.cached<CertificateList>(
      'certs:$orgId',
      () => _client.rpc('list_certificates', params: {'p_org': orgId, 'p_limit': 100}),
      (j) {
        final m = j as Map<String, dynamic>;
        return CertificateList(
          canIssue: m['can_issue'] == true,
          rows: [for (final r in (m['rows'] as List? ?? const [])) CertificateRow.fromJson(r as Map<String, dynamic>)],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> get(String orgId, String id) {
    return SyncService.instance.cached<Map<String, dynamic>?>(
      'cert:$id',
      () async => await _client.rpc('get_certificate', params: {'p_org': orgId, 'p_id': id}),
      (j) => j as Map<String, dynamic>?,
    );
  }

  Future<void> issue({required String orgId, required String studentId, required String kind, required String title, String? description}) {
    return _client.rpc('issue_certificate', params: {'p_org': orgId, 'p_student': studentId, 'p_kind': kind, 'p_title': title, 'p_description': description});
  }

  Future<void> issueSerd(String orgId, String sessionId) => _client.rpc('issue_serd_certificate', params: {'p_org': orgId, 'p_session': sessionId});

  Future<void> revoke(String orgId, String id, String? reason) => _client.rpc('revoke_certificate', params: {'p_org': orgId, 'p_id': id, 'p_reason': reason});

  Future<CertificateSettings> settings(String orgId) async =>
      CertificateSettings.fromJson((await _client.rpc('get_certificate_settings', params: {'p_org': orgId})) as Map<String, dynamic>);

  Future<void> saveSettings(String orgId, {required String signerName, required String signerTitle, required String footer, required String serdTitle, required bool autoSerd}) {
    return _client.rpc('set_certificate_settings', params: {
      'p_org': orgId,
      'p_signer_name': signerName,
      'p_signer_title': signerTitle,
      'p_footer': footer,
      'p_serd_title': serdTitle,
      'p_auto_serd': autoSerd,
    });
  }
}

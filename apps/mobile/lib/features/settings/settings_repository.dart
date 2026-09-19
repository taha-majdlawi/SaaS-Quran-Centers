import 'package:supabase_flutter/supabase_flutter.dart';

class WeekdayRow {
  WeekdayRow({required this.dow, required this.label, required this.isWorking, required this.isSerdDay});

  final int dow;
  String label;
  bool isWorking;
  bool isSerdDay;
}

const kTextSettingKeys = [
  'backdate_days',
  'phone_country_code',
  'whatsapp_group_link',
  'center_location_label',
  'prayer_lat',
  'prayer_lng',
  'prayer_calc_method',
  'prayer_madhab',
];

const kFlagSettingKeys = ['flag_market_enabled', 'flag_leaderboard_enabled', 'flag_teacher_manage_students'];

/// Mirrors apps/web's settings/actions.ts - org name/branding/timezone plus
/// the per-center weekdays and settings that eqraa hard-codes.
class SettingsRepository {
  SettingsRepository(this._client);

  final SupabaseClient _client;

  Future<void> updateOrgSettings({
    required String organizationId,
    required String name,
    required String primaryColor,
    required String secondaryColor,
    required String timezone,
  }) {
    return _client.from('organizations').update({
      'name': name,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'timezone': timezone,
    }).eq('id', organizationId);
  }

  Future<List<WeekdayRow>> fetchWeekdays(String organizationId) async {
    final rows = await _client
        .from('center_weekdays')
        .select('dow, label, is_working, is_serd_day')
        .eq('organization_id', organizationId)
        .order('dow');
    return (rows as List)
        .map((r) => WeekdayRow(
              dow: r['dow'] as int,
              label: r['label'] as String,
              isWorking: r['is_working'] as bool,
              isSerdDay: r['is_serd_day'] as bool,
            ))
        .toList();
  }

  Future<void> saveWeekdays(String organizationId, List<WeekdayRow> days) {
    return _client.from('center_weekdays').upsert([
      for (final d in days)
        {
          'organization_id': organizationId,
          'dow': d.dow,
          'label': d.label,
          'is_working': d.isWorking,
          // A serd day must be a working day (DB check constraint).
          'is_serd_day': d.isWorking && d.isSerdDay,
        },
    ], onConflict: 'organization_id,dow');
  }

  Future<Map<String, String>> fetchCenterSettings(String organizationId) async {
    final rows = await _client
        .from('organization_settings')
        .select('key, value')
        .eq('organization_id', organizationId);
    return {for (final r in rows as List) r['key'] as String: (r['value'] as String?) ?? ''};
  }

  Future<void> saveCenterSettings(String organizationId, Map<String, String> values) {
    final now = DateTime.now().toUtc().toIso8601String();
    return _client.from('organization_settings').upsert([
      for (final e in values.entries)
        {'organization_id': organizationId, 'key': e.key, 'value': e.value, 'updated_at': now},
    ], onConflict: 'organization_id,key');
  }
}

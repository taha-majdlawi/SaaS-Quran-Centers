import 'package:intl/intl.dart' show DateFormat;

final _dateTime = DateFormat('yyyy/MM/dd  HH:mm');
final _date = DateFormat('yyyy/MM/dd');

/// "2026/09/19  16:30" from an ISO timestamp (shown in the device's timezone).
String formatDateTime(String? iso, {String fallback = '—'}) {
  final parsed = iso == null ? null : DateTime.tryParse(iso);
  if (parsed == null) return fallback;
  return _dateTime.format(parsed.toLocal());
}

String formatDate(String? iso, {String fallback = '—'}) {
  final parsed = iso == null ? null : DateTime.tryParse(iso);
  if (parsed == null) return fallback;
  return _date.format(parsed.toLocal());
}

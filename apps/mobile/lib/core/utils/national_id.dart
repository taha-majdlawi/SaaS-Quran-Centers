/// Same rule as apps/web/src/lib/auth/national-id.ts (0095): Latin letters and digits, upper
/// case, 4-20 long; Arabic-Indic and Persian digits become 0-9, spaces and dashes go.
/// null = not an ID.
String? normalizeNationalId(String? value) {
  if (value == null) return null;
  final buf = StringBuffer();
  for (final r in value.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      buf.write(r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      buf.write(r - 0x06F0);
    } else if (!' \t-_.'.runes.contains(r)) {
      buf.writeCharCode(r);
    }
  }
  final v = buf.toString().toUpperCase();
  return RegExp(r'^[A-Z0-9]{4,20}$').hasMatch(v) ? v : null;
}

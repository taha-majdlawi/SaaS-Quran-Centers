import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bustan_alquran_app/core/widgets/ui.dart';

void main() {
  test('a viewing-account refusal and server rules reach the person as written', () {
    expect(friendlyError(StateError('هذا حساب عرض'), 'x'), 'هذا حساب عرض');
    expect(friendlyError(const PostgrestException(message: 'هذا حساب عرض — للاطّلاع فقط', code: '42501'), 'x'), 'هذا حساب عرض — للاطّلاع فقط');
    expect(friendlyError(const PostgrestException(message: 'الطالب ليس ضمن حلقتك', code: 'P0001'), 'x'), 'الطالب ليس ضمن حلقتك');
  });

  test('raw Postgres wording is replaced, a lost connection is named, the rest falls back', () {
    expect(friendlyError(const PostgrestException(message: 'new row violates row-level security policy', code: '42501'), 'x'), 'لا تملك صلاحية تنفيذ هذه العملية');
    expect(friendlyError(const PostgrestException(message: 'fk', code: '23503'), 'x'), 'لا يمكن تنفيذ العملية لوجود بيانات مرتبطة');
    expect(friendlyError(const SocketException('down'), 'x'), 'تعذّر الاتصال بالإنترنت، حاول مرة أخرى');
    expect(friendlyError(Exception('boom'), 'حدث خطأ'), 'حدث خطأ');
  });
}

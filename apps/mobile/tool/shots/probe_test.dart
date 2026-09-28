import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';

void main() {
  setUpAll(loadFonts);
  testWidgets('probe', (t) async {
    await shot(t, 'probe', Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: const ListTile(leading: Icon(Icons.groups_rounded), title: Text('حلقة النور'), subtitle: Text('١٢ طالبًا · سمّع ٨')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    ), height: 300);
  });
}

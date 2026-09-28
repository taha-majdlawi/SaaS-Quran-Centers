import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/i18n.dart';

/// Shown once after creating an account: the only moment the password is
/// visible, so it can be copied and handed over.
Future<void> showCredentialsDialog(
  BuildContext context, {
  required String title,
  required String centerCode,
  required String loginId,
  required String password,
}) {
  final text = fmt(tr(context).ui.credsText, {'centerCode': centerCode, 'loginId': loginId, 'password': password});
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: SelectableText(text, textDirection: TextDirection.rtl, style: const TextStyle(height: 1.8)),
          ),
          const SizedBox(height: 10),
          Text(
            tr(context).ui.credsOnce,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).ui.copied)));
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: Text(tr(context).ui.copy),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          child: Text(tr(context).ui.done),
        ),
      ],
    ),
  );
}

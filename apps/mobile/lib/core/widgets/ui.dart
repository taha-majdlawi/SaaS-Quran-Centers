import 'package:flutter/material.dart';

/// Loading / error-with-retry / data states for any Future, so no screen
/// spins forever when a request fails.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.future, required this.builder, this.onRetry});

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(onRetry: onRetry);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message = 'تعذّر تحميل البيانات', this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('تأكد من الاتصال بالإنترنت وحاول مرة أخرى',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success / error message strip used under forms.
class MessageBanner extends StatelessWidget {
  const MessageBanner({super.key, required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: color.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: color.shade800))),
        ],
      ),
    );
  }
}

/// Primary action button with an in-button spinner while working.
class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.label, required this.onPressed, required this.loading, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label),
            ],
          );
    return FilledButton(onPressed: loading ? null : onPressed, child: child);
  }
}

/// Small colored pill for statuses (active / paused / present ...).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.color = Colors.grey});

  final String label;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Section title used inside long forms / detail screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }
}

/// Circular avatar with the first letter of a name.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar(this.name, {super.key, this.radius = 22});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    final primary = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.12),
      child: Text(letter, style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: radius * 0.85)),
    );
  }
}

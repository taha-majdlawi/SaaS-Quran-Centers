'use client';

import { useFormStatus } from 'react-dom';
import { useClientI18n } from '@/lib/i18n/client';

/**
 * Drop-in replacement for a plain <button type="submit"> inside a
 * <form action={serverAction}> - useFormStatus() only works in a Client
 * Component descendant of the form, so this can't just be a className
 * helper like auth-styles.ts. Shows a spinner + pendingText while the
 * server action is running, and disables the button so it can't be
 * double-submitted.
 */
export function SubmitButton({
  children,
  pendingText,
  className,
  disabled = false,
}: {
  children: React.ReactNode;
  pendingText?: string;
  className?: string;
  disabled?: boolean;
}) {
  const { pending } = useFormStatus();
  const i18n = useClientI18n();

  return (
    <button type="submit" disabled={pending || disabled} className={className}>
      {pending ? (
        <span className="flex items-center justify-center gap-2">
          <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
          {pendingText ?? i18n?.t.working ?? 'جاري التنفيذ...'}
        </span>
      ) : (
        children
      )}
    </button>
  );
}

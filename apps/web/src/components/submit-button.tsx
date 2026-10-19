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
  formAction,
  formNoValidate,
  title,
}: {
  children: React.ReactNode;
  pendingText?: string;
  className?: string;
  disabled?: boolean;
  /** a second button of a form, sending its fields to another action */
  formAction?: (formData: FormData) => void | Promise<void> | Promise<never>;
  formNoValidate?: boolean;
  /** a tooltip / accessible name when the button shows only an icon */
  title?: string;
}) {
  const { pending } = useFormStatus();
  const i18n = useClientI18n();

  return (
    <button type="submit" disabled={pending || disabled} className={className} formAction={formAction} formNoValidate={formNoValidate} title={title} aria-label={title}>
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

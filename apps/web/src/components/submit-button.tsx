'use client';

import { useFormStatus } from 'react-dom';

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
  pendingText = 'جاري التنفيذ...',
  className,
}: {
  children: React.ReactNode;
  pendingText?: string;
  className?: string;
}) {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending} className={className}>
      {pending ? (
        <span className="flex items-center justify-center gap-2">
          <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
          {pendingText}
        </span>
      ) : (
        children
      )}
    </button>
  );
}

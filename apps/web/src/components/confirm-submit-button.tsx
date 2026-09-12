'use client';

import { useFormStatus } from 'react-dom';

/** Same as SubmitButton, but asks for confirmation before the form actually
 * submits - for irreversible actions like delete. */
export function ConfirmSubmitButton({
  children,
  confirmMessage,
  pendingText = 'جاري التنفيذ...',
  className,
}: {
  children: React.ReactNode;
  confirmMessage: string;
  pendingText?: string;
  className?: string;
}) {
  const { pending } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className={className}
      onClick={(e) => {
        if (!confirm(confirmMessage)) e.preventDefault();
      }}
    >
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

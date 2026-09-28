'use client';

import { useFormStatus } from 'react-dom';
import { useClientI18n } from '@/lib/i18n/client';

/** Same as SubmitButton, but asks for confirmation before the form actually
 * submits - for irreversible actions like delete. */
export function ConfirmSubmitButton({
  children,
  confirmMessage,
  pendingText,
  className,
}: {
  children: React.ReactNode;
  confirmMessage: string;
  pendingText?: string;
  className?: string;
}) {
  const { pending } = useFormStatus();
  const i18n = useClientI18n();

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
          {pendingText ?? i18n?.t.working ?? 'جاري التنفيذ...'}
        </span>
      ) : (
        children
      )}
    </button>
  );
}

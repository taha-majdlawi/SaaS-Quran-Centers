import { staffStrings } from '@/lib/i18n/server';

/** A sentence for the person, instead of a raw Postgres message, when a delete does not go through. */
export async function deleteErrorMessage(error: { code?: string; message?: string } | null): Promise<string> {
  const C = (await staffStrings()).common;
  if (!error) return C.deleteDenied;
  if (error.code === '23503') return C.deleteLinked;
  return error.message || C.deleteFailed;
}

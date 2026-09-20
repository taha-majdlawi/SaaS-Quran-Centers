/** A sentence for the person, instead of a raw Postgres message, when a delete does not go through. */
export function deleteErrorMessage(error: { code?: string; message?: string } | null): string {
  if (!error) return 'لا تملك صلاحية الحذف أو أن العنصر غير موجود';
  if (error.code === '23503') return 'لا يمكن الحذف لوجود بيانات مرتبطة به (طلاب أو تسميعات أو غيرها). انقلها أولًا أو غيّر الحالة بدل الحذف.';
  return error.message || 'تعذّر الحذف';
}

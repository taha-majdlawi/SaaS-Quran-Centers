// The mushaf data and logic live in mushaf.ts; this is the shared digits helper.

const ARABIC_DIGITS = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
export const arabicNumber = (n: number) => String(n).split('').map((d) => ARABIC_DIGITS[Number(d)]).join('');


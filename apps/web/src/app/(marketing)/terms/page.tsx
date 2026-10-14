import type { Metadata } from 'next';
import { PlatformLegal } from '@/components/platform-legal';
import { terms } from '@/lib/legal/platform';

export const metadata: Metadata = { title: 'شروط الاستخدام | Terms of Use - بستان القرآن' };

// bustan-alquran.com/terms
export default function TermsPage() {
  return <PlatformLegal docs={terms} />;
}

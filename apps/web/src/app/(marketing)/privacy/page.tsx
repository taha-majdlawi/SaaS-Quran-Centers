import type { Metadata } from 'next';
import { PlatformLegal } from '@/components/platform-legal';
import { privacy } from '@/lib/legal/platform';

export const metadata: Metadata = { title: 'سياسة الخصوصية | Privacy Policy - بستان القرآن' };

// bustan-alquran.com/privacy - for Google sign-in's consent screen and the app stores too.
export default function PrivacyPage() {
  return <PlatformLegal docs={privacy} />;
}

import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'منصة مراكز تحفيظ القرآن',
  description: 'منصة SaaS لإدارة مراكز تحفيظ القرآن الكريم',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}

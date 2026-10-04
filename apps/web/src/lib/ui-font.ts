import localFont from 'next/font/local';

// Tajawal - SIL Open Font License 1.1 (src/fonts/Tajawal-OFL.txt). The same UI
// font as the mobile app, self-hosted (no request to a font service), so the
// web and the app read as one product in Arabic and in Latin languages.
export const uiFont = localFont({
  src: [
    { path: '../fonts/Tajawal-Regular.ttf', weight: '400', style: 'normal' },
    { path: '../fonts/Tajawal-Medium.ttf', weight: '500', style: 'normal' },
    { path: '../fonts/Tajawal-Bold.ttf', weight: '700', style: 'normal' },
    { path: '../fonts/Tajawal-ExtraBold.ttf', weight: '800', style: 'normal' },
  ],
  variable: '--font-ui',
  display: 'swap',
  fallback: ['system-ui', 'Segoe UI', 'Tahoma', 'Arial', 'sans-serif'],
});

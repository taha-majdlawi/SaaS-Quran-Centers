import type { Config } from 'tailwindcss';

export default {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        // Amiri Quran (SIL OFL), loaded by components/quran-font.tsx
        quran: ['var(--font-quran)', 'serif'],
      },
      colors: {
        // Overridden per-tenant at runtime via CSS variables set from
        // organizations.primary_color / secondary_color - see
        // src/lib/tenant/get-org-context.ts.
        brand: 'var(--brand-primary, #0f766e)',
        'brand-accent': 'var(--brand-secondary, #f59e0b)',
      },
    },
  },
  plugins: [],
} satisfies Config;

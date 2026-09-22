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
        // src/lib/tenant/get-org-context.ts. The fallback (no override) is
        // the platform's own identity - marketing pages, the platform owner
        // console, and a brand-new center before it picks its own colors.
        // See design/brand/README.md.
        brand: 'var(--brand-primary, #1E7A54)',
        'brand-accent': 'var(--brand-secondary, #D4A24C)',
      },
    },
  },
  plugins: [],
} satisfies Config;

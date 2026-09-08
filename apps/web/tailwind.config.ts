import type { Config } from 'tailwindcss';

export default {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
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

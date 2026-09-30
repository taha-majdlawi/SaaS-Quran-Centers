import type { Config } from 'tailwindcss';

// A CSS-variable colour that still honours opacity modifiers (bg-brand/10):
// plain var() colours silently drop them, so mix with transparent instead.
// (Tailwind accepts a function here; its types only list strings.)
const withAlpha = (cssVar: string) =>
  (({ opacityValue }: { opacityValue?: string }) =>
    opacityValue === undefined || opacityValue === '1'
      ? cssVar
      : `color-mix(in srgb, ${cssVar} calc(${opacityValue} * 100%), transparent)`) as unknown as string;

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
        brand: withAlpha('var(--brand-primary, #1E7A54)'),
        'brand-accent': withAlpha('var(--brand-secondary, #D4A24C)'),
      },
    },
  },
  plugins: [],
} satisfies Config;

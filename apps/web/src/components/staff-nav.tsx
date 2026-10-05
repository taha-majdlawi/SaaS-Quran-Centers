'use client';

import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import {
  Activity,
  AudioLines,
  Award,
  BarChart3,
  Bell,
  BookOpen,
  CalendarDays,
  ClipboardCheck,
  CreditCard,
  FileBadge,
  Globe,
  GraduationCap,
  History,
  Layers,
  LayoutDashboard,
  type LucideIcon,
  Megaphone,
  Menu,
  MessageCircle,
  Mic,
  RotateCcw,
  ScrollText,
  Search,
  Settings,
  ShieldCheck,
  Star,
  Store,
  Trash2,
  Trophy,
  Users,
  UsersRound,
  Wallet,
  X,
  CircleDot,
} from 'lucide-react';

const ICONS: Record<string, LucideIcon> = {
  dashboard: LayoutDashboard,
  quran: BookOpen,
  search: Search,
  students: Users,
  teachers: GraduationCap,
  circles: CircleDot,
  stages: Layers,
  attendance: ClipboardCheck,
  gatherings: UsersRound,
  recitations: AudioLines,
  'external-recitations': Mic,
  reviews: RotateCcw,
  serd: ScrollText,
  points: Star,
  badges: Award,
  market: Store,
  'circle-challenges': Trophy,
  activities: Activity,
  calendar: CalendarDays,
  announcements: Megaphone,
  chat: MessageCircle,
  notifications: Bell,
  reports: BarChart3,
  certificates: FileBadge,
  fees: Wallet,
  members: ShieldCheck,
  'deletion-requests': Trash2,
  audit: History,
  site: Globe,
  settings: Settings,
  billing: CreditCard,
};

export interface NavSectionView {
  title: string | null;
  items: { slug: string; label: string }[];
}

/** The page a path belongs to: "/" -> dashboard, "/students/12/edit" -> students. */
function slugOf(path: string): string {
  const first = path.split('/').filter(Boolean)[0];
  return first ?? 'dashboard';
}

/**
 * The staff menu: grouped sections with icons and the current page marked.
 * A fixed column on wide screens; on phones and tablets a button opens it as a drawer.
 */
export function StaffNav({ sections, menuLabel }: { sections: NavSectionView[]; menuLabel: string }) {
  const pathname = usePathname() ?? '/';
  const active = slugOf(pathname);
  const [open, setOpen] = useState(false);

  // a new page closes the drawer
  useEffect(() => setOpen(false), [pathname]);

  const list = (
    <nav className="flex flex-col gap-4 text-sm">
      {sections.map((s, i) => (
        <div key={s.title ?? i} className="flex flex-col gap-0.5">
          {s.title && <p className="px-3 pb-1 text-[11px] font-bold uppercase tracking-wider text-gray-400">{s.title}</p>}
          {s.items.map((m) => {
            const Icon = ICONS[m.slug] ?? CircleDot;
            const on = active === m.slug;
            return (
              <a
                key={m.slug}
                // relative to the root domain: the browser is already on the center's subdomain
                href={`/${m.slug === 'dashboard' ? '' : m.slug}`}
                aria-current={on ? 'page' : undefined}
                className={`flex items-center gap-2.5 rounded-lg px-3 py-2 transition-colors ${
                  on ? 'bg-brand/10 font-semibold text-brand' : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
                }`}
              >
                <Icon size={18} strokeWidth={on ? 2.4 : 2} className={on ? 'text-brand' : 'text-gray-400'} aria-hidden />
                <span className="truncate">{m.label}</span>
              </a>
            );
          })}
        </div>
      ))}
    </nav>
  );

  return (
    <>
      {/* wide screens: a column that stays while the page scrolls */}
      <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] w-64 shrink-0 overflow-y-auto border-e bg-white px-3 py-5 lg:block print:hidden">{list}</aside>

      {/* phones / tablets: a menu button, and the same list as a drawer */}
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="fixed bottom-5 end-5 z-30 flex items-center gap-2 rounded-full bg-brand px-4 py-3 text-sm font-semibold text-white shadow-lg lg:hidden print:hidden"
        aria-expanded={open}
      >
        <Menu size={18} aria-hidden /> {menuLabel}
      </button>
      {open && (
        <div className="fixed inset-0 z-40 lg:hidden" role="dialog" aria-modal="true" aria-label={menuLabel}>
          <button type="button" aria-label="×" className="absolute inset-0 bg-black/30" onClick={() => setOpen(false)} />
          <aside className="absolute inset-y-0 start-0 w-72 max-w-[85vw] overflow-y-auto bg-white px-3 py-4 shadow-xl">
            <div className="mb-3 flex justify-end">
              <button type="button" onClick={() => setOpen(false)} className="rounded-lg p-2 text-gray-500 hover:bg-gray-100" aria-label="×">
                <X size={18} aria-hidden />
              </button>
            </div>
            {list}
          </aside>
        </div>
      )}
    </>
  );
}

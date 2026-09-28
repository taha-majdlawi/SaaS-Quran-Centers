import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { csvCell } from '@/lib/csv';
import { staffStrings } from '@/lib/i18n/server';

export async function GET(_req: Request, { params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  if (!org.myPermissions.includes('students')) return new Response((await staffStrings()).common.forbidden, { status: 403 });

  const supabase = await createClient();
  const { data, error } = await supabase
    .from('students_profile')
    .select('student_code, full_name, status, birth_date, phone, whatsapp, address, total_points, circles(name)')
    .eq('organization_id', org.id)
    .order('full_name');
  if (error) return new Response(error.message, { status: 400 });

  const header = ['code', 'name', 'circle', 'status', 'birth_date', 'phone', 'whatsapp', 'address', 'points'];
  const lines = [header.join(',')];
  for (const s of data ?? []) {
    const circle = (s.circles as unknown as { name: string } | null)?.name ?? '';
    lines.push([s.student_code, s.full_name, circle, s.status, s.birth_date, s.phone, s.whatsapp, s.address, s.total_points].map(csvCell).join(','));
  }
  return new Response('\uFEFF' + lines.join('\r\n'), {
    headers: { 'Content-Type': 'text/csv; charset=utf-8', 'Content-Disposition': `attachment; filename="students-${org.slug}.csv"` },
  });
}

import { createClient } from '@/lib/supabase/server';

export default async function PlatformOrganizationsPage() {
  const supabase = await createClient();
  const { data: organizations } = await supabase
    .from('organizations')
    .select('id, name, slug, status, created_at')
    .order('created_at', { ascending: false });

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">المراكز (Tenants)</h1>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">الاسم</th>
            <th className="px-4 py-2">الرابط</th>
            <th className="px-4 py-2">الحالة</th>
          </tr>
        </thead>
        <tbody>
          {(organizations ?? []).map((o) => (
            <tr key={o.id} className="border-t">
              <td className="px-4 py-2">{o.name}</td>
              <td className="px-4 py-2">{o.slug}</td>
              <td className="px-4 py-2">{o.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

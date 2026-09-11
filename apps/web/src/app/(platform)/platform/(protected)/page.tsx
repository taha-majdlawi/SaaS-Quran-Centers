import { createClient } from '@/lib/supabase/server';

export default async function PlatformOverviewPage() {
  const supabase = await createClient();
  const { count } = await supabase.from('organizations').select('*', { count: 'exact', head: true });

  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">نظرة عامة</h1>
      <p className="text-gray-600">عدد المراكز المسجّلة على المنصة: {count ?? 0}</p>
    </div>
  );
}

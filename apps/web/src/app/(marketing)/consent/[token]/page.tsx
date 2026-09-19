import { createAdminClient } from '@/lib/supabase/admin';
import { answerConsent } from './actions';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface Info {
  center: string;
  event: string;
  student: string;
  start_date: string;
  end_date: string;
  starts_at: string | null;
  location: string | null;
  description: string | null;
  status: 'pending' | 'approved' | 'declined';
}

// Public page a guardian opens from a WhatsApp link - no account, no sign-in.
// The token is a random UUID per registration; nothing here is reachable
// without it, and the database is only ever touched by the service key on the
// server (anon has no access to any table or function).
export default async function ConsentPage({
  params,
  searchParams,
}: {
  params: Promise<{ token: string }>;
  searchParams: Promise<{ done?: string }>;
}) {
  const { token } = await params;
  const { done } = await searchParams;

  let info: Info | null = null;
  if (UUID.test(token)) {
    const { data } = await createAdminClient().rpc('consent_info', { p_token: token });
    info = (data as Info | null) ?? null;
  }

  if (!info) {
    return (
      <main className="mx-auto max-w-md p-8 text-center">
        <h1 className="mb-2 text-xl font-bold">الرابط غير صالح</h1>
        <p className="text-sm text-gray-500">تأكد من الرابط الذي وصلك، أو تواصل مع المركز.</p>
      </main>
    );
  }

  const when = info.start_date === info.end_date ? info.start_date : `${info.start_date} — ${info.end_date}`;

  return (
    <main className="mx-auto max-w-md p-6">
      <p className="mb-1 text-sm text-gray-500">{info.center}</p>
      <h1 className="mb-4 text-xl font-bold">موافقة ولي الأمر</h1>
      <div className="mb-4 rounded-lg border bg-white p-5 text-sm">
        <p className="mb-2">
          يطلب المركز موافقتكم على مشاركة <b>{info.student}</b> في:
        </p>
        <p className="text-lg font-bold">{info.event}</p>
        <p className="mt-1">
          {when}
          {info.starts_at && ` · ${info.starts_at.slice(0, 5)}`}
        </p>
        {info.location && <p>المكان: {info.location}</p>}
        {info.description && <p className="mt-2 whitespace-pre-line text-gray-600">{info.description}</p>}
      </div>

      {done || info.status !== 'pending' ? (
        <p
          className={`rounded px-4 py-3 text-center text-sm ${
            info.status === 'approved' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
          }`}
        >
          {info.status === 'approved' ? 'تم تسجيل موافقتكم. شكرًا لكم.' : 'تم تسجيل عدم الموافقة.'}
        </p>
      ) : (
        <form action={answerConsent} className="flex gap-3">
          <input type="hidden" name="token" value={token} />
          <button name="decision" value="approved" className="flex-1 rounded bg-green-600 px-4 py-3 font-semibold text-white">
            أوافق
          </button>
          <button name="decision" value="declined" className="flex-1 rounded border border-red-300 px-4 py-3 font-semibold text-red-600">
            لا أوافق
          </button>
        </form>
      )}
    </main>
  );
}

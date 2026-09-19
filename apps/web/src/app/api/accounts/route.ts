import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { AccountError, provisionStudent, provisionTeacher, resetMemberPassword } from '@/lib/accounts/provision';

// Account management for CLIENTS THAT CANNOT HOLD THE SERVICE KEY (the mobile
// app). The caller proves who they are with their own Supabase access token;
// every permission rule lives in lib/accounts/provision.ts, the same code the
// web's server actions use, so web and mobile can never drift apart.
export async function POST(request: Request) {
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return NextResponse.json({ error: 'غير مصرّح' }, { status: 401 });

  const admin = createAdminClient();
  const {
    data: { user },
  } = await admin.auth.getUser(token);
  if (!user) return NextResponse.json({ error: 'غير مصرّح' }, { status: 401 });

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'طلب غير صالح' }, { status: 400 });
  }

  try {
    switch (body.action) {
      case 'create_student':
        return NextResponse.json(await provisionStudent(admin, user.id, body as never));
      case 'create_teacher':
        return NextResponse.json(await provisionTeacher(admin, user.id, body as never));
      case 'reset_password':
        await resetMemberPassword(admin, user.id, body as never);
        return NextResponse.json({ ok: true });
      default:
        return NextResponse.json({ error: 'إجراء غير معروف' }, { status: 400 });
    }
  } catch (e) {
    if (e instanceof AccountError) return NextResponse.json({ error: e.message }, { status: 400 });
    return NextResponse.json({ error: 'حدث خطأ غير متوقع' }, { status: 500 });
  }
}

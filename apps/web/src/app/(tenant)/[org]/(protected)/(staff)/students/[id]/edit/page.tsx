import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateStudent, deleteStudent } from '../../actions';
import { createGuardianForStudent, setStudentGuardian } from '../guardian-actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const STATUS_OPTIONS = ['active', 'paused', 'graduated', 'withdrawn'];

export default async function EditStudentPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{
    error?: string;
    guardianCreated?: string;
    guardianPassword?: string;
    guardianLinked?: string;
    ok?: string;
  }>;
}) {
  const { org: slug, id } = await params;
  const { error, guardianCreated, guardianPassword, guardianLinked, ok } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const isAdmin = org.myRole === 'admin';

  const [{ data: student }, { data: circles }, { data: members }] = await Promise.all([
    supabase
      .from('students_profile')
      .select('id, full_name, student_code, birth_date, circle_id, status, phone, whatsapp, address, guardian_member_id, national_id')
      .eq('organization_id', org.id)
      .eq('id', id)
      .maybeSingle(),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
    isAdmin ? supabase.rpc('list_org_members', { org_id: org.id }) : Promise.resolve({ data: [] }),
  ]);
  const guardians = ((members ?? []) as { id: string; role: string; full_name: string | null; email: string | null }[])
    .filter((m) => m.role === 'guardian');
  const currentGuardian = guardians.find((g) => g.id === student?.guardian_member_id);
  const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

  if (!student) notFound();

  return (
    <div className="max-w-lg">
      <a href={`/students/${student.id}` as never} className="text-sm text-brand hover:underline">
        {S.profile.backProfile}
      </a>
      <h1 className="mb-6 mt-2 text-2xl font-bold">{S.students.editTitle}</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}

      <form action={updateStudent} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={student.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.students.fullName}
          <input
            name="fullName"
            required
            defaultValue={student.full_name}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.studentCode}
          <input
            name="studentCode"
            required
            defaultValue={student.student_code}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.nationalId}
          <input
            name="nationalId"
            defaultValue={student.national_id ?? ''}
            inputMode="numeric"
            autoComplete="off"
            dir="ltr"
            maxLength={24}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
          <span className="mt-1 block text-xs font-normal text-gray-400">{S.students.nationalIdHint}</span>
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.birthDate}
          <input
            type="date"
            name="birthDate"
            defaultValue={student.birth_date ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.mobile}
          <input name="phone" defaultValue={student.phone ?? ''} dir="ltr" className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.students.whatsappShort}
          <input name="whatsapp" defaultValue={student.whatsapp ?? ''} dir="ltr" className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.students.address}
          <input name="address" defaultValue={student.address ?? ''} className={field} />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.colCircle}
          <select
            name="circleId"
            required
            defaultValue={student.circle_id ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="" disabled>
              {S.students.pickCircle}
            </option>
            {(circles ?? []).map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.colStatus}
          <select
            name="status"
            defaultValue={student.status}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            {STATUS_OPTIONS.map((s) => (
              <option key={s} value={s}>
                {S.students.status[s]}
              </option>
            ))}
          </select>
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.common.saving}
        >
          {S.students.saveChanges}
        </SubmitButton>
      </form>

      {isAdmin && (
        <section className="mt-6 rounded-lg border bg-white p-6">
          <h2 className="mb-1 font-semibold">{S.students.guardian}</h2>
          <p className="mb-3 text-sm text-gray-500">
            {currentGuardian
              ? fmt(S.students.guardianNow, { name: currentGuardian.full_name ?? currentGuardian.email ?? '—' })
              : S.students.noGuardian}
          </p>

          {guardianCreated && (
            <p className="mb-3 rounded bg-green-50 px-3 py-2 text-sm text-green-700">
              {fmt(S.students.guardianCreated, { code: slug, login: guardianCreated, password: guardianPassword ?? '' })}
              <br />
              <span className="text-xs">{S.students.passwordOnce}</span>
            </p>
          )}
          {guardianLinked && <p className="mb-3 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.students.linkUpdated}</p>}

          <form action={setStudentGuardian} className="mb-4 flex items-end gap-2">
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="studentId" value={student.id} />
            <label className="flex-1 text-sm font-medium text-gray-700">
              {S.students.linkExisting}
              <select name="guardianMemberId" defaultValue={student.guardian_member_id ?? ''} className={field}>
                <option value="">{S.students.none2}</option>
                {guardians.map((g) => (
                  <option key={g.id} value={g.id}>
                    {g.full_name ?? g.email}
                  </option>
                ))}
              </select>
            </label>
            <SubmitButton className="rounded border px-4 py-2 text-sm font-semibold text-brand" pendingText="...">
              {S.students.saveLink}
            </SubmitButton>
          </form>

          {!student.guardian_member_id && (
            <form action={createGuardianForStudent} className="flex flex-col gap-2 border-t pt-4">
              <input type="hidden" name="orgId" value={org.id} />
              <input type="hidden" name="studentId" value={student.id} />
              <p className="text-sm font-medium text-gray-700">{S.students.createGuardian}</p>
              <input name="fullName" required placeholder={S.students.guardianName} className={field} />
              <input name="identifier" required placeholder={S.students.loginOrEmail} dir="ltr" className={field} />
              <input name="phone" placeholder={S.students.mobileOptional} dir="ltr" className={field} />
              <input name="password" required minLength={8} placeholder={S.students.passwordPh} className={field} />
              <SubmitButton
                className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white"
                pendingText={S.students.creating}
              >
                {S.students.createGuardianBtn}
              </SubmitButton>
            </form>
          )}
        </section>
      )}

      <form action={deleteStudent} className="mt-3">
        <input type="hidden" name="id" value={student.id} />
        <ConfirmSubmitButton
          confirmMessage={fmt(S.students.deleteConfirm, { name: student.full_name })}
          pendingText={S.common.deleting}
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          {S.students.deleteStudent}
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}

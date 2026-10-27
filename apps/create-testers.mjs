// Creates the Google Play testers' accounts in the eqraa (test) center:
// 6 circles "حلقة الاختبار 1..6", each with one test teacher and one test student.
// Run from the project folder on the laptop:   node create-testers.mjs
// It signs in as the center's admin (asked here, never stored) and uses the same
// endpoint as the app (/api/accounts), so every normal permission check applies.
// Safe to run again: existing circles / accounts are reused, not duplicated.
import fs from 'node:fs';
import readline from 'node:readline';

const SITE = 'https://bustan-alquran.com';
const CENTER = 'eqraa';
const TEST_PASSWORD = '123456789';
const COUNT = 6;
const TEACHER_ID = (i) => `90000${i}`; // teacher signs in with this number
const STUDENT_CODE = (i) => `90010${i}`; // student signs in with this number

const env = JSON.parse(fs.readFileSync(new URL('./mobile/env.json', import.meta.url)));
const URL_ = env.SUPABASE_URL, KEY = env.SUPABASE_PUBLISHABLE_KEY;

function ask(q, hidden = false) {
  return new Promise((res) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
    if (hidden) rl._writeToOutput = (s) => { if (s.includes(q)) rl.output.write(q); };
    rl.question(q, (a) => { rl.close(); if (hidden) process.stdout.write('\n'); res(a.trim()); });
  });
}

async function json(res) {
  const t = await res.text();
  try { return t ? JSON.parse(t) : {}; } catch { return { raw: t }; }
}

const email = await ask('إيميل مدير مركز إقرأ: ');
const password = await ask('كلمة سر المدير (ما بتنعرض): ', true);

// 1. sign in as the admin
const tok = await json(await fetch(`${URL_}/auth/v1/token?grant_type=password`, {
  method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }),
}));
if (!tok.access_token) { console.error('فشل تسجيل الدخول:', tok.error_description || tok.msg || tok.error || ''); process.exit(1); }
const auth = { apikey: KEY, Authorization: `Bearer ${tok.access_token}`, 'Content-Type': 'application/json' };
const rest = (path, init = {}) => fetch(`${URL_}/rest/v1/${path}`, { ...init, headers: { ...auth, ...(init.headers || {}) } });

// 2. the center
const [org] = await json(await rest(`organizations?slug=eq.${CENTER}&select=id,name`));
if (!org) { console.error(`ما لقيت المركز ${CENTER}`); process.exit(1); }
console.log(`المركز: ${org.name}`);

const api = async (body) => {
  const r = await fetch(`${SITE}/api/accounts`, { method: 'POST', headers: { Authorization: `Bearer ${tok.access_token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ orgId: org.id, ...body }) });
  const d = await json(r);
  return { ok: r.ok, ...d };
};

const rows = [];
for (let i = 1; i <= COUNT; i++) {
  const circleName = `حلقة الاختبار ${i}`;
  // 3. the circle (reused if it exists)
  let [circle] = await json(await rest(`circles?organization_id=eq.${org.id}&name=eq.${encodeURIComponent(circleName)}&select=id,teacher_id`));
  if (!circle) {
    [circle] = await json(await rest('circles', { method: 'POST', headers: { Prefer: 'return=representation' }, body: JSON.stringify({ organization_id: org.id, name: circleName }) }));
    if (!circle?.id) { console.error(`تعذّر إنشاء ${circleName}`); process.exit(1); }
  }

  // 4. the teacher
  const t = await api({ action: 'create_teacher', fullName: `معلم تجريبي ${i}`, identifier: TEACHER_ID(i), password: TEST_PASSWORD });
  if (t.userId) {
    await rest(`circles?id=eq.${circle.id}`, { method: 'PATCH', body: JSON.stringify({ teacher_id: t.userId }) });
  } else if (!circle.teacher_id) {
    console.warn(`معلم ${i}: ${t.error || 'لم يُنشأ'} (إن كان موجودًا من قبل، اربطه بالحلقة من صفحة الحلقات)`);
  }

  // 5. the student
  const s = await api({ action: 'create_student', fullName: `طالب تجريبي ${i}`, studentCode: STUDENT_CODE(i), circleId: circle.id, password: TEST_PASSWORD });
  if (!s.ok && !s.studentId) console.warn(`طالب ${i}: ${s.error || 'لم يُنشأ'}`);

  rows.push({ circle: circleName, teacher: TEACHER_ID(i), teacherOk: !!t.userId, student: STUDENT_CODE(i), studentOk: !!s.studentId });
}

console.log('\nالحسابات (كلمة السر لكل الحسابات: ' + TEST_PASSWORD + ')');
console.log('الحلقة | المعلم (رقم الدخول) | الطالب (رقم الدخول)');
for (const r of rows) {
  console.log(`${r.circle} | ${r.teacher}${r.teacherOk ? '' : ' (موجود/فشل)'} | ${r.student}${r.studentOk ? '' : ' (موجود/فشل)'}`);
}
console.log(`\nالدخول: اختر مركز «${CENTER}» بالتطبيق، وادخل برقم الدخول وكلمة السر.`);

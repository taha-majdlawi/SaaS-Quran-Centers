// Android App Links: lets https://<center>.bustan-alquran.com/join?... open the app directly.
// The debug fingerprint below is the one the current builds are signed with; add the Play
// upload/app-signing SHA-256 through ANDROID_APP_FINGERPRINTS (comma separated) when releasing.
const PACKAGE = 'com.bustanalquran.bustan_alquran_app';
const BUILT_IN = ['0C:FC:11:1C:15:0F:6D:71:9F:A3:FC:B3:21:D0:9B:DD:2B:82:45:59:F6:0B:25:79:E5:E6:1F:33:FC:1E:7F:19'];

export function GET() {
  const extra = (process.env.ANDROID_APP_FINGERPRINTS ?? '').split(',').map((s) => s.trim()).filter(Boolean);
  const body = [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: { namespace: 'android_app', package_name: PACKAGE, sha256_cert_fingerprints: [...BUILT_IN, ...extra] },
    },
  ];
  return new Response(JSON.stringify(body), { headers: { 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=3600' } });
}

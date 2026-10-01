import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/attendance/attendance_repository.dart';
import '../../features/calendar/calendar_repository.dart';
import '../../features/comms/comms_repository.dart';
import '../../features/engagement/engagement_repository.dart';
import '../../features/insights/insights_repository.dart';
import '../../features/members/members_repository.dart';
import '../../features/my_portal/my_portal_repository.dart';
import '../../features/quran/quran_data.dart';
import '../../features/recitation/recitation_repository.dart';
import '../../features/serd/serd_repository.dart';
import '../../features/attention/attention_screen.dart';
import '../../features/profiles/profiles_repository.dart';
import '../../features/students/students_repository.dart';
import '../tenant/organization.dart';
import 'sync_service.dart';

/// Downloads what a person needs to keep working without a connection: for a
/// teacher every circle, every student in them (file, recitation log, notes,
/// serd, plan), today's attendance, the serd setup, reviews, the calendar and
/// the messages; for a family their children's records. Every read goes through
/// [SyncService.cached] with the same keys the screens use, so afterwards the
/// screens open from the phone.
class OfflinePrefetch extends ChangeNotifier {
  OfflinePrefetch._();
  static final instance = OfflinePrefetch._();

  /// Re-downloaded by itself when the last full download is older than this.
  static const staleAfter = Duration(minutes: 30);

  bool _running = false;
  int _done = 0;
  int _total = 0;
  int _failed = 0;
  DateTime? _lastRun;
  String? _boundKey;

  bool get running => _running;
  int get done => _done;
  int get total => _total;
  int get failed => _failed;

  /// When everything was last downloaded for the current account and center.
  DateTime? get lastRun => _lastRun;
  double get progress => _total == 0 ? 0 : _done / _total;

  SupabaseClient? _client;
  OrganizationMembership? Function()? _current;
  bool _wasOnline = true;
  Timer? _timer;

  /// Keeps the download fresh by itself: when the connection comes back, and
  /// every [staleAfter] while the app is open. [current] is the active center.
  void autoRun(SupabaseClient client, OrganizationMembership? Function() current) {
    if (_client != null) return;
    _client = client;
    _current = current;
    SyncService.instance.addListener(() {
      final online = SyncService.instance.online;
      if (online && !_wasOnline) _kick();
      _wasOnline = online;
    });
    _timer = Timer.periodic(staleAfter, (_) => _kick());
    // back to the app after a while: refresh what went stale meanwhile
    _lifecycle = AppLifecycleListener(onResume: _kick);
  }

  AppLifecycleListener? _lifecycle;

  void _kick() {
    final client = _client;
    final m = _current?.call();
    if (client != null && m != null) unawaited(run(client, m));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  String _prefKey(String userId, String orgId) => 'offline_prefetch_at:$userId:$orgId';

  /// Loads when the current account + center was last downloaded (for the sync screen).
  Future<void> bind(String? userId, String? orgId) async {
    final key = userId == null || orgId == null ? null : _prefKey(userId, orgId);
    if (key == _boundKey) return;
    _boundKey = key;
    _lastRun = null;
    if (key != null) {
      try {
        final ms = (await SharedPreferences.getInstance()).getInt(key);
        if (ms != null) _lastRun = DateTime.fromMillisecondsSinceEpoch(ms);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Downloads everything unless it was done recently ([force] = always).
  Future<void> run(SupabaseClient client, OrganizationMembership membership, {bool force = false}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null || _running) return;
    final orgId = membership.organization.id;
    await bind(userId, orgId);
    if (!force && _lastRun != null && DateTime.now().difference(_lastRun!) < staleAfter) return;
    if (!SyncService.instance.online) return;

    _running = true;
    _done = 0;
    _total = 0;
    _failed = 0;
    notifyListeners();
    try {
      final staff = membership.role == OrgRole.admin || membership.role == OrgRole.teacher;
      if (staff) {
        await _staff(client, membership, userId);
      } else {
        await _family(client, orgId);
      }
      // only a download that reached the server counts as "done"
      if (SyncService.instance.online && _failed < _total) {
        _lastRun = DateTime.now();
        try {
          await (await SharedPreferences.getInstance()).setInt(_prefKey(userId, orgId), _lastRun!.millisecondsSinceEpoch);
        } catch (_) {}
      }
    } finally {
      _running = false;
      notifyListeners();
    }
    // the mushaf text last and quietly: it is big and rarely changes
    unawaited(_quran());
  }

  Future<void> _staff(SupabaseClient client, OrganizationMembership m, String userId) async {
    final orgId = m.organization.id;
    final isAdmin = m.role == OrgRole.admin;
    final rec = RecitationRepository(client);
    final ins = InsightsRepository(client);
    final att = AttendanceRepository(client);
    final serd = SerdRepository(client);
    final portal = MyPortalRepository(client);
    final students = StudentsRepository(client);
    final comms = CommsRepository(client);
    final cal = CalendarRepository(client);
    final eng = EngagementRepository(client);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final month = DateTime(DateTime.now().year, DateTime.now().month);
    final prof = ProfilesRepository(client);
    final period = ProfilePeriod.of('month');

    // 1. the day and the circles (an admin downloads every circle of the center)
    final circles = <MyCircle>[];
    await _all([
      () => rec.fetchGrades(orgId),
      () => rec.fetchTeacherToday(orgId),
      () async {
        final mine = await rec.fetchMyCircles(orgId, userId: userId, isAdmin: false);
        if (!isAdmin) circles.addAll(mine);
      },
      if (isAdmin) () async => circles.addAll(await rec.fetchMyCircles(orgId, userId: userId, isAdmin: true)),
      if (isAdmin) () => MembersRepository(client).fetchMembers(orgId),
      () => ins.checkedInCircles(orgId),
      () => ins.dueReviews(orgId),
      () => att.fetchCircles(orgId),
      () => SyncService.instance.raw('my-name', () => client.from('profiles').select('full_name').eq('id', userId).maybeSingle()),
      if (m.hasModule('serd')) ...[
        () => serd.fetchSetup(orgId),
        () => serd.teacherScheduled(orgId),
        () => serd.teacherMy(orgId),
        () => serd.fetchStages(orgId),
      ],
      if (m.hasModule('students')) () => students.fetchStudents(orgId),
      if (m.hasModule('students')) () => students.fetchCircles(orgId),
      if (m.hasModule('calendar')) () => cal.fetchRange(orgId, month, DateTime(month.year, month.month + 1, 0)),
      if (m.hasModule('announcements')) () => comms.announcements(orgId),
      () => comms.notifications(orgId),
      if (m.hasModule('chat')) () => comms.threads(orgId),
      if (m.hasModule('badges')) () => eng.badgeDefs(orgId),
    ]);

    // 2. every circle: its students, today's attendance, its reviews
    final studentIds = <String>{};
    await _all([
      for (final c in circles) ...[
        () async => studentIds.addAll((await rec.fetchCircleStudents(c.id)).map((s) => s.id)),
        () => att.fetchStudentsInCircle(orgId, c.id),
        () => att.fetchExisting(c.id, today),
        () => ins.dueReviews(orgId, circleId: c.id),
        () => SyncService.instance.raw('circle-name:${c.id}', () => client.from('circles').select('name').eq('id', c.id).single()),
        // the circle's profile, this month and the month before (for the comparison)
        () => prof.circle(orgId, c.id, period),
        () => prof.circle(orgId, c.id, period.previous),
      ],
      // my own profile, and who needs attention
      () => AttentionScreen.load(client, orgId),
      () => prof.teacher(orgId, userId, period),
      () => prof.teacher(orgId, userId, period.previous),
    ]);

    // 3. every student's file
    await _all([
      for (final id in studentIds) ...[
        () => portal.fetchDashboard(orgId, id),
        () => rec.fetchStudentRecitations(id),
        () => ins.notes(orgId, id),
        () => students.fetchStudent(id),
        () => SyncService.instance.raw('student-guardian:$id', () => client.from('students_profile').select('guardian_member_id').eq('id', id).maybeSingle()),
        if (m.hasModule('serd')) () => serd.studentSummary(orgId, id),
        () => prof.goal(orgId, id),
      ],
    ]);
  }

  Future<void> _family(SupabaseClient client, String orgId) async {
    final portal = MyPortalRepository(client);
    final comms = CommsRepository(client);
    final kids = <String>[];
    await _all([
      () async => kids.addAll((await portal.fetchMyStudents(orgId)).map((s) => s.id)),
      () => comms.announcements(orgId),
      () => comms.notifications(orgId),
    ]);
    await _all([
      for (final id in kids) ...[
        () => portal.fetchDashboard(orgId, id),
        () => portal.fetchRecordDetail(orgId, id),
        () => ProfilesRepository(client).goal(orgId, id),
        () => ProfilesRepository(client).weekly(orgId, id),
      ],
    ]);
  }

  /// Runs [tasks] a few at a time; one failing never stops the others.
  Future<void> _all(List<Future<dynamic> Function()> tasks, {int parallel = 4}) async {
    _total += tasks.length;
    notifyListeners();
    var next = 0;
    Future<void> worker() async {
      while (next < tasks.length) {
        final task = tasks[next++];
        try {
          await task();
        } catch (_) {
          _failed++;
        }
        _done++;
        notifyListeners();
      }
    }

    await Future.wait([for (var i = 0; i < parallel; i++) worker()]);
  }

  bool _quranRunning = false;

  Future<void> _quran() async {
    if (_quranRunning) return;
    _quranRunning = true;
    final text = QuranTextService();
    try {
      for (var n = 1; n <= 114; n++) {
        if (!SyncService.instance.online) break;
        try {
          await text.surah(n); // read from the phone when it is already there
        } catch (_) {
          break; // the mushaf source is unreachable - try again next time
        }
      }
    } finally {
      _quranRunning = false;
    }
  }
}

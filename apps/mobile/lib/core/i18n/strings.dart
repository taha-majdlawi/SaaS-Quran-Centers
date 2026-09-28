// GENERATED from the i18n spec (see docs/I18N.md) - edit the spec, not this file.
// Every language must fill every field: a missing translation is a compile error.
// ignore_for_file: lines_longer_than_80_chars

/// Shared words and the generic states.
class SCommon {
  const SCommon({required this.appName, required this.signOut, required this.loadFailed, required this.checkConnection, required this.retry, required this.noPermission, required this.linkedData, required this.offline, required this.cancel, required this.save, required this.delete, required this.edit, required this.send, required this.close, required this.confirm, required this.language, required this.goodMorning, required this.goodEvening, required this.listSep});
  final String appName;
  final String signOut;
  final String loadFailed;
  final String checkConnection;
  final String retry;
  final String noPermission;
  final String linkedData;
  final String offline;
  final String cancel;
  final String save;
  final String delete;
  final String edit;
  final String send;
  final String close;
  final String confirm;
  final String language;
  final String goodMorning;
  final String goodEvening;
  final String listSep;
}

/// Names of fixed values (the staff screens use the Arabic ones).
class SLabels {
  const SLabels({required this.recitationType, required this.attendance, required this.purchase, required this.metric, required this.challengeStatus, required this.serdStatus, required this.months, required this.rule, required this.juz, required this.portion, required this.portionDen, required this.portionOrd, required this.audience, required this.consent, required this.source, required this.registration, required this.weekdays, required this.certKind, required this.deletionStatus, required this.roles});
  final Map<String, String> recitationType;
  final Map<String, String> attendance;
  final Map<String, String> purchase;
  final Map<String, String> metric;
  final Map<String, String> challengeStatus;
  final Map<String, String> serdStatus;
  final List<String> months;
  final Map<String, String> rule;
  final String juz;
  final String portion;
  final Map<String, String> portionDen;
  final List<String> portionOrd;
  final Map<String, String> audience;
  final Map<String, String> consent;
  final Map<String, String> source;
  final Map<String, String> registration;
  final List<String> weekdays;
  final Map<String, String> certKind;
  final Map<String, String> deletionStatus;
  final Map<String, String> roles;
}

/// The strips under the status bar.
class SBanners {
  const SBanners({required this.viewer, required this.billingLock});
  final String viewer;
  final String billingLock;
}

/// The student / guardian portal (my_portal).
class SPortal {
  const SPortal({required this.tabHome, required this.tabRecord, required this.tabAccount, required this.noChildren, required this.notLinked, required this.askAdmin, required this.studentMissing, required this.noStudent, required this.hello, required this.sheikh, required this.noCircle, required this.progressTitle, required this.partsOf30, required this.nextPlan, required this.goalQuran, required this.goalPoints, required this.unitJuz, required this.unitPoints, required this.remaining, required this.announcements, required this.upcoming, required this.prayers, required this.statsTitle, required this.statAyahs, required this.statAttendance, required this.statTotal, required this.statLast, required this.weekTitle, required this.weekCount, required this.weekBetter, required this.weekWorse, required this.weekSame, required this.streak, required this.streakRecord, required this.yourBadges, required this.calendar, required this.calendarSub, required this.chat, required this.announcementsLink, required this.report, required this.reportSub, required this.certificates, required this.quran, required this.quranSub, required this.privacy, required this.privacySub, required this.notifications, required this.badges, required this.market, required this.serd, required this.recent, required this.noRecitations, required this.studentCode, required this.circle, required this.stage, required this.teacher, required this.phone, required this.address, required this.languageHint});
  final String tabHome;
  final String tabRecord;
  final String tabAccount;
  final String noChildren;
  final String notLinked;
  final String askAdmin;
  final String studentMissing;
  final String noStudent;
  final String hello;
  final String sheikh;
  final String noCircle;
  final String progressTitle;
  final String partsOf30;
  final String nextPlan;
  final String goalQuran;
  final String goalPoints;
  final String unitJuz;
  final String unitPoints;
  final String remaining;
  final String announcements;
  final String upcoming;
  final List<String> prayers;
  final String statsTitle;
  final String statAyahs;
  final String statAttendance;
  final String statTotal;
  final String statLast;
  final String weekTitle;
  final String weekCount;
  final String weekBetter;
  final String weekWorse;
  final String weekSame;
  final String streak;
  final String streakRecord;
  final String yourBadges;
  final String calendar;
  final String calendarSub;
  final String chat;
  final String announcementsLink;
  final String report;
  final String reportSub;
  final String certificates;
  final String quran;
  final String quranSub;
  final String privacy;
  final String privacySub;
  final String notifications;
  final String badges;
  final String market;
  final String serd;
  final String recent;
  final String noRecitations;
  final String studentCode;
  final String circle;
  final String stage;
  final String teacher;
  final String phone;
  final String address;
  final String languageHint;
}

/// The record tab.
class SRecord {
  const SRecord({required this.tabRecitations, required this.tabAttendance, required this.tabSerd, required this.thisMonth, required this.recitations, required this.ayahs, required this.attendance, required this.points, required this.breakdown, required this.noAttendance, required this.search, required this.all, required this.noResults, required this.session});
  final String tabRecitations;
  final String tabAttendance;
  final String tabSerd;
  final String thisMonth;
  final String recitations;
  final String ayahs;
  final String attendance;
  final String points;
  final String breakdown;
  final String noAttendance;
  final String search;
  final String all;
  final String noResults;
  final String session;
}

/// Badges & competition (portal).
class SBadges {
  const SBadges({required this.title, required this.mine, required this.none, required this.earned, required this.expires, required this.manual, required this.board, required this.points, required this.challenge});
  final String title;
  final String mine;
  final String none;
  final String earned;
  final String expires;
  final String manual;
  final String board;
  final String points;
  final String challenge;
}

/// Points market (portal).
class SMarket {
  const SMarket({required this.title, required this.disabled, required this.balance, required this.earned, required this.pending, required this.available, required this.empty, required this.stock, required this.bought, required this.soldOut, required this.buy, required this.tooPoor, required this.orders, required this.noOrders, required this.cancelled});
  final String title;
  final String disabled;
  final String balance;
  final String earned;
  final String pending;
  final String available;
  final String empty;
  final String stock;
  final String bought;
  final String soldOut;
  final String buy;
  final String tooPoor;
  final String orders;
  final String noOrders;
  final String cancelled;
}

/// A student's approved serd summary.
class SSerdCard {
  const SSerdCard({required this.none, required this.sessions, required this.average, required this.best, required this.covered, required this.juzCount, required this.complete, required this.partial, required this.partialItem});
  final String none;
  final String sessions;
  final String average;
  final String best;
  final String covered;
  final String juzCount;
  final String complete;
  final String partial;
  final String partialItem;
}

/// Announcements.
class SAnn {
  const SAnn({required this.title, required this.newTitle, required this.none, required this.draft, required this.required, required this.deleteTitle, required this.sure, required this.fieldTitle, required this.fieldBody, required this.audience, required this.circleOptional, required this.allCircles, required this.pin, required this.publish, required this.publishHint, required this.editTitle, required this.yourCircle});
  final String title;
  final String newTitle;
  final String none;
  final String draft;
  final String required;
  final String deleteTitle;
  final String sure;
  final String fieldTitle;
  final String fieldBody;
  final String audience;
  final String circleOptional;
  final String allCircles;
  final String pin;
  final String publish;
  final String publishHint;
  final String editTitle;
  final String yourCircle;
}

/// Calendar list and event detail.
class SCal {
  const SCal({required this.settingLoadFailed, required this.reminderTitle, required this.reminderHours, required this.reminderHelp, required this.reminderSaved, required this.saveFailed, required this.title, required this.reminderTip, required this.types, required this.add, required this.legend, required this.thisMonth, required this.nothing, required this.youRegistered, required this.dayOff, required this.serdScheduled, required this.serd, required this.linkCopied, required this.registeredDone, required this.resultOf, required this.rank, required this.note, required this.resultSaved, required this.details, required this.registration, required this.participants, required this.registerStudent, required this.noParticipants, required this.waitlistCount, required this.circle, required this.stage, required this.workDay, required this.taken, required this.waiting, required this.deadline, required this.needsConsent, required this.unregister, required this.unregistered, required this.staffRegistered, required this.register, required this.waitlisted, required this.joinWaitlist, required this.leftWaitlist, required this.leaveWaitlist, required this.registeredChip, required this.waitingChip, required this.consent, required this.copyLink, required this.result, required this.rankN, required this.copyConsent, required this.consentRecorded, required this.phoneConsent, required this.declineRecorded, required this.decline, required this.resultBtn, required this.searchStudent, required this.onDay, required this.takenShort, required this.offDay, required this.unregisterQ});
  final String settingLoadFailed;
  final String reminderTitle;
  final String reminderHours;
  final String reminderHelp;
  final String reminderSaved;
  final String saveFailed;
  final String title;
  final String reminderTip;
  final String types;
  final String add;
  final String legend;
  final String thisMonth;
  final String nothing;
  final String youRegistered;
  final String dayOff;
  final String serdScheduled;
  final String serd;
  final String linkCopied;
  final String registeredDone;
  final String resultOf;
  final String rank;
  final String note;
  final String resultSaved;
  final String details;
  final String registration;
  final String participants;
  final String registerStudent;
  final String noParticipants;
  final String waitlistCount;
  final String circle;
  final String stage;
  final String workDay;
  final String taken;
  final String waiting;
  final String deadline;
  final String needsConsent;
  final String unregister;
  final String unregistered;
  final String staffRegistered;
  final String register;
  final String waitlisted;
  final String joinWaitlist;
  final String leftWaitlist;
  final String leaveWaitlist;
  final String registeredChip;
  final String waitingChip;
  final String consent;
  final String copyLink;
  final String result;
  final String rankN;
  final String copyConsent;
  final String consentRecorded;
  final String phoneConsent;
  final String declineRecorded;
  final String decline;
  final String resultBtn;
  final String searchStudent;
  final String onDay;
  final String takenShort;
  final String offDay;
  final String unregisterQ;
}

/// Certificates (the certificate itself stays Arabic, as issued).
class SCert {
  const SCert({required this.failed, required this.issueTitle, required this.student, required this.kind, required this.fieldTitle, required this.fieldText, required this.issue, required this.serdHint, required this.issued, required this.revokeTitle, required this.reason, required this.revoke, required this.revoked, required this.customizeTitle, required this.signer, required this.signerRole, required this.footer, required this.serdTitle, required this.autoSerd, required this.futureOnly, required this.saved, required this.title, required this.customize, required this.add, required this.none, required this.revokedMark, required this.one, required this.notFound, required this.linkCopied, required this.copyLink, required this.pdfHint, required this.titleHint, required this.signerRoleHint});
  final String failed;
  final String issueTitle;
  final String student;
  final String kind;
  final String fieldTitle;
  final String fieldText;
  final String issue;
  final String serdHint;
  final String issued;
  final String revokeTitle;
  final String reason;
  final String revoke;
  final String revoked;
  final String customizeTitle;
  final String signer;
  final String signerRole;
  final String footer;
  final String serdTitle;
  final String autoSerd;
  final String futureOnly;
  final String saved;
  final String title;
  final String customize;
  final String add;
  final String none;
  final String revokedMark;
  final String one;
  final String notFound;
  final String linkCopied;
  final String copyLink;
  final String pdfHint;
  final String titleHint;
  final String signerRoleHint;
}

/// Messages.
class SChat {
  const SChat({required this.title, required this.newChat, required this.none, required this.noneHint, required this.deletedLast, required this.you, required this.searchName, required this.noContacts, required this.uploadFailed, required this.sendFailed, required this.stillFailing, required this.gallery, required this.camera, required this.imageSize, required this.editTitle, required this.deleteTitle, required this.deleteBody, required this.deleteFailed, required this.unmute, required this.start, required this.deleted, required this.notSent, required this.sending, required this.edited, required this.attach, required this.caption, required this.cantReply, required this.mute, required this.write});
  final String title;
  final String newChat;
  final String none;
  final String noneHint;
  final String deletedLast;
  final String you;
  final String searchName;
  final String noContacts;
  final String uploadFailed;
  final String sendFailed;
  final String stillFailing;
  final String gallery;
  final String camera;
  final String imageSize;
  final String editTitle;
  final String deleteTitle;
  final String deleteBody;
  final String deleteFailed;
  final String unmute;
  final String start;
  final String deleted;
  final String notSent;
  final String sending;
  final String edited;
  final String attach;
  final String caption;
  final String cantReply;
  final String mute;
  final String write;
}

/// Notifications.
class SNotif {
  const SNotif({required this.now, required this.minutesAgo, required this.hoursAgo, required this.today, required this.yesterday, required this.title, required this.markAll, required this.prefs, required this.none, required this.notSaved, required this.noPush, required this.noPermission, required this.paused, required this.quiet, required this.types});
  final String now;
  final String minutesAgo;
  final String hoursAgo;
  final String today;
  final String yesterday;
  final String title;
  final String markAll;
  final String prefs;
  final String none;
  final String notSaved;
  final String noPush;
  final String noPermission;
  final String paused;
  final String quiet;
  final String types;
}

/// Account & data deletion.
class SPriv {
  const SPriv({required this.updated, required this.updateFailed, required this.requestsTitle, required this.noRequests, required this.reviewHint, required this.student, required this.approve, required this.reject, required this.done, required this.confirmTitle, required this.confirmBody, required this.sendRequest, required this.sendFailed, required this.title, required this.intro, required this.last, required this.reason, required this.submit});
  final String updated;
  final String updateFailed;
  final String requestsTitle;
  final String noRequests;
  final String reviewHint;
  final String student;
  final String approve;
  final String reject;
  final String done;
  final String confirmTitle;
  final String confirmBody;
  final String sendRequest;
  final String sendFailed;
  final String title;
  final String intro;
  final String last;
  final String reason;
  final String submit;
}

/// The Quran screens (the text itself stays Arabic).
class SQuran {
  const SQuran({required this.title, required this.surahs, required this.search, required this.continueReading, required this.position, required this.ayahs, required this.noBookmarks, required this.noBookmarksHint, required this.playFailed, required this.ayahOf, required this.playFromHere, required this.unmark, required this.copyAyah, required this.copied, required this.smaller, required this.bigger, required this.loadFailed, required this.repeat, required this.noRepeat, required this.prevAyah, required this.nextAyah, required this.credit, required this.bookmarks, required this.mark, required this.repeatN});
  final String title;
  final String surahs;
  final String search;
  final String continueReading;
  final String position;
  final String ayahs;
  final String noBookmarks;
  final String noBookmarksHint;
  final String playFailed;
  final String ayahOf;
  final String playFromHere;
  final String unmark;
  final String copyAyah;
  final String copied;
  final String smaller;
  final String bigger;
  final String loadFailed;
  final String repeat;
  final String noRepeat;
  final String prevAyah;
  final String nextAyah;
  final String credit;
  final String bookmarks;
  final String mark;
  final String repeatN;
}

/// Reports (the student report is also the portal's).
class SRep {
  const SRep({required this.from, required this.to, required this.title, required this.loadFailed, required this.activeStudents, required this.newStudents, required this.recitations, required this.recitingStudents, required this.points, required this.attendanceRate, required this.serdApproved, required this.certsIssued, required this.copied, required this.copySummary, required this.types, required this.attendance, required this.circles, required this.teachers, required this.top, required this.studentTitle, required this.student, required this.noStudent, required this.teacher, required this.periodRecitations, required this.periodPoints, required this.totalPoints, required this.progress, required this.savedParts, required this.serd, required this.badges, required this.certificates, required this.log, required this.none, required this.circleLine, required this.teacherLine});
  final String from;
  final String to;
  final String title;
  final String loadFailed;
  final String activeStudents;
  final String newStudents;
  final String recitations;
  final String recitingStudents;
  final String points;
  final String attendanceRate;
  final String serdApproved;
  final String certsIssued;
  final String copied;
  final String copySummary;
  final String types;
  final String attendance;
  final String circles;
  final String teachers;
  final String top;
  final String studentTitle;
  final String student;
  final String noStudent;
  final String teacher;
  final String periodRecitations;
  final String periodPoints;
  final String totalPoints;
  final String progress;
  final String savedParts;
  final String serd;
  final String badges;
  final String certificates;
  final String log;
  final String none;
  final String circleLine;
  final String teacherLine;
}

/// Offline uploads.
class SSync {
  const SSync({required this.title, required this.allUp, required this.lastSync, required this.cached, required this.uploadNow, required this.nothing, required this.rejected, required this.discardTitle, required this.discardBody, required this.retry, required this.stripFailed, required this.counts, required this.nothingHint, required this.queued, required this.stripWaiting, required this.stripOffline});
  final String title;
  final String allUp;
  final String lastSync;
  final String cached;
  final String uploadNow;
  final String nothing;
  final String rejected;
  final String discardTitle;
  final String discardBody;
  final String retry;
  final String stripFailed;
  final String counts;
  final String nothingHint;
  final String queued;
  final String stripWaiting;
  final String stripOffline;
}

class S {
  const S({required this.lang, required this.common, required this.labels, required this.banners, required this.portal, required this.record, required this.badges, required this.market, required this.serdCard, required this.ann, required this.cal, required this.cert, required this.chat, required this.notif, required this.priv, required this.quran, required this.rep, required this.sync});
  /// 'ar' or 'en'.
  final String lang;
  bool get isAr => lang == 'ar';
  final SCommon common;
  final SLabels labels;
  final SBanners banners;
  final SPortal portal;
  final SRecord record;
  final SBadges badges;
  final SMarket market;
  final SSerdCard serdCard;
  final SAnn ann;
  final SCal cal;
  final SCert cert;
  final SChat chat;
  final SNotif notif;
  final SPriv priv;
  final SQuran quran;
  final SRep rep;
  final SSync sync;

  static const ar = S(
    lang: 'ar',
    common: SCommon(
      appName: 'بستان القرآن',
      signOut: 'تسجيل خروج',
      loadFailed: 'تعذّر تحميل البيانات',
      checkConnection: 'تأكد من الاتصال بالإنترنت وحاول مرة أخرى',
      retry: 'إعادة المحاولة',
      noPermission: 'لا تملك صلاحية تنفيذ هذه العملية',
      linkedData: 'لا يمكن تنفيذ العملية لوجود بيانات مرتبطة',
      offline: 'تعذّر الاتصال بالإنترنت، حاول مرة أخرى',
      cancel: 'إلغاء',
      save: 'حفظ',
      delete: 'حذف',
      edit: 'تعديل',
      send: 'إرسال',
      close: 'إغلاق',
      confirm: 'تأكيد',
      language: 'اللغة',
      goodMorning: 'صباح الخير',
      goodEvening: 'مساء الخير',
      listSep: '، ',
    ),
    labels: SLabels(
      recitationType: {'new_memorization': 'حفظ جديد', 'recent_review': 'مراجعة قريبة', 'distant_review': 'مراجعة بعيدة'},
      attendance: {'present': 'حاضر', 'absent': 'غائب', 'late': 'متأخر', 'excused': 'مُعذَر'},
      purchase: {'pending': 'قيد التسليم', 'fulfilled': 'تم التسليم', 'cancelled': 'ملغى'},
      metric: {'points': 'متوسط النقاط لكل طالب', 'recitations': 'متوسط عدد التسميعات لكل طالب', 'attendance': 'متوسط أيام الحضور لكل طالب'},
      challengeStatus: {'upcoming': 'قادمة', 'active': 'جارية', 'ended': 'انتهت'},
      serdStatus: {'scheduled': 'مجدول', 'submitted': 'بانتظار الاعتماد', 'approved': 'معتمد', 'rejected': 'مرفوض'},
      months: ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
      rule: {'manual': 'يمنحها المشرف', 'points_threshold': '{n} نقطة', 'recitations_count': '{n} تسميعة', 'grade_count': '{n} تسميعة بتقدير «{grade}»', 'streak_days': '{n} أيام متتالية', 'weekly_attendance': 'حضور أسبوعي {n}%', 'juz_complete': 'إتمام الجزء {n} في السرد', 'serd_passed_count': '{n} سرد ناجح'},
      juz: 'جزء {n}',
      portion: '{den} {ord}',
      portionDen: {'2': 'النصف', '4': 'الربع', '8': 'الثُمن'},
      portionOrd: ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن'],
      audience: {'all': 'الجميع', 'teachers': 'المعلمون', 'students': 'الطلاب', 'guardians': 'أولياء الأمور'},
      consent: {'not_required': '—', 'pending': 'بانتظار الموافقة', 'approved': 'موافق', 'declined': 'رفض'},
      source: {'self': 'سجّل بنفسه', 'guardian': 'سجّله ولي الأمر', 'teacher': 'سجّله المعلم', 'admin': 'سجّله المشرف'},
      registration: {'none': 'بلا تسجيل', 'ended': 'انتهت', 'closed': 'التسجيل مغلق', 'full': 'اكتملت المقاعد', 'open': 'التسجيل مفتوح'},
      weekdays: ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'],
      certKind: {'serd': 'السرد القرآني', 'memorization': 'إتمام حفظ', 'excellence': 'تفوّق', 'attendance': 'انتظام', 'custom': 'مخصّصة'},
      deletionStatus: {'pending': 'قيد المراجعة', 'approved': 'موافَق عليه', 'rejected': 'مرفوض', 'completed': 'اكتمل'},
      roles: {'admin': 'مدير', 'teacher': 'معلم', 'student': 'طالب', 'guardian': 'ولي أمر'},
    ),
    banners: SBanners(
      viewer: 'هذا حساب عرض — البيانات للاطّلاع فقط',
      billingLock: '🍂 انتهى اشتراك المركز — البيانات للاطّلاع فقط حتى التجديد',
    ),
    portal: SPortal(
      tabHome: 'الرئيسية',
      tabRecord: 'سجلّي',
      tabAccount: 'حسابي',
      noChildren: 'لا يوجد أبناء مرتبطون بحسابك',
      notLinked: 'حسابك غير مرتبط بملف طالب',
      askAdmin: 'تواصل مع إدارة المركز لربط الحساب',
      studentMissing: 'تعذّر إيجاد ملف الطالب',
      noStudent: 'لا يوجد ملف طالب مرتبط',
      hello: 'مرحبًا، {name}',
      sheikh: 'الشيخ {name}',
      noCircle: 'لم تُسند إلى حلقة بعد',
      progressTitle: 'تقدّم الحفظ',
      partsOf30: '{n} من 30 جزءًا',
      nextPlan: 'خطتك القادمة: {plan}',
      goalQuran: 'لإكمال حفظ القرآن الكريم',
      goalPoints: 'للوصول إلى {n} نقطة',
      unitJuz: 'جزء',
      unitPoints: 'نقطة',
      remaining: 'باقي {n} {unit}',
      announcements: 'إعلانات',
      upcoming: 'قريبًا',
      prayers: ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'],
      statsTitle: 'إحصائياتك',
      statAyahs: 'آيات هذا الأسبوع',
      statAttendance: 'الحضور الأسبوعي',
      statTotal: 'إجمالي التسميعات',
      statLast: 'آخر تسميع',
      weekTitle: 'أسبوعك',
      weekCount: '{n} تسميعات هذا الأسبوع',
      weekBetter: 'أفضل من الأسبوع الماضي (+{n})',
      weekWorse: 'أقل من الأسبوع الماضي ({n})',
      weekSame: 'ثابت مقارنة بالأسبوع الماضي',
      streak: 'سلسلتك الحالية: {n} يوم  ·  أطول سلسلة: {best}',
      streakRecord: '🎉 رقمك الشخصي الجديد في السلسلة!',
      yourBadges: 'شاراتك',
      calendar: 'التقويم والفعاليات',
      calendarSub: 'الإجازات والرحلات والمسابقات والتسجيل فيها',
      chat: 'المحادثات',
      announcementsLink: 'الإعلانات',
      report: 'التقرير',
      reportSub: 'التسميع والحضور والسرد لفترة تختارها',
      certificates: 'الشهادات',
      quran: 'المصحف',
      quranSub: 'قراءة واستماع وعلامات',
      privacy: 'حسابي وبياناتي',
      privacySub: 'طلب حذف الحساب والبيانات',
      notifications: 'الإشعارات',
      badges: 'الشارات',
      market: 'السوق',
      serd: 'السرد القرآني',
      recent: 'آخر التسميعات',
      noRecitations: 'لا يوجد تسميعات بعد',
      studentCode: 'رقم الطالب',
      circle: 'الحلقة',
      stage: 'المرحلة',
      teacher: 'الشيخ',
      phone: 'الجوال',
      address: 'العنوان',
      languageHint: 'لغة التطبيق',
    ),
    record: SRecord(
      tabRecitations: 'التسميع',
      tabAttendance: 'الحضور',
      tabSerd: 'السرد',
      thisMonth: 'هذا الشهر',
      recitations: 'تسميعات',
      ayahs: 'آيات',
      attendance: 'حضور',
      points: 'نقاط',
      breakdown: 'تفصيل النقاط',
      noAttendance: 'لا يوجد سجل حضور بعد',
      search: 'بحث بالسورة أو الملاحظة',
      all: 'الكل',
      noResults: 'لا يوجد نتائج',
      session: '{n} تسميعات في جلسة واحدة',
    ),
    badges: SBadges(
      title: 'الشارات والمنافسة',
      mine: 'شاراتي',
      none: 'لا توجد شارات في مركزك بعد',
      earned: '✓ مكتسبة {date}',
      expires: '  ·  تنتهي {date}',
      manual: 'يمنحها المشرف',
      board: 'لوحة الشرف — {circle}',
      points: '{n} نقطة',
      challenge: 'منافسة الحلقات: {title}',
    ),
    market: SMarket(
      title: 'سوق النقاط',
      disabled: 'السوق غير مفعّل في مركزك حاليًا',
      balance: 'الرصيد',
      earned: 'من {n} نقطة  ·  المصروف {spent}',
      pending: '  ·  {n} نقطة تنتظر اكتمال وحدة تحويل',
      available: 'المتاح للشراء',
      empty: 'لا توجد عناصر حاليًا',
      stock: 'المتبقي: {n}',
      bought: 'تم الطلب ✓ سيُسلَّم من المركز',
      soldOut: 'نفد',
      buy: 'شراء',
      tooPoor: 'الرصيد لا يكفي',
      orders: 'طلباتي',
      noOrders: 'لا توجد طلبات بعد',
      cancelled: 'أُلغي الطلب وعاد الرصيد',
    ),
    serdCard: SSerdCard(
      none: 'لا يوجد سرد معتمد بعد',
      sessions: 'جلسات معتمدة',
      average: 'المتوسط',
      best: 'الأفضل',
      covered: 'ما سُرد',
      juzCount: '{n} جزء',
      complete: 'أجزاء مكتملة: {list}',
      partial: 'جزئي: {list}',
      partialItem: 'جزء {juz} — {e}/8',
    ),
    ann: SAnn(
      title: 'الإعلانات',
      newTitle: 'إعلان جديد',
      none: 'لا توجد إعلانات',
      draft: 'مسودة',
      required: 'العنوان والنص مطلوبان',
      deleteTitle: 'حذف الإعلان',
      sure: 'متأكد؟',
      fieldTitle: 'العنوان',
      fieldBody: 'النص',
      audience: 'الجمهور',
      circleOptional: 'حلقة محددة (اختياري)',
      allCircles: 'كل الحلقات',
      pin: 'تثبيت في الأعلى',
      publish: 'نشر الآن',
      publishHint: 'يصل إشعار للجمهور عند أول نشر',
      editTitle: 'تعديل إعلان',
      yourCircle: 'حلقتك',
    ),
    cal: SCal(
      settingLoadFailed: 'تعذّر تحميل الإعداد',
      reminderTitle: 'تذكير المسجّلين',
      reminderHours: 'قبل بدء الفعالية بـ (ساعة) — 0 = إيقاف',
      reminderHelp: 'يصل التذكير لأولياء أمور الطلاب المسجّلين وللطلاب',
      reminderSaved: 'حُفظ إعداد التذكير',
      saveFailed: 'تعذّر الحفظ',
      title: 'التقويم والفعاليات',
      reminderTip: 'التذكير قبل الفعالية',
      types: 'أنواع العناصر',
      add: 'إضافة',
      legend: 'أيام الدوام: {working} من {total}  ·  الرمادي = غير دوام  ·  «سرد» = يوم سرد',
      thisMonth: 'عناصر هذا الشهر',
      nothing: 'لا يوجد شيء',
      youRegistered: 'أنت مسجّل ✓',
      dayOff: 'غير دوام',
      serdScheduled: 'سرد مجدول: {name}',
      serd: 'سرد',
      linkCopied: 'تم نسخ رابط الموافقة',
      registeredDone: 'تم التسجيل',
      resultOf: 'نتيجة {name}',
      rank: 'الترتيب',
      note: 'ملاحظة',
      resultSaved: 'حُفظت النتيجة',
      details: 'تفاصيل',
      registration: 'التسجيل',
      participants: 'المسجّلون ({n})',
      registerStudent: 'تسجيل طالب',
      noParticipants: 'لا يوجد مسجّلون بعد',
      waitlistCount: 'قائمة الانتظار ({n})',
      circle: 'حلقة {name}',
      stage: 'مرحلة {name}',
      workDay: 'يوم دوام',
      taken: 'المسجّلون: {n}',
      waiting: 'الانتظار: {n}',
      deadline: 'آخر موعد: {date}',
      needsConsent: 'تحتاج موافقة ولي الأمر',
      unregister: 'إلغاء التسجيل',
      unregistered: 'أُلغي التسجيل',
      staffRegistered: 'سجّله المعلم أو المشرف — للإلغاء تواصل معه',
      register: 'تسجيل',
      waitlisted: 'أُضيف إلى قائمة الانتظار',
      joinWaitlist: 'انضم لقائمة الانتظار',
      leftWaitlist: 'خرج من قائمة الانتظار',
      leaveWaitlist: 'اخرج من قائمة الانتظار',
      registeredChip: 'مسجّل ✓',
      waitingChip: 'في الانتظار',
      consent: 'موافقة ولي الأمر: {status}',
      copyLink: 'نسخ الرابط',
      result: 'النتيجة: الترتيب {rank}',
      rankN: 'الترتيب {rank}',
      copyConsent: 'نسخ رابط الموافقة',
      consentRecorded: 'سُجّلت الموافقة',
      phoneConsent: 'موافقة هاتفية',
      declineRecorded: 'سُجّل الرفض',
      decline: 'رفض',
      resultBtn: 'النتيجة',
      searchStudent: 'ابحث باسم الطالب أو رقمه',
      onDay: 'عناصر يوم {day}',
      takenShort: '{n} مسجّل',
      offDay: 'ليس يوم دوام (لا يُحتسب في نسبة الحضور)',
      unregisterQ: 'إلغاء تسجيل {name}؟',
    ),
    cert: SCert(
      failed: 'تعذّر تنفيذ العملية',
      issueTitle: 'إصدار شهادة',
      student: 'الطالب',
      kind: 'النوع',
      fieldTitle: 'عنوان الشهادة',
      fieldText: 'النص (اختياري)',
      issue: 'إصدار الشهادة',
      serdHint: 'شهادة السرد تُصدر من شاشة السرد بعد الاعتماد.',
      issued: 'صدرت الشهادة',
      revokeTitle: 'سحب الشهادة',
      reason: 'السبب (اختياري)',
      revoke: 'سحب',
      revoked: 'سُحبت الشهادة',
      customizeTitle: 'تخصيص الشهادة لمركزك',
      signer: 'اسم الموقِّع',
      signerRole: 'صفته',
      footer: 'عبارة أسفل الشهادة',
      serdTitle: 'عنوان شهادة السرد',
      autoSerd: 'إصدار شهادة السرد تلقائيًا عند اعتماد جلسة ناجحة',
      futureOnly: 'التغييرات تسري على الشهادات القادمة فقط؛ ما صدر سابقًا يبقى كما هو.',
      saved: 'حُفظت الإعدادات',
      title: 'الشهادات',
      customize: 'تخصيص الشهادة',
      add: 'شهادة',
      none: 'لا توجد شهادات بعد',
      revokedMark: ' · ملغاة',
      one: 'الشهادة',
      notFound: 'الشهادة غير موجودة',
      linkCopied: 'نُسخ رابط التحقق',
      copyLink: 'نسخ رابط التحقق من الشهادة',
      pdfHint: 'للحصول على نسخة PDF مطبوعة افتح الشهادة من المتصفح واختر «طباعة / حفظ PDF».',
      titleHint: 'شهادة تفوّق',
      signerRoleHint: 'مدير المركز',
    ),
    chat: SChat(
      title: 'المحادثات',
      newChat: 'محادثة جديدة',
      none: 'لا توجد محادثات بعد',
      noneHint: 'ابدأ محادثة جديدة بالزر أدناه',
      deletedLast: '🚫 حُذفت رسالة',
      you: 'أنت: ',
      searchName: 'ابحث بالاسم',
      noContacts: 'لا يوجد من يمكنك مراسلته',
      uploadFailed: 'تعذّر رفع الصورة',
      sendFailed: 'تعذّر الإرسال، تأكد من الإنترنت وحاول مجددًا',
      stillFailing: 'ما زال تعذّر الإرسال',
      gallery: 'من المعرض',
      camera: 'التقاط صورة',
      imageSize: 'حجم الصورة الأقصى 5 ميغابايت',
      editTitle: 'تعديل الرسالة',
      deleteTitle: 'حذف الرسالة',
      deleteBody: 'تُحذف عندك وعند الطرف الآخر ولا يمكن التراجع.',
      deleteFailed: 'تعذّر الحذف — تحقّق من الاتصال',
      unmute: 'تفعيل التنبيهات',
      start: 'ابدأ المحادثة',
      deleted: 'حُذفت هذه الرسالة',
      notSent: 'لم يُرسل — اضغط لإعادة المحاولة',
      sending: 'جارٍ الإرسال...',
      edited: ' · عُدّلت',
      attach: 'إرفاق صورة',
      caption: 'أضف تعليقًا (اختياري)...',
      cantReply: 'لا يمكنك مراسلة هذا المستخدم حاليًا',
      mute: 'كتم',
      write: 'اكتب رسالتك...',
    ),
    notif: SNotif(
      now: 'الآن',
      minutesAgo: 'قبل {n} دقيقة',
      hoursAgo: 'قبل {n} ساعة',
      today: 'اليوم',
      yesterday: 'أمس',
      title: 'الإشعارات',
      markAll: 'تعليم الكل كمقروء',
      prefs: 'ما الذي يصلني',
      none: 'لا توجد إشعارات',
      notSaved: 'لم يُحفظ التغيير. تحقّق من الاتصال وأعد المحاولة.',
      noPush: 'الإشعارات الفورية غير مفعّلة في هذه النسخة من التطبيق — تصلك داخل التطبيق فقط.',
      noPermission: 'لم يُمنح التطبيق إذن الإشعارات. افتح إعدادات الهاتف ← التطبيقات ← بستان القرآن ← الإشعارات وفعّلها.',
      paused: 'أوقف المركز إرسال الإشعارات مؤقتًا — تبقى القائمة داخل التطبيق تعمل.',
      quiet: 'لا تصل إشعارات الهاتف بين {from} و{to} — تُؤجَّل إلى الصباح.',
      types: 'أنواع الإشعارات',
    ),
    priv: SPriv(
      updated: 'تم تحديث الطلب',
      updateFailed: 'تعذّر التحديث',
      requestsTitle: 'طلبات حذف البيانات',
      noRequests: 'لا طلبات',
      reviewHint: '«موافقة» تعني أنك ستحذف الحساب والبيانات بنفسك، ثم اضغط «اكتمل» ليصل إشعار لصاحب الطلب.',
      student: 'الطالب: {name}',
      approve: 'موافقة',
      reject: 'رفض',
      done: 'اكتمل الحذف',
      confirmTitle: 'طلب حذف الحساب والبيانات',
      confirmBody: 'سيُرسل طلبك إلى إدارة المركز لمراجعته. متأكد؟',
      sendRequest: 'إرسال الطلب',
      sendFailed: 'تعذّر إرسال الطلب',
      title: 'حسابي وبياناتي',
      intro: 'يمكنك طلب حذف حسابك وبياناتك من {org}. تراجع الإدارة الطلب ويصلك إشعار بالنتيجة. يخص هذا المركز فقط.',
      last: 'آخر طلب: {status}',
      reason: 'السبب (اختياري)',
      submit: 'طلب حذف حسابي وبياناتي',
    ),
    quran: SQuran(
      title: 'المصحف',
      surahs: 'السور',
      search: 'ابحث باسم السورة أو رقمها',
      continueReading: 'أكمل القراءة',
      position: 'سورة {surah} — الآية {ayah}',
      ayahs: '{n} آية',
      noBookmarks: 'لا توجد علامات',
      noBookmarksHint: 'اضغط على آية في المصحف لإضافة علامة',
      playFailed: 'تعذّر تشغيل التلاوة، تأكد من الإنترنت',
      ayahOf: '{surah} — الآية {ayah}',
      playFromHere: 'تشغيل من هنا',
      unmark: 'إزالة العلامة',
      copyAyah: 'نسخ الآية',
      copied: 'تم النسخ',
      smaller: 'تصغير الخط',
      bigger: 'تكبير الخط',
      loadFailed: 'تعذّر تحميل السورة، تأكد من الإنترنت',
      repeat: 'تكرار الآية',
      noRepeat: 'بلا تكرار',
      prevAyah: 'الآية السابقة',
      nextAyah: 'الآية التالية',
      credit: 'نص المصحف: مشروع تنزيل (tanzil.net) · التلاوات: everyayah.com',
      bookmarks: 'العلامات',
      mark: 'إضافة علامة',
      repeatN: 'تكرار الآية {n} مرات',
    ),
    rep: SRep(
      from: 'من {date}',
      to: 'إلى {date}',
      title: 'التقارير',
      loadFailed: 'تعذّر تحميل التقرير',
      activeStudents: 'الطلاب النشطون',
      newStudents: 'طلاب جدد',
      recitations: 'التسميعات',
      recitingStudents: 'طلاب سمّعوا',
      points: 'النقاط',
      attendanceRate: 'نسبة الحضور',
      serdApproved: 'سرد معتمد',
      certsIssued: 'شهادات صدرت',
      copied: 'نُسخ ملخص التقرير',
      copySummary: 'نسخ الملخص',
      types: 'أنواع التسميع',
      attendance: 'الحضور',
      circles: 'الحلقات',
      teachers: 'المعلمون',
      top: 'الأعلى نقاطًا',
      studentTitle: 'تقرير الطالب',
      student: 'الطالب',
      noStudent: 'لا يوجد طالب مرتبط بحسابك',
      teacher: ' · المعلم: {name}',
      periodRecitations: 'تسميعات الفترة',
      periodPoints: 'نقاط الفترة',
      totalPoints: 'مجموع النقاط',
      progress: 'التقدّم',
      savedParts: 'الأجزاء المحفوظة',
      serd: 'السرد القرآني',
      badges: 'الشارات',
      certificates: 'الشهادات',
      log: 'سجل التسميع',
      none: 'لا تسميعات في هذه الفترة',
      circleLine: '{teacher} · {students} طالب\\nتسميعات {recitations} · نقاط {points} · حضور {attendance}',
      teacherLine: '{recitations} تسميع · {points} نقطة',
    ),
    sync: SSync(
      title: 'المزامنة',
      allUp: 'كل شيء مرفوع',
      lastSync: 'آخر رفع ناجح: {time}',
      cached: 'تُعرض بيانات محفوظة سابقًا لأن الاتصال غير متاح',
      uploadNow: 'ارفع الآن',
      nothing: 'لا يوجد شيء في الانتظار',
      rejected: 'رُفض من الخادم: {error}',
      discardTitle: 'حذف من الانتظار؟',
      discardBody: 'لن يُرفع هذا السجل أبدًا.',
      retry: 'أعد المحاولة',
      stripFailed: 'بعض السجلات رُفضت ({n}) — اضغط للمراجعة',
      counts: 'بانتظار الرفع: {waiting} · تحتاج مراجعة: {failed}',
      nothingHint: 'ما تسجّله دون اتصال يظهر هنا حتى يُرفع.',
      queued: 'سُجّل {time} · محاولات: {n}',
      stripWaiting: 'بانتظار الرفع: {n} — يُرفع تلقائيًا عند عودة الاتصال',
      stripOffline: 'لا يوجد اتصال — تُعرض بيانات محفوظة',
    ),
  );

  static const en = S(
    lang: 'en',
    common: SCommon(
      appName: 'Bustan Al-Quran',
      signOut: 'Sign out',
      loadFailed: 'Could not load the data',
      checkConnection: 'Check your internet connection and try again',
      retry: 'Try again',
      noPermission: 'You don’t have permission to do this',
      linkedData: 'This can’t be done because other data depends on it',
      offline: 'No internet connection, try again',
      cancel: 'Cancel',
      save: 'Save',
      delete: 'Delete',
      edit: 'Edit',
      send: 'Send',
      close: 'Close',
      confirm: 'Confirm',
      language: 'Language',
      goodMorning: 'Good morning',
      goodEvening: 'Good evening',
      listSep: ', ',
    ),
    labels: SLabels(
      recitationType: {'new_memorization': 'New memorization', 'recent_review': 'Recent review', 'distant_review': 'Distant review'},
      attendance: {'present': 'Present', 'absent': 'Absent', 'late': 'Late', 'excused': 'Excused'},
      purchase: {'pending': 'Awaiting delivery', 'fulfilled': 'Delivered', 'cancelled': 'Cancelled'},
      metric: {'points': 'Average points per student', 'recitations': 'Average recitations per student', 'attendance': 'Average attendance days per student'},
      challengeStatus: {'upcoming': 'Upcoming', 'active': 'Running', 'ended': 'Ended'},
      serdStatus: {'scheduled': 'Scheduled', 'submitted': 'Awaiting approval', 'approved': 'Approved', 'rejected': 'Rejected'},
      months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      rule: {'manual': 'Awarded by the admin', 'points_threshold': '{n} points', 'recitations_count': '{n} recitations', 'grade_count': '{n} recitations graded “{grade}”', 'streak_days': '{n} days in a row', 'weekly_attendance': '{n}% weekly attendance', 'juz_complete': 'Complete juz {n} in serd', 'serd_passed_count': '{n} passed serd sessions'},
      juz: 'Juz {n}',
      portion: '{ord} {den}',
      portionDen: {'2': 'half', '4': 'quarter', '8': 'eighth'},
      portionOrd: ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'],
      audience: {'all': 'Everyone', 'teachers': 'Teachers', 'students': 'Students', 'guardians': 'Guardians'},
      consent: {'not_required': '—', 'pending': 'Awaiting consent', 'approved': 'Agreed', 'declined': 'Declined'},
      source: {'self': 'Registered themselves', 'guardian': 'Registered by the guardian', 'teacher': 'Registered by the teacher', 'admin': 'Registered by the admin'},
      registration: {'none': 'No registration', 'ended': 'Ended', 'closed': 'Registration closed', 'full': 'All places taken', 'open': 'Registration open'},
      weekdays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      certKind: {'serd': 'Quran serd', 'memorization': 'Memorization completed', 'excellence': 'Excellence', 'attendance': 'Regular attendance', 'custom': 'Custom'},
      deletionStatus: {'pending': 'Under review', 'approved': 'Approved', 'rejected': 'Declined', 'completed': 'Completed'},
      roles: {'admin': 'Admin', 'teacher': 'Teacher', 'student': 'Student', 'guardian': 'Guardian'},
    ),
    banners: SBanners(
      viewer: 'This is a viewing account — the data is read-only',
      billingLock: '🍂 The center’s subscription has ended — the data is read-only until it is renewed',
    ),
    portal: SPortal(
      tabHome: 'Home',
      tabRecord: 'My record',
      tabAccount: 'Account',
      noChildren: 'No children are linked to your account',
      notLinked: 'Your account isn’t linked to a student profile',
      askAdmin: 'Contact the center’s administration to link your account',
      studentMissing: 'Could not find the student’s profile',
      noStudent: 'No student profile is linked',
      hello: 'Hello, {name}',
      sheikh: 'Sheikh {name}',
      noCircle: 'Not assigned to a circle yet',
      progressTitle: 'Memorization progress',
      partsOf30: '{n} of 30 juz',
      nextPlan: 'Your next plan: {plan}',
      goalQuran: 'to complete memorizing the Quran',
      goalPoints: 'to reach {n} points',
      unitJuz: 'juz',
      unitPoints: 'points',
      remaining: '{n} {unit} left',
      announcements: 'Announcements',
      upcoming: 'Coming up',
      prayers: ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
      statsTitle: 'Your stats',
      statAyahs: 'Ayahs this week',
      statAttendance: 'Weekly attendance',
      statTotal: 'Total recitations',
      statLast: 'Last recitation',
      weekTitle: 'Your week',
      weekCount: '{n} recitations this week',
      weekBetter: 'Better than last week (+{n})',
      weekWorse: 'Fewer than last week ({n})',
      weekSame: 'Same as last week',
      streak: 'Current streak: {n} days  ·  Longest: {best}',
      streakRecord: '🎉 A new personal best streak!',
      yourBadges: 'Your badges',
      calendar: 'Calendar & events',
      calendarSub: 'Holidays, trips and competitions — and signing up',
      chat: 'Messages',
      announcementsLink: 'Announcements',
      report: 'Report',
      reportSub: 'Recitation, attendance and serd for a period you choose',
      certificates: 'Certificates',
      quran: 'Quran',
      quranSub: 'Read, listen and bookmark',
      privacy: 'My account & data',
      privacySub: 'Request deletion of the account and data',
      notifications: 'Notifications',
      badges: 'Badges',
      market: 'Market',
      serd: 'Quran serd',
      recent: 'Latest recitations',
      noRecitations: 'No recitations yet',
      studentCode: 'Student number',
      circle: 'Circle',
      stage: 'Stage',
      teacher: 'Sheikh',
      phone: 'Phone',
      address: 'Address',
      languageHint: 'App language',
    ),
    record: SRecord(
      tabRecitations: 'Recitation',
      tabAttendance: 'Attendance',
      tabSerd: 'Serd',
      thisMonth: 'This month',
      recitations: 'Recitations',
      ayahs: 'Ayahs',
      attendance: 'Attendance',
      points: 'Points',
      breakdown: 'Points breakdown',
      noAttendance: 'No attendance records yet',
      search: 'Search by surah or note',
      all: 'All',
      noResults: 'No results',
      session: '{n} recitations in one session',
    ),
    badges: SBadges(
      title: 'Badges & competition',
      mine: 'My badges',
      none: 'Your center has no badges yet',
      earned: '✓ Earned {date}',
      expires: '  ·  expires {date}',
      manual: 'Awarded by the admin',
      board: 'Honor board — {circle}',
      points: '{n} points',
      challenge: 'Circle challenge: {title}',
    ),
    market: SMarket(
      title: 'Points market',
      disabled: 'The market is not enabled at your center right now',
      balance: 'Balance',
      earned: 'From {n} points  ·  spent {spent}',
      pending: '  ·  {n} points waiting to complete a conversion unit',
      available: 'Available to buy',
      empty: 'Nothing available right now',
      stock: 'Left: {n}',
      bought: 'Ordered ✓ — the center will hand it over',
      soldOut: 'Sold out',
      buy: 'Buy',
      tooPoor: 'Not enough balance',
      orders: 'My orders',
      noOrders: 'No orders yet',
      cancelled: 'Order cancelled and balance returned',
    ),
    serdCard: SSerdCard(
      none: 'No approved serd yet',
      sessions: 'Approved sessions',
      average: 'Average',
      best: 'Best',
      covered: 'Covered',
      juzCount: '{n} juz',
      complete: 'Completed juz: {list}',
      partial: 'Partial: {list}',
      partialItem: 'Juz {juz} — {e}/8',
    ),
    ann: SAnn(
      title: 'Announcements',
      newTitle: 'New announcement',
      none: 'No announcements',
      draft: 'Draft',
      required: 'Title and text are required',
      deleteTitle: 'Delete announcement',
      sure: 'Are you sure?',
      fieldTitle: 'Title',
      fieldBody: 'Text',
      audience: 'Audience',
      circleOptional: 'A specific circle (optional)',
      allCircles: 'All circles',
      pin: 'Pin to the top',
      publish: 'Publish now',
      publishHint: 'The audience is notified the first time it’s published',
      editTitle: 'Edit announcement',
      yourCircle: 'Your circle',
    ),
    cal: SCal(
      settingLoadFailed: 'Could not load the setting',
      reminderTitle: 'Remind the registered',
      reminderHours: 'Hours before the event starts — 0 = off',
      reminderHelp: 'Sent to the registered students and their guardians',
      reminderSaved: 'Reminder setting saved',
      saveFailed: 'Could not save',
      title: 'Calendar & events',
      reminderTip: 'Reminder before the event',
      types: 'Entry types',
      add: 'Add',
      legend: 'Working days: {working} of {total}  ·  grey = day off  ·  “Serd” = serd day',
      thisMonth: 'This month',
      nothing: 'Nothing here',
      youRegistered: 'You’re registered ✓',
      dayOff: 'Day off',
      serdScheduled: 'Scheduled serd: {name}',
      serd: 'Serd',
      linkCopied: 'Consent link copied',
      registeredDone: 'Registered',
      resultOf: 'Result for {name}',
      rank: 'Rank',
      note: 'Note',
      resultSaved: 'Result saved',
      details: 'Details',
      registration: 'Registration',
      participants: 'Registered ({n})',
      registerStudent: 'Register a student',
      noParticipants: 'No one registered yet',
      waitlistCount: 'Waiting list ({n})',
      circle: '{name} circle',
      stage: '{name} stage',
      workDay: 'Working day',
      taken: 'Registered: {n}',
      waiting: 'Waiting: {n}',
      deadline: 'Deadline: {date}',
      needsConsent: 'Needs guardian consent',
      unregister: 'Cancel registration',
      unregistered: 'Registration cancelled',
      staffRegistered: 'Registered by the teacher or admin — contact them to cancel',
      register: 'Register',
      waitlisted: 'Added to the waiting list',
      joinWaitlist: 'Join the waiting list',
      leftWaitlist: 'Left the waiting list',
      leaveWaitlist: 'Leave the waiting list',
      registeredChip: 'Registered ✓',
      waitingChip: 'Waiting',
      consent: 'Guardian consent: {status}',
      copyLink: 'Copy link',
      result: 'Result: rank {rank}',
      rankN: 'Rank {rank}',
      copyConsent: 'Copy consent link',
      consentRecorded: 'Consent recorded',
      phoneConsent: 'Consent by phone',
      declineRecorded: 'Refusal recorded',
      decline: 'Declined',
      resultBtn: 'Result',
      searchStudent: 'Search by student name or number',
      onDay: 'Entries on day {day}',
      takenShort: '{n} registered',
      offDay: 'Not a working day (not counted in the attendance rate)',
      unregisterQ: 'Cancel {name}’s registration?',
    ),
    cert: SCert(
      failed: 'Could not complete the action',
      issueTitle: 'Issue a certificate',
      student: 'Student',
      kind: 'Type',
      fieldTitle: 'Certificate title',
      fieldText: 'Text (optional)',
      issue: 'Issue the certificate',
      serdHint: 'Serd certificates are issued from the serd screen after approval.',
      issued: 'Certificate issued',
      revokeTitle: 'Revoke the certificate',
      reason: 'Reason (optional)',
      revoke: 'Revoke',
      revoked: 'Certificate revoked',
      customizeTitle: 'Customize the certificate for your center',
      signer: 'Signer name',
      signerRole: 'Their title',
      footer: 'Footer line',
      serdTitle: 'Serd certificate title',
      autoSerd: 'Issue the serd certificate automatically when a passing session is approved',
      futureOnly: 'Changes apply to future certificates only; issued ones stay as they are.',
      saved: 'Settings saved',
      title: 'Certificates',
      customize: 'Customize the certificate',
      add: 'Certificate',
      none: 'No certificates yet',
      revokedMark: ' · revoked',
      one: 'Certificate',
      notFound: 'Certificate not found',
      linkCopied: 'Verification link copied',
      copyLink: 'Copy the certificate’s verification link',
      pdfHint: 'For a printable PDF, open the certificate in a browser and choose “Print / save as PDF”.',
      titleHint: 'Certificate of excellence',
      signerRoleHint: 'Center director',
    ),
    chat: SChat(
      title: 'Messages',
      newChat: 'New conversation',
      none: 'No conversations yet',
      noneHint: 'Start a new one with the button below',
      deletedLast: '🚫 A message was deleted',
      you: 'You: ',
      searchName: 'Search by name',
      noContacts: 'There is no one you can message',
      uploadFailed: 'Could not upload the image',
      sendFailed: 'Could not send — check your connection and try again',
      stillFailing: 'Still could not send',
      gallery: 'From the gallery',
      camera: 'Take a photo',
      imageSize: 'Maximum image size is 5 MB',
      editTitle: 'Edit message',
      deleteTitle: 'Delete message',
      deleteBody: 'It will be deleted for you and the other person, and cannot be undone.',
      deleteFailed: 'Could not delete — check your connection',
      unmute: 'Unmute',
      start: 'Start the conversation',
      deleted: 'This message was deleted',
      notSent: 'Not sent — tap to retry',
      sending: 'Sending...',
      edited: ' · edited',
      attach: 'Attach an image',
      caption: 'Add a caption (optional)...',
      cantReply: 'You can’t message this user right now',
      mute: 'Mute',
      write: 'Write your message...',
    ),
    notif: SNotif(
      now: 'Now',
      minutesAgo: '{n} min ago',
      hoursAgo: '{n} h ago',
      today: 'Today',
      yesterday: 'Yesterday',
      title: 'Notifications',
      markAll: 'Mark all as read',
      prefs: 'What I receive',
      none: 'No notifications',
      notSaved: 'The change wasn’t saved. Check your connection and try again.',
      noPush: 'Push notifications aren’t enabled in this version of the app — you’ll see them inside the app only.',
      noPermission: 'The app hasn’t been allowed to send notifications. Open the phone’s Settings → Apps → Bustan Al-Quran → Notifications and turn them on.',
      paused: 'The center has paused notifications for now — the in-app list still works.',
      quiet: 'Phone notifications are held between {from} and {to} — they arrive in the morning.',
      types: 'Notification types',
    ),
    priv: SPriv(
      updated: 'Request updated',
      updateFailed: 'Could not update',
      requestsTitle: 'Data deletion requests',
      noRequests: 'No requests',
      reviewHint: '“Approve” means you will delete the account and data yourself, then press “Deleted” so the requester is notified.',
      student: 'Student: {name}',
      approve: 'Approve',
      reject: 'Decline',
      done: 'Deleted',
      confirmTitle: 'Request deletion of the account and data',
      confirmBody: 'Your request goes to the center’s administration for review. Are you sure?',
      sendRequest: 'Send the request',
      sendFailed: 'Could not send the request',
      title: 'My account & data',
      intro: 'You can ask {org} to delete your account and data. The administration reviews the request and you are notified of the outcome. This only concerns this center.',
      last: 'Latest request: {status}',
      reason: 'Reason (optional)',
      submit: 'Request deletion of my account and data',
    ),
    quran: SQuran(
      title: 'Quran',
      surahs: 'Surahs',
      search: 'Search by surah name or number',
      continueReading: 'Continue reading',
      position: '{surah} — ayah {ayah}',
      ayahs: '{n} ayahs',
      noBookmarks: 'No bookmarks',
      noBookmarksHint: 'Tap an ayah in the Quran to bookmark it',
      playFailed: 'Could not play the recitation — check your connection',
      ayahOf: '{surah} — ayah {ayah}',
      playFromHere: 'Play from here',
      unmark: 'Remove bookmark',
      copyAyah: 'Copy the ayah',
      copied: 'Copied',
      smaller: 'Smaller text',
      bigger: 'Bigger text',
      loadFailed: 'Could not load the surah — check your connection',
      repeat: 'Repeat the ayah',
      noRepeat: 'No repeat',
      prevAyah: 'Previous ayah',
      nextAyah: 'Next ayah',
      credit: 'Quran text: Tanzil project (tanzil.net) · Recitations: everyayah.com',
      bookmarks: 'Bookmarks',
      mark: 'Add bookmark',
      repeatN: 'Repeat the ayah {n} times',
    ),
    rep: SRep(
      from: 'From {date}',
      to: 'To {date}',
      title: 'Reports',
      loadFailed: 'Could not load the report',
      activeStudents: 'Active students',
      newStudents: 'New students',
      recitations: 'Recitations',
      recitingStudents: 'Students who recited',
      points: 'Points',
      attendanceRate: 'Attendance rate',
      serdApproved: 'Approved serd',
      certsIssued: 'Certificates issued',
      copied: 'Report summary copied',
      copySummary: 'Copy summary',
      types: 'Recitation types',
      attendance: 'Attendance',
      circles: 'Circles',
      teachers: 'Teachers',
      top: 'Top points',
      studentTitle: 'Student report',
      student: 'Student',
      noStudent: 'No student is linked to your account',
      teacher: ' · Teacher: {name}',
      periodRecitations: 'Recitations in period',
      periodPoints: 'Points in period',
      totalPoints: 'Total points',
      progress: 'Progress',
      savedParts: 'Juz memorized',
      serd: 'Quran serd',
      badges: 'Badges',
      certificates: 'Certificates',
      log: 'Recitation log',
      none: 'No recitations in this period',
      circleLine: '{teacher} · {students} students\\n{recitations} recitations · {points} points · {attendance} attendance',
      teacherLine: '{recitations} recitations · {points} points',
    ),
    sync: SSync(
      title: 'Sync',
      allUp: 'Everything is uploaded',
      lastSync: 'Last successful upload: {time}',
      cached: 'Showing saved data because there’s no connection',
      uploadNow: 'Upload now',
      nothing: 'Nothing waiting',
      rejected: 'Rejected by the server: {error}',
      discardTitle: 'Remove from the queue?',
      discardBody: 'This record will never be uploaded.',
      retry: 'Try again',
      stripFailed: 'Some records were rejected ({n}) — tap to review',
      counts: 'Waiting: {waiting} · need review: {failed}',
      nothingHint: 'What you record offline shows here until it’s uploaded.',
      queued: 'Recorded {time} · attempts: {n}',
      stripWaiting: 'Waiting to upload: {n} — goes up automatically when back online',
      stripOffline: 'No connection — showing saved data',
    ),
  );

}

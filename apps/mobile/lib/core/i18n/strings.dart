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

/// Students needing attention.
class SAttn {
  const SAttn({required this.title, required this.hint, required this.none, required this.behind, required this.idle, required this.never, required this.absences, required this.all, required this.filterBehind, required this.filterIdle, required this.filterAbsent, required this.recite, required this.call, required this.lastRecited, required this.count});
  final String title;
  final String hint;
  final String none;
  final String behind;
  final String idle;
  final String never;
  final String absences;
  final String all;
  final String filterBehind;
  final String filterIdle;
  final String filterAbsent;
  final String recite;
  final String call;
  final String lastRecited;
  final String count;
}

/// Sign in, join, onboarding and the center picker.
class SAuth {
  const SAuth({required this.thisCenter, required this.noCenter, required this.badLogin, required this.notMember, required this.serverDown, required this.codeFirst, required this.openFailed, required this.signInTitle, required this.step1, required this.centerCode, required this.enterCode, required this.noCenterShort, required this.codeHint, required this.step2, required this.loginId, required this.enterId, required this.password, required this.enterPassword, required this.forgot, required this.signInTo, required this.signIn, required this.whoHint, required this.confirmEmail, required this.joinFailed, required this.joinTitle, required this.invalidInvite, required this.invalidBody, required this.inviteFrom, required this.asRole, required this.signedInAs, required this.confirmJoin, required this.inviteEmail, required this.yourPassword, required this.createPassword, required this.signInJoin, required this.createJoin, required this.noAccount, required this.haveAccount, required this.ob1, required this.ob1Body, required this.ob2, required this.ob2Body, required this.ob3, required this.ob3Body, required this.openSignup, required this.skip, required this.signInBtn, required this.next, required this.registerCenter, required this.pickCenter, required this.noCenters, required this.noCentersHint});
  final String thisCenter;
  final String noCenter;
  final String badLogin;
  final String notMember;
  final String serverDown;
  final String codeFirst;
  final String openFailed;
  final String signInTitle;
  final String step1;
  final String centerCode;
  final String enterCode;
  final String noCenterShort;
  final String codeHint;
  final String step2;
  final String loginId;
  final String enterId;
  final String password;
  final String enterPassword;
  final String forgot;
  final String signInTo;
  final String signIn;
  final String whoHint;
  final String confirmEmail;
  final String joinFailed;
  final String joinTitle;
  final String invalidInvite;
  final String invalidBody;
  final String inviteFrom;
  final String asRole;
  final String signedInAs;
  final String confirmJoin;
  final String inviteEmail;
  final String yourPassword;
  final String createPassword;
  final String signInJoin;
  final String createJoin;
  final String noAccount;
  final String haveAccount;
  final String ob1;
  final String ob1Body;
  final String ob2;
  final String ob2Body;
  final String ob3;
  final String ob3Body;
  final String openSignup;
  final String skip;
  final String signInBtn;
  final String next;
  final String registerCenter;
  final String pickCenter;
  final String noCenters;
  final String noCentersHint;
}

/// Badges (staff).
class SBadgesStaff {
  const SBadgesStaff({required this.rules, required this.manual, required this.auto, required this.expiresSuffix, required this.nameRequired, required this.pickStudent, required this.awarded, required this.pickCircle, required this.awardedN, required this.deleteTitle, required this.deleteBody, required this.newTitle, required this.badge, required this.icon, required this.name, required this.description, required this.rule, required this.threshold, required this.juzNo, required this.percent, required this.count, required this.grade, required this.duration, required this.active, required this.giveManually, required this.toStudent, required this.toCircle, required this.holdersN, required this.noHolders, required this.revoked, required this.revoke, required this.reevaluate, required this.reevaluated, required this.intro, required this.empty, required this.expiresAfter, required this.inactive});
  final Map<String, String> rules;
  final String manual;
  final String auto;
  final String expiresSuffix;
  final String nameRequired;
  final String pickStudent;
  final String awarded;
  final String pickCircle;
  final String awardedN;
  final String deleteTitle;
  final String deleteBody;
  final String newTitle;
  final String badge;
  final String icon;
  final String name;
  final String description;
  final String rule;
  final String threshold;
  final String juzNo;
  final String percent;
  final String count;
  final String grade;
  final String duration;
  final String active;
  final String giveManually;
  final String toStudent;
  final String toCircle;
  final String holdersN;
  final String noHolders;
  final String revoked;
  final String revoke;
  final String reevaluate;
  final String reevaluated;
  final String intro;
  final String empty;
  final String expiresAfter;
  final String inactive;
}

/// Calendar list and event detail.
class SCal {
  const SCal({required this.settingLoadFailed, required this.reminderTitle, required this.reminderHours, required this.reminderHelp, required this.reminderSaved, required this.saveFailed, required this.title, required this.reminderTip, required this.types, required this.add, required this.legend, required this.thisMonth, required this.nothing, required this.youRegistered, required this.dayOff, required this.serdScheduled, required this.serd, required this.linkCopied, required this.registeredDone, required this.resultOf, required this.rank, required this.note, required this.resultSaved, required this.details, required this.registration, required this.participants, required this.registerStudent, required this.noParticipants, required this.waitlistCount, required this.circle, required this.stage, required this.workDay, required this.taken, required this.waiting, required this.deadline, required this.needsConsent, required this.unregister, required this.unregistered, required this.staffRegistered, required this.register, required this.waitlisted, required this.joinWaitlist, required this.leftWaitlist, required this.leaveWaitlist, required this.registeredChip, required this.waitingChip, required this.consent, required this.copyLink, required this.result, required this.rankN, required this.copyConsent, required this.consentRecorded, required this.phoneConsent, required this.declineRecorded, required this.decline, required this.resultBtn, required this.searchStudent, required this.onDay, required this.takenShort, required this.offDay, required this.unregisterQ, required this.withReg, required this.notWorking, required this.workingDay, required this.notWorkingDay, required this.pickTypeTitle, required this.deleteBody, required this.addTitle, required this.type, required this.titleField, required this.description, required this.fromV, required this.toV, required this.timeOpt, required this.place, required this.whoSees, required this.audienceLabel, required this.oneCircle, required this.allCircles, required this.oneStage, required this.allStages, required this.workingSection, required this.overrideType, required this.typeMakes, required this.offDaysHint, required this.registrationSection, required this.seats, required this.closesAt, required this.removeDeadline, required this.open, required this.saved, required this.newType, required this.editType, required this.name, required this.hasRegistration, required this.needsGuardian, required this.active, required this.typeNameRequired, required this.typesTitle, required this.typesHint, required this.working, required this.guardianConsent, required this.inactive});
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
  final String withReg;
  final String notWorking;
  final String workingDay;
  final String notWorkingDay;
  final String pickTypeTitle;
  final String deleteBody;
  final String addTitle;
  final String type;
  final String titleField;
  final String description;
  final String fromV;
  final String toV;
  final String timeOpt;
  final String place;
  final String whoSees;
  final String audienceLabel;
  final String oneCircle;
  final String allCircles;
  final String oneStage;
  final String allStages;
  final String workingSection;
  final String overrideType;
  final String typeMakes;
  final String offDaysHint;
  final String registrationSection;
  final String seats;
  final String closesAt;
  final String removeDeadline;
  final String open;
  final String saved;
  final String newType;
  final String editType;
  final String name;
  final String hasRegistration;
  final String needsGuardian;
  final String active;
  final String typeNameRequired;
  final String typesTitle;
  final String typesHint;
  final String working;
  final String guardianConsent;
  final String inactive;
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

/// The center admin's feature switches (center_features, 0088).
class SCfeat {
  const SCfeat({required this.names, required this.tab, required this.title, required this.hint, required this.notInPlan, required this.save, required this.saved, required this.off});
  final Map<String, String> names;
  final String tab;
  final String title;
  final String hint;
  final String notInPlan;
  final String save;
  final String saved;
  final String off;
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

/// The staff dashboard (admin and teacher home).
class SDash {
  const SDash({required this.takeAttendance, required this.addStudent, required this.serdSession, required this.newAnnouncement, required this.calendar, required this.title, required this.greeting, required this.yourCirclesToday, required this.noCircle, required this.notWorkingDay, required this.studentsN, required this.recitedN, required this.presentN, required this.absentN, required this.students, required this.teachers, required this.circles, required this.todayAttendance, required this.shortcuts, required this.centerAdmin, required this.waitSerd, required this.waitMarket, required this.waitGatherings, required this.waitExternal, required this.needsYou, required this.nothingWaiting, required this.inactiveN, required this.thisWeek, required this.weekRecitations, required this.weekReciting, required this.weekPoints, required this.weekAttendance, required this.upcomingEvents, required this.notYet, required this.registered, required this.dropoutRisk, required this.noRisk, required this.teacherPerf, required this.recitationsWord, required this.riskTags, required this.idleDays, required this.perfLine});
  final String takeAttendance;
  final String addStudent;
  final String serdSession;
  final String newAnnouncement;
  final String calendar;
  final String title;
  final String greeting;
  final String yourCirclesToday;
  final String noCircle;
  final String notWorkingDay;
  final String studentsN;
  final String recitedN;
  final String presentN;
  final String absentN;
  final String students;
  final String teachers;
  final String circles;
  final String todayAttendance;
  final String shortcuts;
  final String centerAdmin;
  final String waitSerd;
  final String waitMarket;
  final String waitGatherings;
  final String waitExternal;
  final String needsYou;
  final String nothingWaiting;
  final String inactiveN;
  final String thisWeek;
  final String weekRecitations;
  final String weekReciting;
  final String weekPoints;
  final String weekAttendance;
  final String upcomingEvents;
  final String notYet;
  final String registered;
  final String dropoutRisk;
  final String noRisk;
  final String teacherPerf;
  final String recitationsWord;
  final Map<String, String> riskTags;
  final String idleDays;
  final String perfLine;
}

/// Student fees (optional feature): the admin's list and record-a-payment, the family's account.
class SFees {
  const SFees({required this.title, required this.collectedMonth, required this.outstanding, required this.owingN, required this.filter, required this.search, required this.none, required this.exempt, required this.discountV, required this.noPlan, required this.owes, required this.credit, required this.settled, required this.dueSoFar, required this.paidTotal, required this.upcoming, required this.plan, required this.periods, required this.recordTitle, required this.amount, required this.amountInvalid, required this.method, required this.methods, required this.paidOn, required this.note, required this.record, required this.recorded, required this.outbox, required this.pendingUpload, required this.charges, required this.payments, required this.status, required this.notYetDue, required this.waive, required this.cancelCharge, required this.reopen, required this.cancelChargeConfirm, required this.receiptNo, required this.receiptTitle, required this.voidPayment, required this.voidReason, required this.voidConfirm, required this.voided, required this.noCharges, required this.noPayments, required this.balanceAfter, required this.byLabel, required this.share, required this.receiptText, required this.manageOnWeb, required this.adminOnly, required this.openAccount});
  final String title;
  final String collectedMonth;
  final String outstanding;
  final String owingN;
  final Map<String, String> filter;
  final String search;
  final String none;
  final String exempt;
  final String discountV;
  final String noPlan;
  final String owes;
  final String credit;
  final String settled;
  final String dueSoFar;
  final String paidTotal;
  final String upcoming;
  final String plan;
  final Map<String, String> periods;
  final String recordTitle;
  final String amount;
  final String amountInvalid;
  final String method;
  final Map<String, String> methods;
  final String paidOn;
  final String note;
  final String record;
  final String recorded;
  final String outbox;
  final String pendingUpload;
  final String charges;
  final String payments;
  final Map<String, String> status;
  final String notYetDue;
  final String waive;
  final String cancelCharge;
  final String reopen;
  final String cancelChargeConfirm;
  final String receiptNo;
  final String receiptTitle;
  final String voidPayment;
  final String voidReason;
  final String voidConfirm;
  final String voided;
  final String noCharges;
  final String noPayments;
  final String balanceAfter;
  final String byLabel;
  final String share;
  final String receiptText;
  final String manageOnWeb;
  final String adminOnly;
  final String openAccount;
}

/// The garden design (headers, hub, navigation).
class SGarden {
  const SGarden({required this.online, required this.offline, required this.noInternet, required this.syncCenter, required this.offlineWaiting, required this.syncing, required this.waitingN, required this.failedN, required this.tabHome, required this.tabStudents, required this.tabSerd, required this.tabChat, required this.tabMore, required this.seeAll, required this.moreTitle, required this.checkedInShort, required this.checkInShort, required this.studentsN, required this.statCircles, required this.statStudents, required this.statRecited, required this.statPresent, required this.quickTitle, required this.account, required this.notificationPrefs, required this.statJuz, required this.statPoints, required this.statStreak, required this.explore, required this.statAttendance, required this.itemsN});
  final String online;
  final String offline;
  final String noInternet;
  final String syncCenter;
  final String offlineWaiting;
  final String syncing;
  final String waitingN;
  final String failedN;
  final String tabHome;
  final String tabStudents;
  final String tabSerd;
  final String tabChat;
  final String tabMore;
  final String seeAll;
  final String moreTitle;
  final String checkedInShort;
  final String checkInShort;
  final String studentsN;
  final String statCircles;
  final String statStudents;
  final String statRecited;
  final String statPresent;
  final String quickTitle;
  final String account;
  final String notificationPrefs;
  final String statJuz;
  final String statPoints;
  final String statStreak;
  final String explore;
  final String statAttendance;
  final String itemsN;
}

/// Gatherings and external recitations (staff).
class SGather {
  const SGather({required this.noCircle, required this.okLinked, required this.skippedSuffix, required this.actionFailed, required this.extNew, required this.studentName, required this.type, required this.surah, required this.fromAyah, required this.toAyah, required this.grade, required this.extUpload, required this.extUploaded, required this.extLinked, required this.rejectTitle, required this.reasonOpt, required this.reject, required this.rejected, required this.extNewShort, required this.noRequests, required this.linked, required this.rejectedChip, required this.pending, required this.linkedTo, required this.reasonV, required this.pickStudent, required this.deletedReq, required this.linkedAttended, required this.addName, required this.name, required this.add, required this.nameAdded, required this.activity, required this.metaLine, required this.namesN, required this.nameDeleted, required this.linkedLine, required this.skipped, required this.skip, required this.nameSkipped, required this.unlink, required this.uploadNew, required this.activityName, required this.activityType, required this.none, required this.placeOpt, required this.attendees, required this.uploadBtn, required this.uploadedN, required this.uploadFailed, required this.upload, required this.empty, required this.countsLine, required this.reviewed, required this.pendingN, required this.waitingAdmin, required this.pickStudentTitle, required this.searchPh});
  final String noCircle;
  final String okLinked;
  final String skippedSuffix;
  final String actionFailed;
  final String extNew;
  final String studentName;
  final String type;
  final String surah;
  final String fromAyah;
  final String toAyah;
  final String grade;
  final String extUpload;
  final String extUploaded;
  final String extLinked;
  final String rejectTitle;
  final String reasonOpt;
  final String reject;
  final String rejected;
  final String extNewShort;
  final String noRequests;
  final String linked;
  final String rejectedChip;
  final String pending;
  final String linkedTo;
  final String reasonV;
  final String pickStudent;
  final String deletedReq;
  final String linkedAttended;
  final String addName;
  final String name;
  final String add;
  final String nameAdded;
  final String activity;
  final String metaLine;
  final String namesN;
  final String nameDeleted;
  final String linkedLine;
  final String skipped;
  final String skip;
  final String nameSkipped;
  final String unlink;
  final String uploadNew;
  final String activityName;
  final String activityType;
  final String none;
  final String placeOpt;
  final String attendees;
  final String uploadBtn;
  final String uploadedN;
  final String uploadFailed;
  final String upload;
  final String empty;
  final String countsLine;
  final String reviewed;
  final String pendingN;
  final String waitingAdmin;
  final String pickStudentTitle;
  final String searchPh;
}

/// Student notes, search, suggested review, challenges, audit (staff).
class SIns {
  const SIns({required this.guardianVisibleSuffix, required this.overdueSuffix, required this.noCircle, required this.auditActions, required this.auditTables, required this.newNote, required this.notePh, required this.guardianVisible, required this.noteFailed, required this.notesTitle, required this.noNotes, required this.searchFailed, required this.searchPh, required this.noResults, required this.students, required this.staff, required this.admin, required this.teacher, required this.circles, required this.reviewsTitle, required this.noReviews, required this.reviewsHint, required this.challengeTitleRequired, required this.newChallenge, required this.editChallenge, required this.title, required this.description, required this.metric, required this.deleteChallenge, required this.sure, required this.challenge, required this.noCircles, required this.boardLine, required this.noChallenges, required this.noAudit, required this.auditHint});
  final String guardianVisibleSuffix;
  final String overdueSuffix;
  final String noCircle;
  final Map<String, String> auditActions;
  final Map<String, String> auditTables;
  final String newNote;
  final String notePh;
  final String guardianVisible;
  final String noteFailed;
  final String notesTitle;
  final String noNotes;
  final String searchFailed;
  final String searchPh;
  final String noResults;
  final String students;
  final String staff;
  final String admin;
  final String teacher;
  final String circles;
  final String reviewsTitle;
  final String noReviews;
  final String reviewsHint;
  final String challengeTitleRequired;
  final String newChallenge;
  final String editChallenge;
  final String title;
  final String description;
  final String metric;
  final String deleteChallenge;
  final String sure;
  final String challenge;
  final String noCircles;
  final String boardLine;
  final String noChallenges;
  final String noAudit;
  final String auditHint;
}

/// The live recite screen (/my/recite).
class SLive {
  const SLive({required this.title, required this.hint, required this.student, required this.surah, required this.type, required this.from, required this.to, required this.start, required this.unsupported, required this.micDenied, required this.network, required this.listening, required this.paused, required this.progress, required this.mistakesN, required this.stopMissing, required this.stopWrong, required this.correctIs, required this.heard, required this.resume, required this.forgot, required this.finish, required this.result, required this.score, required this.mistakeList, required this.resultNote, required this.note, required this.send, required this.sending, required this.sent, required this.again, required this.appAudio, required this.recording, required this.withAudio, required this.retry, required this.notSent, required this.nothingHeard, required this.mine, required this.error, required this.fab, required this.liveBadge, required this.loading, required this.appNoAudio, required this.appUnsupported});
  final String title;
  final String hint;
  final String student;
  final String surah;
  final String type;
  final String from;
  final String to;
  final String start;
  final String unsupported;
  final String micDenied;
  final String network;
  final String listening;
  final String paused;
  final String progress;
  final String mistakesN;
  final String stopMissing;
  final String stopWrong;
  final String correctIs;
  final String heard;
  final String resume;
  final String forgot;
  final String finish;
  final String result;
  final String score;
  final String mistakeList;
  final String resultNote;
  final String note;
  final String send;
  final String sending;
  final String sent;
  final String again;
  final String appAudio;
  final String recording;
  final String withAudio;
  final String retry;
  final String notSent;
  final String nothingHeard;
  final String mine;
  final String error;
  final String fab;
  final String liveBadge;
  final String loading;
  final String appNoAudio;
  final String appUnsupported;
}

/// Members, teachers and permissions (admin).
class SMem {
  const SMem({required this.modules, required this.status, required this.password8, required this.passwordChanged, required this.accountSaved, required this.removeTitle, required this.removeBody, required this.editTitle, required this.selfNote, required this.role, required this.statusLabel, required this.modulesTitle, required this.viewOnly, required this.viewOnlyHint, required this.changePassword, required this.newPassword, required this.teacherCreated, required this.newTeacher, required this.teacherHint, required this.required, required this.loginId, required this.min8, required this.createAccount, required this.inviteCreated, required this.inviteError, required this.inviteTitle, required this.email, required this.inviteBtn, required this.pendingInvites, required this.contactTitle, required this.contactHint});
  final Map<String, String> modules;
  final Map<String, String> status;
  final String password8;
  final String passwordChanged;
  final String accountSaved;
  final String removeTitle;
  final String removeBody;
  final String editTitle;
  final String selfNote;
  final String role;
  final String statusLabel;
  final String modulesTitle;
  final String viewOnly;
  final String viewOnlyHint;
  final String changePassword;
  final String newPassword;
  final String teacherCreated;
  final String newTeacher;
  final String teacherHint;
  final String required;
  final String loginId;
  final String min8;
  final String createAccount;
  final String inviteCreated;
  final String inviteError;
  final String inviteTitle;
  final String email;
  final String inviteBtn;
  final String pendingInvites;
  final String contactTitle;
  final String contactHint;
}

/// Recurring mistakes (recitation_mistake_stats).
class SMistakes {
  const SMistakes({required this.title, required this.hint, required this.summary, required this.bySurah, required this.byAyah, required this.byWord, required this.times, required this.none, required this.ayah});
  final String title;
  final String hint;
  final String summary;
  final String bySurah;
  final String byAyah;
  final String byWord;
  final String times;
  final String none;
  final String ayah;
}

/// The points market (staff).
class SMkt {
  const SMkt({required this.rateTitle, required this.perPoints, required this.equals, required this.currency, required this.rateHint, required this.rateInvalid, required this.rateSaved, required this.cancelOrder, required this.cancelOrderBody, required this.no, required this.yes, required this.orderCancelled, required this.newItem, required this.adminOnly, required this.items, required this.ordersN, required this.orders, required this.balances, required this.noOrders, required this.delivered, required this.walletLine, required this.disabled, required this.rateLine, required this.rateSub, required this.noItems, required this.unlimited, required this.stockN, required this.inactiveSuffix, required this.nameRequired, required this.noUpload, required this.uploadFailed, required this.tooBig3, required this.deleteItem, required this.deleteItemBody, required this.editItem, required this.name, required this.description, required this.uploadDevice, required this.removeImage, required this.imageLink, required this.priceIn, required this.stock, required this.active});
  final String rateTitle;
  final String perPoints;
  final String equals;
  final String currency;
  final String rateHint;
  final String rateInvalid;
  final String rateSaved;
  final String cancelOrder;
  final String cancelOrderBody;
  final String no;
  final String yes;
  final String orderCancelled;
  final String newItem;
  final String adminOnly;
  final String items;
  final String ordersN;
  final String orders;
  final String balances;
  final String noOrders;
  final String delivered;
  final String walletLine;
  final String disabled;
  final String rateLine;
  final String rateSub;
  final String noItems;
  final String unlimited;
  final String stockN;
  final String inactiveSuffix;
  final String nameRequired;
  final String noUpload;
  final String uploadFailed;
  final String tooBig3;
  final String deleteItem;
  final String deleteItemBody;
  final String editItem;
  final String name;
  final String description;
  final String uploadDevice;
  final String removeImage;
  final String imageLink;
  final String priceIn;
  final String stock;
  final String active;
}

/// The staff drawer (items keyed by route).
class SNav {
  const SNav({required this.items, required this.sections, required this.switchCenter, required this.menu});
  final Map<String, String> items;
  final Map<String, String> sections;
  final String switchCenter;
  final String menu;
}

/// Notifications.
class SNotif {
  const SNotif({required this.now, required this.minutesAgo, required this.hoursAgo, required this.today, required this.yesterday, required this.title, required this.markAll, required this.prefs, required this.none, required this.notSaved, required this.noPush, required this.noPermission, required this.paused, required this.quiet, required this.events, required this.types, required this.instantTitle, required this.instantBody, required this.instantBattery, required this.instantBatteryHint, required this.instantAutostart, required this.instantAutostartHint, required this.instantOk});
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
  final Map<String, String> events;
  final String types;
  final String instantTitle;
  final String instantBody;
  final String instantBattery;
  final String instantBatteryHint;
  final String instantAutostart;
  final String instantAutostartHint;
  final String instantOk;
}

/// Circles, stages, grades, attendance, activities and the public page (admin).
class SOrg {
  const SOrg({required this.circleStatus, required this.attStatus, required this.outboxAttendance, required this.saveErrorRetry, required this.deleteCircle, required this.deleteCircleBody, required this.editCircle, required this.addCircle, required this.circleName, required this.stage, required this.noStage, required this.teacher, required this.noTeacher, required this.capacity, required this.assistants, required this.assistantsHint, required this.noOtherTeachers, required this.status, required this.addCircleBtn, required this.noCircles, required this.noCirclesHint, required this.capacityN, required this.gradesLoadFailed, required this.keyRule, required this.gradesSaved, required this.gradesTitle, required this.gradesHint, required this.name, required this.points, required this.addGrade, required this.keyField, required this.nameField, required this.saveGrades, required this.gradesAdminOnly, required this.stageTaken, required this.deleteStage, required this.deleteStageBody, required this.editStage, required this.addStage, required this.stageName, required this.stageNamePh, required this.stageCode, required this.stageOrder, required this.addStageBtn, required this.noStages, required this.noStagesHint, required this.orderN, required this.circlesLoadFailed, required this.studentsLoadFailed, required this.attSaved, required this.saveAtt, required this.circle, required this.dateV, required this.pickCircle, required this.pickCircleHint, required this.noStudents, required this.allPresent, required this.deleteActivity, required this.deleteActivityBody, required this.editActivity, required this.newActivity, required this.title, required this.description, required this.whenOpt, required this.addActivity, required this.noActivities, required this.noActivitiesHint, required this.noTime, required this.siteIntro, required this.siteEnable, required this.heroTitle, required this.heroBody, required this.contactEmail, required this.siteAdminOnly});
  final Map<String, String> circleStatus;
  final Map<String, String> attStatus;
  final String outboxAttendance;
  final String saveErrorRetry;
  final String deleteCircle;
  final String deleteCircleBody;
  final String editCircle;
  final String addCircle;
  final String circleName;
  final String stage;
  final String noStage;
  final String teacher;
  final String noTeacher;
  final String capacity;
  final String assistants;
  final String assistantsHint;
  final String noOtherTeachers;
  final String status;
  final String addCircleBtn;
  final String noCircles;
  final String noCirclesHint;
  final String capacityN;
  final String gradesLoadFailed;
  final String keyRule;
  final String gradesSaved;
  final String gradesTitle;
  final String gradesHint;
  final String name;
  final String points;
  final String addGrade;
  final String keyField;
  final String nameField;
  final String saveGrades;
  final String gradesAdminOnly;
  final String stageTaken;
  final String deleteStage;
  final String deleteStageBody;
  final String editStage;
  final String addStage;
  final String stageName;
  final String stageNamePh;
  final String stageCode;
  final String stageOrder;
  final String addStageBtn;
  final String noStages;
  final String noStagesHint;
  final String orderN;
  final String circlesLoadFailed;
  final String studentsLoadFailed;
  final String attSaved;
  final String saveAtt;
  final String circle;
  final String dateV;
  final String pickCircle;
  final String pickCircleHint;
  final String noStudents;
  final String allPresent;
  final String deleteActivity;
  final String deleteActivityBody;
  final String editActivity;
  final String newActivity;
  final String title;
  final String description;
  final String whenOpt;
  final String addActivity;
  final String noActivities;
  final String noActivitiesHint;
  final String noTime;
  final String siteIntro;
  final String siteEnable;
  final String heroTitle;
  final String heroBody;
  final String contactEmail;
  final String siteAdminOnly;
}

/// Subscription / plan-capacity strips for staff.
class SPlan {
  const SPlan({required this.graceTrial, required this.gracePaid, required this.soonTrial, required this.soonPaid, required this.days, required this.students, required this.studentsFull, required this.studentsLeft, required this.teachersFull, required this.oneTeacherLeft});
  final String graceTrial;
  final String gracePaid;
  final String soonTrial;
  final String soonPaid;
  final Map<String, String> days;
  final Map<String, String> students;
  final String studentsFull;
  final String studentsLeft;
  final String teachersFull;
  final String oneTeacherLeft;
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

/// Teacher / circle profiles and the memorization goal.
class SProf {
  const SProf({required this.thisMonth, required this.lastMonth, required this.last90, required this.vsPrev, required this.same, required this.newV, required this.recitations, required this.reciting, required this.points, required this.attendance, required this.serdHeard, required this.serdApproved, required this.daysPresent, required this.teacherDays, required this.students, required this.circles, required this.assistant, required this.teacher, required this.assistants, required this.recent, required this.teacherAtt, required this.nothing, required this.lastRec, required this.never, required this.today, required this.daysAgo, required this.profile, required this.myProfile, required this.message, required this.call, required this.notAllowed, required this.goalTitle, required this.memorized, required this.percentQuran, required this.pace, required this.paceV, required this.goalPace, required this.goalPaceV, required this.sinceStart, required this.forecast, required this.forecastGoal, required this.noPace, required this.noGoal, required this.goalStatus, required this.setGoal, required this.editGoal, required this.pagesPerDay, required this.targetPages, required this.note, required this.save, required this.clearGoal, required this.goalSaved, required this.invalidPages, required this.outboxGoal, required this.whatsapp});
  final String thisMonth;
  final String lastMonth;
  final String last90;
  final String vsPrev;
  final String same;
  final String newV;
  final String recitations;
  final String reciting;
  final String points;
  final String attendance;
  final String serdHeard;
  final String serdApproved;
  final String daysPresent;
  final String teacherDays;
  final String students;
  final String circles;
  final String assistant;
  final String teacher;
  final String assistants;
  final String recent;
  final String teacherAtt;
  final String nothing;
  final String lastRec;
  final String never;
  final String today;
  final String daysAgo;
  final String profile;
  final String myProfile;
  final String message;
  final String call;
  final String notAllowed;
  final String goalTitle;
  final String memorized;
  final String percentQuran;
  final String pace;
  final String paceV;
  final String goalPace;
  final String goalPaceV;
  final String sinceStart;
  final String forecast;
  final String forecastGoal;
  final String noPace;
  final String noGoal;
  final Map<String, String> goalStatus;
  final String setGoal;
  final String editGoal;
  final String pagesPerDay;
  final String targetPages;
  final String note;
  final String save;
  final String clearGoal;
  final String goalSaved;
  final String invalidPages;
  final String outboxGoal;
  final String whatsapp;
}

/// The Quran screens (the text itself stays Arabic).
class SQuran {
  const SQuran({required this.title, required this.surahs, required this.search, required this.continueReading, required this.position, required this.ayahs, required this.noBookmarks, required this.noBookmarksHint, required this.playFailed, required this.ayahOf, required this.playFromHere, required this.unmark, required this.copyAyah, required this.copied, required this.smaller, required this.bigger, required this.loadFailed, required this.repeat, required this.noRepeat, required this.prevAyah, required this.nextAyah, required this.credit, required this.bookmarks, required this.mark, required this.repeatN, required this.play, required this.pause, required this.sync, required this.syncNone, required this.syncAyah, required this.syncWord, required this.reciter, required this.noTimings, required this.noSurahAudio, required this.fontSize, required this.testMode, required this.testHint, required this.revealPage, required this.hidePage, required this.prevPage, required this.nextPage, required this.readingSettings});
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
  final String play;
  final String pause;
  final String sync;
  final String syncNone;
  final String syncAyah;
  final String syncWord;
  final String reciter;
  final String noTimings;
  final String noSurahAudio;
  final String fontSize;
  final String testMode;
  final String testHint;
  final String revealPage;
  final String hidePage;
  final String prevPage;
  final String nextPage;
  final String readingSettings;
}

/// Recording recitations (sheet, lesson mode).
class SRec {
  const SRec({required this.pickGrade, required this.pickSurah, required this.enterRange, required this.rangeOrder, required this.tooFar, required this.partial, required this.newTitle, required this.editTitle, required this.prefilled, required this.dateToday, required this.dateV, required this.type, required this.addSurah, required this.grade, required this.notes, required this.saveBtn, required this.saveEdit, required this.fromAyah, required this.toAyah, required this.maxV, required this.searchSurah, required this.ayahsN, required this.absenceFailed, required this.lessonTitle, required this.studentXofY, required this.plan, required this.recordBtn, required this.absent, required this.later, required this.nobody, required this.done, required this.summary, required this.anotherRound, required this.finish, required this.circle, required this.doneToday, required this.outboxAttendance, required this.outboxRecitation, required this.today, required this.dayMonth, required this.addNote, required this.saveWithPoints, required this.change, required this.wholeSurah});
  final String pickGrade;
  final String pickSurah;
  final String enterRange;
  final String rangeOrder;
  final String tooFar;
  final String partial;
  final String newTitle;
  final String editTitle;
  final String prefilled;
  final String dateToday;
  final String dateV;
  final String type;
  final String addSurah;
  final String grade;
  final String notes;
  final String saveBtn;
  final String saveEdit;
  final String fromAyah;
  final String toAyah;
  final String maxV;
  final String searchSurah;
  final String ayahsN;
  final String absenceFailed;
  final String lessonTitle;
  final String studentXofY;
  final String plan;
  final String recordBtn;
  final String absent;
  final String later;
  final String nobody;
  final String done;
  final String summary;
  final String anotherRound;
  final String finish;
  final String circle;
  final String doneToday;
  final String outboxAttendance;
  final String outboxRecitation;
  final String today;
  final String dayMonth;
  final String addNote;
  final String saveWithPoints;
  final String change;
  final String wholeSurah;
}

/// Reciting to the system, the teacher's test in the mushaf, passage repeat, the recorded recitations.
class SRecite {
  const SRecite({required this.rangeTitle, required this.from, required this.to, required this.times, required this.rangeHint, required this.loop, required this.rangeOff, required this.recite, required this.reciteTitle, required this.reciteHint, required this.student, required this.type, required this.start, required this.stop, required this.recording, required this.micDenied, required this.micMissing, required this.tooLong, required this.uploading, required this.checking, required this.uploadFailed, required this.result, required this.score, required this.correct, required this.missing, required this.wrong, required this.extra, required this.legend, required this.unavailable, required this.autoNote, required this.note, required this.send, required this.sent, required this.again, required this.cancel, required this.testStudent, required this.testTitle, required this.testHint, required this.mistakes, required this.grade, required this.save, required this.saved, required this.chooseStudent, required this.noStudents, required this.badRange, required this.error, required this.myTitle, required this.inboxTitle, required this.inboxHint, required this.pending, required this.reviewed, required this.none, required this.approve, required this.reject, required this.rejectNote, required this.teacherNote, required this.studentNote, required this.autoScore, required this.noAuto, required this.heardAs, required this.missingWords, required this.openMushaf, required this.teacherTest, required this.markedMistakes, required this.statusDraft, required this.statusSubmitted, required this.statusApproved, required this.statusRejected, required this.reviewedBy, required this.ayahRange, required this.waitingN, required this.recheck, required this.testNote, required this.micDeniedApp, required this.play, required this.apply});
  final String rangeTitle;
  final String from;
  final String to;
  final String times;
  final String rangeHint;
  final String loop;
  final String rangeOff;
  final String recite;
  final String reciteTitle;
  final String reciteHint;
  final String student;
  final String type;
  final String start;
  final String stop;
  final String recording;
  final String micDenied;
  final String micMissing;
  final String tooLong;
  final String uploading;
  final String checking;
  final String uploadFailed;
  final String result;
  final String score;
  final String correct;
  final String missing;
  final String wrong;
  final String extra;
  final String legend;
  final String unavailable;
  final String autoNote;
  final String note;
  final String send;
  final String sent;
  final String again;
  final String cancel;
  final String testStudent;
  final String testTitle;
  final String testHint;
  final String mistakes;
  final String grade;
  final String save;
  final String saved;
  final String chooseStudent;
  final String noStudents;
  final String badRange;
  final String error;
  final String myTitle;
  final String inboxTitle;
  final String inboxHint;
  final String pending;
  final String reviewed;
  final String none;
  final String approve;
  final String reject;
  final String rejectNote;
  final String teacherNote;
  final String studentNote;
  final String autoScore;
  final String noAuto;
  final String heardAs;
  final String missingWords;
  final String openMushaf;
  final String teacherTest;
  final String markedMistakes;
  final String statusDraft;
  final String statusSubmitted;
  final String statusApproved;
  final String statusRejected;
  final String reviewedBy;
  final String ayahRange;
  final String waitingN;
  final String recheck;
  final String testNote;
  final String micDeniedApp;
  final String play;
  final String apply;
}

/// Reports (the student report is also the portal's).
class SRep {
  const SRep({required this.from, required this.to, required this.title, required this.loadFailed, required this.activeStudents, required this.newStudents, required this.recitations, required this.recitingStudents, required this.points, required this.attendanceRate, required this.serdApproved, required this.certsIssued, required this.copied, required this.copySummary, required this.types, required this.attendance, required this.circles, required this.teachers, required this.top, required this.studentTitle, required this.student, required this.noStudent, required this.teacher, required this.periodRecitations, required this.periodPoints, required this.totalPoints, required this.progress, required this.savedParts, required this.serd, required this.badges, required this.certificates, required this.log, required this.none, required this.circleLine, required this.teacherLine, required this.sumTitle, required this.sumActive, required this.sumPoints, required this.sumAttendance, required this.sumSerd, required this.sumRecitations, required this.sumCircle});
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
  final String sumTitle;
  final String sumActive;
  final String sumPoints;
  final String sumAttendance;
  final String sumSerd;
  final String sumRecitations;
  final String sumCircle;
}

/// The daily review portion (suggested from what is memorized, approved by the teacher).
class SRplan {
  const SRplan({required this.title, required this.hint, required this.range, required this.ayahRef, required this.pagesN, required this.approve, required this.approveAll, required this.approvedN, required this.recite, required this.skip, required this.status, required this.none, required this.cycleStart, required this.today, required this.reviewPages, required this.outbox});
  final String title;
  final String hint;
  final String range;
  final String ayahRef;
  final String pagesN;
  final String approve;
  final String approveAll;
  final String approvedN;
  final String recite;
  final String skip;
  final Map<String, String> status;
  final String none;
  final String cycleStart;
  final String today;
  final String reviewPages;
  final String outbox;
}

/// Quran serd (staff): list, entry, schedule, settings, report.
class SSerd {
  const SSerd({required this.overdueSuffix, required this.inactiveSuffix, required this.passSuffix, required this.wholeJuz, required this.noCircle, required this.linkStudent, required this.approved, required this.rejectTitle, required this.rejectReason, required this.reject, required this.rejected, required this.deleteTitle, required this.deleteBody, required this.deleted, required this.approve, required this.reapprove, required this.certIssued, required this.issueCert, required this.schedule, required this.report, required this.settings, required this.record, required this.all, required this.pending, required this.scheduled, required this.approvedChip, required this.rejectedChip, required this.empty, required this.requestedN, required this.assigned, required this.openAny, required this.recordShort, required this.mine, required this.mineEmpty, required this.saved, required this.wholeAlways, required this.newErrorType, required this.editErrorType, required this.name, required this.perErrors, required this.deductPct, required this.active, required this.fillAll, required this.stagePortions, required this.stagePass, required this.settingsTitle, required this.settingsHint, required this.general, required this.passPct, required this.wholePoints, required this.defaultPortions, required this.wholeNumbers, required this.saveGeneral, required this.errorTypes, required this.perRule, required this.byStage, required this.byStageHint, required this.usesGeneral, required this.pickOrType, required this.pickPart, required this.sentScore, required this.saveFailedNet, required this.newTitle, required this.scheduledTitle, required this.pickStudent, required this.typeName, required this.clearPick, required this.dateLine, required this.parts, required this.errors, required this.perRule2, required this.expected, required this.notesOpt, required this.submit, required this.noResults, required this.reportTitle, required this.totalSessions, required this.waiting, required this.avgScore, required this.pointsGiven, required this.approvedParts, required this.juzLine, required this.topErrors, required this.examiners, required this.partsLine, required this.examiner, required this.circleTeacher, required this.assignedTo, required this.openToAny, required this.noStudent, required this.scoreLabel, required this.resultLine, required this.rejectReasonV, required this.whole, required this.pickJuz, required this.juzLine2, required this.addJuz, required this.passed, required this.repeat, required this.pickBoth, required this.scheduledOk, required this.scheduleHint, required this.student, required this.when, required this.partsWanted, required this.assign, required this.scheduleBtn, required this.outboxLabel, required this.certDone, required this.issueAnother});
  final String overdueSuffix;
  final String inactiveSuffix;
  final String passSuffix;
  final String wholeJuz;
  final String noCircle;
  final String linkStudent;
  final String approved;
  final String rejectTitle;
  final String rejectReason;
  final String reject;
  final String rejected;
  final String deleteTitle;
  final String deleteBody;
  final String deleted;
  final String approve;
  final String reapprove;
  final String certIssued;
  final String issueCert;
  final String schedule;
  final String report;
  final String settings;
  final String record;
  final String all;
  final String pending;
  final String scheduled;
  final String approvedChip;
  final String rejectedChip;
  final String empty;
  final String requestedN;
  final String assigned;
  final String openAny;
  final String recordShort;
  final String mine;
  final String mineEmpty;
  final String saved;
  final String wholeAlways;
  final String newErrorType;
  final String editErrorType;
  final String name;
  final String perErrors;
  final String deductPct;
  final String active;
  final String fillAll;
  final String stagePortions;
  final String stagePass;
  final String settingsTitle;
  final String settingsHint;
  final String general;
  final String passPct;
  final String wholePoints;
  final String defaultPortions;
  final String wholeNumbers;
  final String saveGeneral;
  final String errorTypes;
  final String perRule;
  final String byStage;
  final String byStageHint;
  final String usesGeneral;
  final String pickOrType;
  final String pickPart;
  final String sentScore;
  final String saveFailedNet;
  final String newTitle;
  final String scheduledTitle;
  final String pickStudent;
  final String typeName;
  final String clearPick;
  final String dateLine;
  final String parts;
  final String errors;
  final String perRule2;
  final String expected;
  final String notesOpt;
  final String submit;
  final String noResults;
  final String reportTitle;
  final String totalSessions;
  final String waiting;
  final String avgScore;
  final String pointsGiven;
  final String approvedParts;
  final String juzLine;
  final String topErrors;
  final String examiners;
  final String partsLine;
  final String examiner;
  final String circleTeacher;
  final String assignedTo;
  final String openToAny;
  final String noStudent;
  final String scoreLabel;
  final String resultLine;
  final String rejectReasonV;
  final String whole;
  final String pickJuz;
  final String juzLine2;
  final String addJuz;
  final String passed;
  final String repeat;
  final String pickBoth;
  final String scheduledOk;
  final String scheduleHint;
  final String student;
  final String when;
  final String partsWanted;
  final String assign;
  final String scheduleBtn;
  final String outboxLabel;
  final String certDone;
  final String issueAnother;
}

/// Center settings (admin).
class SSet {
  const SSet({required this.loadSome, required this.saved, required this.fromGallery, required this.takePhoto, required this.tooBig1, required this.logoUploaded, required this.logoAdminOnly, required this.logoFailed, required this.logoHttps, required this.backdateRange, required this.intro, required this.identity, required this.name, required this.uploading, required this.uploadLogo, required this.remove, required this.logoLink, required this.primary, required this.secondary, required this.link, required this.timezone, required this.saveIdentity, required this.workdays, required this.workdaysHint, required this.working, required this.serdDay, required this.saveWorkdays, required this.features, required this.backdate, required this.countryCode, required this.whatsapp, required this.locationLabel, required this.lat, required this.lng, required this.method, required this.madhab, required this.reciters, required this.recitersHint, required this.defaultReciter, required this.firstInList, required this.market, required this.tabs, required this.quranTitle, required this.prayerMethods, required this.majority, required this.hanafi, required this.fees, required this.leaderboard, required this.teacherStudents, required this.saveSettings, required this.adminOnly, required this.loadOne, required this.digestTitle, required this.digestHint, required this.digestEnable, required this.day, required this.hour, required this.digestSaved, required this.saveFailed, required this.digestSub, required this.attTitle, required this.attHint, required this.attEnable, required this.afterHour, required this.attSaved, required this.attTitle2, required this.attSub, required this.language, required this.languageHint});
  final String loadSome;
  final String saved;
  final String fromGallery;
  final String takePhoto;
  final String tooBig1;
  final String logoUploaded;
  final String logoAdminOnly;
  final String logoFailed;
  final String logoHttps;
  final String backdateRange;
  final String intro;
  final String identity;
  final String name;
  final String uploading;
  final String uploadLogo;
  final String remove;
  final String logoLink;
  final String primary;
  final String secondary;
  final String link;
  final String timezone;
  final String saveIdentity;
  final String workdays;
  final String workdaysHint;
  final String working;
  final String serdDay;
  final String saveWorkdays;
  final String features;
  final String backdate;
  final String countryCode;
  final String whatsapp;
  final String locationLabel;
  final String lat;
  final String lng;
  final String method;
  final String madhab;
  final String reciters;
  final String recitersHint;
  final String defaultReciter;
  final String firstInList;
  final String market;
  final Map<String, String> tabs;
  final String quranTitle;
  final Map<String, String> prayerMethods;
  final String majority;
  final String hanafi;
  final String fees;
  final String leaderboard;
  final String teacherStudents;
  final String saveSettings;
  final String adminOnly;
  final String loadOne;
  final String digestTitle;
  final String digestHint;
  final String digestEnable;
  final String day;
  final String hour;
  final String digestSaved;
  final String saveFailed;
  final String digestSub;
  final String attTitle;
  final String attHint;
  final String attEnable;
  final String afterHour;
  final String attSaved;
  final String attTitle2;
  final String attSub;
  final String language;
  final String languageHint;
}

/// Students: list, form and the student file.
class SStu {
  const SStu({required this.status, required this.noCircle, required this.deleteTitle, required this.deleteBody, required this.title, required this.add, required this.searchPh, required this.empty, required this.emptyHint, required this.noMatch, required this.editDetails, required this.deleteWithFile, required this.circleRequired, required this.accountCreated, required this.codeTaken, required this.saveError, required this.deleteBodyPlain, required this.editTitle, required this.details, required this.fullName, required this.nameRequired, required this.birthDate, required this.tapToPick, required this.stageCircle, required this.stage, required this.allStages, required this.circleReq, required this.noCircles, required this.code, required this.codeHint, required this.codeRequired, required this.contact, required this.phone, required this.whatsapp, required this.address, required this.login, required this.password, required this.passwordHint, required this.min8, required this.email, required this.emailHint, required this.statusLabel, required this.saveChanges, required this.addBtn, required this.recEdited, required this.recDeleteTitle, required this.recDeleteBody, required this.deleted, required this.nextPlan, required this.planPh, required this.planSaved, required this.linkUpdated, required this.pickGuardian, required this.noGuardians, required this.newGuardian, required this.guardianName, required this.loginId, required this.phoneOpt, required this.password8, required this.create, required this.guardianIncomplete, required this.guardianCreated, required this.allRecitations, required this.streak, required this.weeklyAttendance, required this.lastRecitation, required this.surahV, required this.recLine, required this.progress, required this.partsOf30, required this.weeklyAttendanceV, required this.statsLine, required this.noPlan, required this.sheikh, required this.phone2, required this.addressLabel, required this.guardian, required this.noGuardian, required this.linkedTo, required this.newAccount, required this.linkExisting, required this.unlink, required this.log, required this.noRecitations});
  final Map<String, String> status;
  final String noCircle;
  final String deleteTitle;
  final String deleteBody;
  final String title;
  final String add;
  final String searchPh;
  final String empty;
  final String emptyHint;
  final String noMatch;
  final String editDetails;
  final String deleteWithFile;
  final String circleRequired;
  final String accountCreated;
  final String codeTaken;
  final String saveError;
  final String deleteBodyPlain;
  final String editTitle;
  final String details;
  final String fullName;
  final String nameRequired;
  final String birthDate;
  final String tapToPick;
  final String stageCircle;
  final String stage;
  final String allStages;
  final String circleReq;
  final String noCircles;
  final String code;
  final String codeHint;
  final String codeRequired;
  final String contact;
  final String phone;
  final String whatsapp;
  final String address;
  final String login;
  final String password;
  final String passwordHint;
  final String min8;
  final String email;
  final String emailHint;
  final String statusLabel;
  final String saveChanges;
  final String addBtn;
  final String recEdited;
  final String recDeleteTitle;
  final String recDeleteBody;
  final String deleted;
  final String nextPlan;
  final String planPh;
  final String planSaved;
  final String linkUpdated;
  final String pickGuardian;
  final String noGuardians;
  final String newGuardian;
  final String guardianName;
  final String loginId;
  final String phoneOpt;
  final String password8;
  final String create;
  final String guardianIncomplete;
  final String guardianCreated;
  final String allRecitations;
  final String streak;
  final String weeklyAttendance;
  final String lastRecitation;
  final String surahV;
  final String recLine;
  final String progress;
  final String partsOf30;
  final String weeklyAttendanceV;
  final String statsLine;
  final String noPlan;
  final String sheikh;
  final String phone2;
  final String addressLabel;
  final String guardian;
  final String noGuardian;
  final String linkedTo;
  final String newAccount;
  final String linkExisting;
  final String unlink;
  final String log;
  final String noRecitations;
}

/// Offline uploads.
class SSync {
  const SSync({required this.title, required this.allUp, required this.lastSync, required this.cached, required this.uploadNow, required this.nothing, required this.rejected, required this.discardTitle, required this.discardBody, required this.retry, required this.stripFailed, required this.counts, required this.nothingHint, required this.queued, required this.stripWaiting, required this.stripOffline, required this.offlineTitle, required this.offlineHint, required this.offlineProgress, required this.offlineNever, required this.offlineLast, required this.offlineNow, required this.offlineNeedsNet});
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
  final String offlineTitle;
  final String offlineHint;
  final String offlineProgress;
  final String offlineNever;
  final String offlineLast;
  final String offlineNow;
  final String offlineNeedsNet;
}

/// The teacher home, circle roster and lesson widgets.
class STeach {
  const STeach({required this.greeting, required this.findStudent, required this.noCircle, required this.noCircleHint, required this.yourCircles, required this.checkedIn, required this.checkInFailed, required this.circleScreen, required this.assistant, required this.stage, required this.doneOf, required this.checkIn, required this.startLesson, required this.savedPoints, required this.attendanceFailed, required this.noStudents, required this.searchPh, required this.all, required this.notToday, required this.recitedToday, required this.sort, required this.alpha, required this.notFirst, required this.topPoints, required this.xOfY, required this.noMatch, required this.showAll, required this.pointsN, required this.recitedTodayN, required this.dueReviews, required this.takeAttendance, required this.attendanceIs, required this.record, required this.general});
  final String greeting;
  final String findStudent;
  final String noCircle;
  final String noCircleHint;
  final String yourCircles;
  final String checkedIn;
  final String checkInFailed;
  final String circleScreen;
  final String assistant;
  final String stage;
  final String doneOf;
  final String checkIn;
  final String startLesson;
  final String savedPoints;
  final String attendanceFailed;
  final String noStudents;
  final String searchPh;
  final String all;
  final String notToday;
  final String recitedToday;
  final String sort;
  final String alpha;
  final String notFirst;
  final String topPoints;
  final String xOfY;
  final String noMatch;
  final String showAll;
  final String pointsN;
  final String recitedTodayN;
  final String dueReviews;
  final String takeAttendance;
  final String attendanceIs;
  final String record;
  final String general;
}

/// Shared widgets and service messages.
class SUi {
  const SUi({required this.credsText, required this.credsOnce, required this.copied, required this.copy, required this.done, required this.skeletonTitle, required this.skeletonSub, required this.add, required this.search, required this.noMatch, required this.channelName, required this.channelDesc, required this.sessionEnded, required this.requestFailed, required this.savedOffline, required this.outboxCheckIn, required this.outboxNote, required this.outboxGathering, required this.outboxExternal, required this.outboxEditRecitation, required this.outboxDeleteRecitation, required this.outboxPlan, required this.waitingUpload});
  final String credsText;
  final String credsOnce;
  final String copied;
  final String copy;
  final String done;
  final String skeletonTitle;
  final String skeletonSub;
  final String add;
  final String search;
  final String noMatch;
  final String channelName;
  final String channelDesc;
  final String sessionEnded;
  final String requestFailed;
  final String savedOffline;
  final String outboxCheckIn;
  final String outboxNote;
  final String outboxGathering;
  final String outboxExternal;
  final String outboxEditRecitation;
  final String outboxDeleteRecitation;
  final String outboxPlan;
  final String waitingUpload;
}

/// The smart weekly report.
class SWeekly {
  const SWeekly({required this.smartToggle, required this.smartHint, required this.title, required this.period, required this.thisWeek, required this.lastWeek, required this.recitations, required this.newPages, required this.reviews, required this.points, required this.attendance, required this.attV, required this.teacherNote, required this.noNote, required this.nextPlan, required this.open});
  final String smartToggle;
  final String smartHint;
  final String title;
  final String period;
  final String thisWeek;
  final String lastWeek;
  final String recitations;
  final String newPages;
  final String reviews;
  final String points;
  final String attendance;
  final String attV;
  final String teacherNote;
  final String noNote;
  final String nextPlan;
  final String open;
}

/// The daily portion card (student_wird).
class SWird {
  const SWird({required this.title, required this.newPart, required this.reviewPart, required this.fromTeacher, required this.suggested, required this.done, required this.sent, required this.todo, required this.recite, required this.open, required this.complete, required this.none, required this.dayOff, required this.pages});
  final String title;
  final String newPart;
  final String reviewPart;
  final String fromTeacher;
  final String suggested;
  final String done;
  final String sent;
  final String todo;
  final String recite;
  final String open;
  final String complete;
  final String none;
  final String dayOff;
  final String pages;
}

class S {
  const S({required this.lang, required this.common, required this.labels, required this.banners, required this.portal, required this.record, required this.badges, required this.market, required this.serdCard, required this.ann, required this.attn, required this.auth, required this.badgesStaff, required this.cal, required this.cert, required this.cfeat, required this.chat, required this.dash, required this.fees, required this.garden, required this.gather, required this.ins, required this.live, required this.mem, required this.mistakes, required this.mkt, required this.nav, required this.notif, required this.org, required this.plan, required this.priv, required this.prof, required this.quran, required this.rec, required this.recite, required this.rep, required this.rplan, required this.serd, required this.set, required this.stu, required this.sync, required this.teach, required this.ui, required this.weekly, required this.wird});
  /// 'ar', 'en', 'tr' or 'fr'.
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
  final SAttn attn;
  final SAuth auth;
  final SBadgesStaff badgesStaff;
  final SCal cal;
  final SCert cert;
  final SCfeat cfeat;
  final SChat chat;
  final SDash dash;
  final SFees fees;
  final SGarden garden;
  final SGather gather;
  final SIns ins;
  final SLive live;
  final SMem mem;
  final SMistakes mistakes;
  final SMkt mkt;
  final SNav nav;
  final SNotif notif;
  final SOrg org;
  final SPlan plan;
  final SPriv priv;
  final SProf prof;
  final SQuran quran;
  final SRec rec;
  final SRecite recite;
  final SRep rep;
  final SRplan rplan;
  final SSerd serd;
  final SSet set;
  final SStu stu;
  final SSync sync;
  final STeach teach;
  final SUi ui;
  final SWeekly weekly;
  final SWird wird;

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
    attn: SAttn(
      title: 'طلاب يحتاجون اهتمام',
      hint: 'مرتّبون من الأكثر حاجة: المتأخر عن هدفه، المنقطع عن التسميع، وكثير الغياب.',
      none: 'لا أحد يحتاج اهتمامًا خاصًا الآن 🌿',
      behind: 'متأخر عن هدفه {pages} صفحة',
      idle: 'لم يسمّع منذ {days} أيام دوام',
      never: 'لم يسمّع أبدًا',
      absences: 'غاب {count} مرات في أسبوعين',
      all: 'الكل',
      filterBehind: 'متأخر عن الهدف',
      filterIdle: 'منقطع',
      filterAbsent: 'غياب',
      recite: 'تسميع',
      call: 'اتصال',
      lastRecited: 'آخر تسميع: {v}',
      count: '{n} طالب',
    ),
    auth: SAuth(
      thisCenter: 'هذا المركز',
      noCenter: 'لم نجد مركزًا بهذا الرمز، تأكد من الرمز وحاول مرة أخرى',
      badLogin: 'رقم الدخول / البريد أو كلمة السر غير صحيحة',
      notMember: 'هذا الحساب غير مسجّل في {v}',
      serverDown: 'تعذّر الاتصال بالخادم، تأكد من الإنترنت وحاول مرة أخرى',
      codeFirst: 'أدخل رمز المركز أولًا',
      openFailed: 'تعذّر فتح الصفحة، حاول من المتصفح',
      signInTitle: 'سجّل دخولك إلى مركزك',
      step1: '١. المركز',
      centerCode: 'رمز المركز',
      enterCode: 'أدخل رمز المركز',
      noCenterShort: 'لا يوجد مركز بهذا الرمز',
      codeHint: 'رمز المركز هو أول جزء من رابط مركزك، مثال: eqraa من eqraa.bustan-alquran.com',
      step2: '٢. حسابك',
      loginId: 'رقم الهوية / الطالب أو البريد',
      enterId: 'أدخل رقمك أو بريدك',
      password: 'كلمة السر',
      enterPassword: 'أدخل كلمة السر',
      forgot: 'نسيت كلمة السر؟',
      signInTo: 'دخول إلى {name}',
      signIn: 'دخول',
      whoHint: 'الدخول للمعلمين والإدارة وأولياء الأمور والطلاب، كلٌّ حسب صلاحياته في المركز.',
      confirmEmail: 'تحقق من بريدك لتأكيد الحساب أولًا، ثم افتح رابط الدعوة من جديد لإكمال الانضمام',
      joinFailed: 'تعذّر إكمال الانضمام، تأكد من الإنترنت وحاول مرة أخرى',
      joinTitle: 'الانضمام إلى مركز',
      invalidInvite: 'الدعوة غير صالحة',
      invalidBody: 'منتهية أو استُخدمت من قبل. اطلب من مدير المركز دعوة جديدة.',
      inviteFrom: 'دعوة من {organization_name}',
      asRole: 'للانضمام كـ {role}',
      signedInAs: 'مسجّل دخول بـ {email}',
      confirmJoin: 'تأكيد الانضمام',
      inviteEmail: 'البريد الإلكتروني (من الدعوة)',
      yourPassword: 'كلمة سر حسابك',
      createPassword: 'أنشئ كلمة سر (8 أحرف على الأقل)',
      signInJoin: 'دخول والانضمام',
      createJoin: 'إنشاء الحساب والانضمام',
      noAccount: 'ليس لدي حساب',
      haveAccount: 'لدي حساب بالفعل',
      ob1: 'سجّل التسميع والحفظ',
      ob1Body: 'كل حلقة، كل طالب، كل صفحة حُفظت أو رُوجعت — بلمسة واحدة من المعلم، وبتقدير وتاريخ محفوظَين دائمًا.',
      ob2: 'تواصل مباشر مع المركز',
      ob2Body: 'رسائل وإعلانات وإشعارات فورية بين الإدارة والمعلمين والطلاب وأولياء الأمور، كل مركز بخصوصيته.',
      ob3: 'نقاط وشارات تحفّز الاستمرار',
      ob3Body: 'كل تسميع يستحق نقاطًا، وكل إنجاز شارة — سوق صغير وحلقات منافسة تجعل الحفظ عادة يومية محببة.',
      openSignup: 'افتح {_signupUrl} من متصفحك لتسجيل مركز جديد',
      skip: 'تخطي',
      signInBtn: 'تسجيل الدخول',
      next: 'التالي',
      registerCenter: 'تسجيل مركز جديد على الموقع ↗',
      pickCenter: 'اختر المركز',
      noCenters: 'حسابك غير مرتبط بأي مركز بعد',
      noCentersHint: 'اطلب من مدير المركز دعوتك، أو سجّل الدخول بحساب آخر',
    ),
    badgesStaff: SBadgesStaff(
      rules: {'manual': 'يدوية (يمنحها المشرف)', 'points_threshold': 'الوصول إلى عدد نقاط', 'recitations_count': 'عدد التسميعات', 'grade_count': 'عدد التسميعات بتقدير معيّن', 'streak_days': 'أيام متتالية بتسميع', 'weekly_attendance': 'نسبة الحضور الأسبوعية', 'juz_complete': 'إتمام جزء كامل في السرد', 'serd_passed_count': 'عدد السرد الناجح'},
      manual: 'يدوي',
      auto: 'تلقائي',
      expiresSuffix: '  ·  تنتهي {date}',
      nameRequired: 'اسم الشارة مطلوب',
      pickStudent: 'اختر الطالب',
      awarded: 'مُنحت الشارة',
      pickCircle: 'اختر الحلقة',
      awardedN: 'مُنحت لـ {n} طالب',
      deleteTitle: 'حذف الشارة',
      deleteBody: 'تُحذف من كل الطلاب. متأكد؟',
      newTitle: 'شارة جديدة',
      badge: 'الشارة',
      icon: 'رمز',
      name: 'الاسم',
      description: 'الوصف',
      rule: 'القاعدة',
      threshold: 'قيمة الشرط',
      juzNo: 'رقم الجزء (1–30)',
      percent: 'نسبة % (1–100)',
      count: 'العدد المطلوب',
      grade: 'التقدير',
      duration: 'مدة الشارة بالأيام (فارغ = دائمة)',
      active: 'فعّالة',
      giveManually: 'منح الشارة يدويًا',
      toStudent: 'لطالب',
      toCircle: 'لحلقة كاملة',
      holdersN: 'حاملو الشارة ({n})',
      noHolders: 'لم تُمنح لأحد بعد',
      revoked: 'سُحبت الشارة',
      revoke: 'سحب',
      reevaluate: 'إعادة تقييم الكل',
      reevaluated: 'أُعيد تقييم الشارات لكل الطلاب',
      intro: 'الشارات التلقائية تُمنح فور تحقق شرطها. اليدوية يمنحها المشرف، أو المعلم لطلاب حلقته.',
      empty: 'لا توجد شارات بعد',
      expiresAfter: 'تنتهي بعد {durationDays} يوم',
      inactive: 'غير فعّالة',
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
      withReg: ' — بتسجيل',
      notWorking: ' — ليس دوامًا',
      workingDay: 'يوم دوام',
      notWorkingDay: 'غير دوام',
      pickTypeTitle: 'اختر النوع واكتب العنوان',
      deleteBody: 'سيُحذف هذا العنصر مع كل التسجيلات عليه. متأكد؟',
      addTitle: 'إضافة إلى التقويم',
      type: 'النوع',
      titleField: 'العنوان',
      description: 'الوصف',
      fromV: 'من: {v}',
      toV: 'إلى: {v}',
      timeOpt: 'الساعة (اختياري)',
      place: 'المكان',
      whoSees: 'من يراها',
      audienceLabel: 'الجمهور',
      oneCircle: 'حلقة محددة',
      allCircles: 'كل الحلقات',
      oneStage: 'مرحلة محددة',
      allStages: 'كل المراحل',
      workingSection: 'الدوام',
      overrideType: 'تجاوز إعداد النوع',
      typeMakes: 'النوع يجعله {v}',
      offDaysHint: 'الأيام غير الدوام لا تُحتسب في نسبة حضور الطلاب.',
      registrationSection: 'التسجيل',
      seats: 'عدد المقاعد (فارغ = بلا حد)',
      closesAt: 'إغلاق التسجيل في: {v}',
      removeDeadline: 'إزالة الموعد',
      open: 'التسجيل مفتوح',
      saved: 'تم الحفظ',
      newType: 'نوع جديد',
      editType: 'تعديل النوع',
      name: 'الاسم',
      hasRegistration: 'يُسجَّل فيه',
      needsGuardian: 'يحتاج موافقة ولي الأمر',
      active: 'فعّال',
      typeNameRequired: 'اسم النوع مطلوب',
      typesTitle: 'أنواع عناصر التقويم',
      typesHint: 'العناصر السابقة تحتفظ بإعداد نوعها وقت إضافتها، فتعديل النوع لا يغيّر نسب الحضور القديمة.',
      working: 'دوام',
      guardianConsent: 'موافقة ولي الأمر',
      inactive: 'غير فعّال',
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
    cfeat: SCfeat(
      names: {'students': 'الطلاب', 'circles': 'الحلقات', 'attendance': 'الحضور والمجالس', 'serd': 'السرد القرآني', 'points': 'النقاط', 'badges': 'الشارات', 'market': 'سوق النقاط', 'circle-challenges': 'منافسات الحلقات', 'activities': 'الأنشطة', 'calendar': 'التقويم', 'announcements': 'الإعلانات', 'chat': 'المحادثات', 'notifications': 'الإشعارات', 'reports': 'التقارير', 'certificates': 'الشهادات', 'fees': 'رسوم الطلاب', 'quran': 'المصحف', 'recitations': 'التسميع المسجّل والمباشر', 'wird': 'ورد اليوم وتذكيره', 'garden_tree': 'الشجرة المتحركة'},
      tab: 'مميزات المركز',
      title: 'المميزات التي يستخدمها المركز',
      hint: 'أوقف ما لا يحتاجه مركزك فيختفي من القوائم عند الجميع، وأعده متى شئت. المتاح هنا هو ما تشمله خطتك.',
      notInPlan: 'غير متاحة في خطتك',
      save: 'حفظ المميزات',
      saved: 'تم حفظ مميزات المركز',
      off: 'هذه الميزة متوقفة في مركزك.',
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
    dash: SDash(
      takeAttendance: 'تسجيل الحضور',
      addStudent: 'إضافة طالب',
      serdSession: 'جلسة سرد',
      newAnnouncement: 'إعلان جديد',
      calendar: 'التقويم',
      title: 'لوحة التحكم',
      greeting: '{v}، السلام عليكم',
      yourCirclesToday: 'حلقاتك اليوم',
      noCircle: 'لم يتم تعيينك لأي حلقة بعد - اطلب من المشرف إضافتك.',
      notWorkingDay: 'اليوم ليس من أيام الدوام في مركزك',
      studentsN: '{students} طالب',
      recitedN: 'سمّع {recited}',
      presentN: 'حاضر {present}',
      absentN: 'غائب {absent}',
      students: 'الطلاب',
      teachers: 'المعلمون',
      circles: 'الحلقات',
      todayAttendance: 'حضور اليوم',
      shortcuts: 'اختصارات سريعة',
      centerAdmin: 'مدير المركز',
      waitSerd: 'سرد بانتظار الاعتماد',
      waitMarket: 'طلبات سوق بانتظار القرار',
      waitGatherings: 'مجالس بانتظار ربط الأسماء',
      waitExternal: 'تسميع خارجي بانتظار الربط',
      needsYou: 'يحتاج انتباهك',
      nothingWaiting: 'لا شيء ينتظر قرارك ✓',
      inactiveN: 'لم يسمّعوا منذ أسبوعين ({inactive_total})',
      thisWeek: 'هذا الأسبوع',
      weekRecitations: 'تسميعات {recitations}',
      weekReciting: 'طلاب سمّعوا {reciting_students}',
      weekPoints: 'نقاط {points}',
      weekAttendance: 'حضور {v}',
      upcomingEvents: 'فعاليات قادمة',
      notYet: 'لم يسمّع بعد',
      registered: 'مسجّل',
      dropoutRisk: 'خطر التسرّب',
      noRisk: 'لا طالب معرَّض للتسرّب ✓',
      teacherPerf: 'أداء المعلمين (7 أيام)',
      recitationsWord: 'تسميع',
      riskTags: {'never': 'لم يسمّع إطلاقًا', 'regressed': 'توقّف بعد انتظام', 'slowing': 'تباطأ', 'attendance_gap': 'يحضر ولا يسمّع'},
      idleDays: '{n} يوم دوام',
      perfLine: '{circles} حلقات · {students} طالب · حضور {days} يوم',
    ),
    fees: SFees(
      title: 'الرسوم',
      collectedMonth: 'المحصّل هذا الشهر',
      outstanding: 'المستحق على الطلاب',
      owingN: 'عليهم مستحقات',
      filter: {'all': 'الكل', 'owing': 'عليهم مستحقات', 'noPlan': 'بلا خطة'},
      search: 'ابحث باسم الطالب أو رقمه',
      none: 'لا يوجد طلاب',
      exempt: 'معفى',
      discountV: 'خصم {n}٪',
      noPlan: 'بلا خطة',
      owes: 'عليه',
      credit: 'له رصيد',
      settled: 'لا مستحقات',
      dueSoFar: 'المستحق حتى اليوم',
      paidTotal: 'المدفوع',
      upcoming: 'رسوم قادمة',
      plan: 'الخطة: {name}',
      periods: {'monthly': 'شهرية', 'term': 'فصلية', 'once': 'لمرة واحدة'},
      recordTitle: 'تسجيل دفعة',
      amount: 'المبلغ',
      amountInvalid: 'أدخل مبلغًا صحيحًا',
      method: 'طريقة الدفع',
      methods: {'cash': 'نقدًا', 'transfer': 'حوالة', 'card': 'بطاقة', 'wallet': 'محفظة إلكترونية', 'other': 'أخرى'},
      paidOn: 'تاريخ الدفع: {date}',
      note: 'ملاحظة (اختياري)',
      record: 'تسجيل الدفعة',
      recorded: 'تم تسجيل الدفعة ✓',
      outbox: 'دفعة {name}: {amount}',
      pendingUpload: 'بانتظار الرفع',
      charges: 'الرسوم',
      payments: 'الدفعات',
      status: {'open': 'مستحقة', 'waived': 'مُعفاة', 'cancelled': 'ملغاة'},
      notYetDue: 'لم يحن موعدها',
      waive: 'إعفاء',
      cancelCharge: 'إلغاء الرسوم',
      reopen: 'إعادة فتح',
      cancelChargeConfirm: 'إلغاء هذه الرسوم؟ (للخطأ في الإدخال؛ للمسامحة استخدم «إعفاء»)',
      receiptNo: 'إيصال رقم {n}',
      receiptTitle: 'إيصال استلام',
      voidPayment: 'إلغاء الدفعة',
      voidReason: 'سبب الإلغاء (اختياري)',
      voidConfirm: 'إلغاء هذه الدفعة؟ يبقى الإيصال مسجلًا بختم «ملغى».',
      voided: 'ملغاة',
      noCharges: 'لا توجد رسوم',
      noPayments: 'لا توجد دفعات',
      balanceAfter: 'المتبقي على الطالب',
      byLabel: 'المستلم',
      share: 'مشاركة',
      receiptText: '{center}\n{title} — {no}\n{student}\n{amount} · {date} · {method}\n{left}',
      manageOnWeb: 'الخطط وتعيينها للطلاب والإعدادات والتقرير من لوحة الموقع.',
      adminOnly: 'الرسوم يديرها المشرف فقط',
      openAccount: 'حساب الرسوم',
    ),
    garden: SGarden(
      online: 'متصل',
      offline: 'دون اتصال',
      noInternet: 'الشبكة بلا إنترنت',
      syncCenter: 'مركز المزامنة',
      offlineWaiting: 'دون اتصال · {n} بانتظار الرفع',
      syncing: 'جاري الرفع',
      waitingN: '{n} بانتظار الرفع',
      failedN: '{n} لم تُرفع',
      tabHome: 'الرئيسية',
      tabStudents: 'الطلاب',
      tabSerd: 'السرد',
      tabChat: 'الرسائل',
      tabMore: 'المزيد',
      seeAll: 'عرض الكل',
      moreTitle: 'كل الأقسام',
      checkedInShort: 'سجّلتَ حضورك',
      checkInShort: 'سجّل حضوري',
      studentsN: 'طلاب الحلقة ({n})',
      statCircles: 'حلقات',
      statStudents: 'طالبًا',
      statRecited: 'سمّعوا',
      statPresent: 'حاضرون',
      quickTitle: 'اختصارات',
      account: 'الحساب',
      notificationPrefs: 'تفضيلات الإشعارات',
      statJuz: 'جزءًا',
      statPoints: 'نقطة',
      statStreak: 'أيام متتالية',
      explore: 'استكشف',
      statAttendance: 'الحضور',
      itemsN: '{n} عنصرًا',
    ),
    gather: SGather(
      noCircle: 'بدون حلقة',
      okLinked: 'رُبط الاسم',
      skippedSuffix: ' · تُجوهل {n}',
      actionFailed: 'تعذّر تنفيذ العملية — تحقّق من الاتصال',
      extNew: 'تسميع خارجي',
      studentName: 'اسم الطالب',
      type: 'النوع',
      surah: 'السورة',
      fromAyah: 'من آية',
      toAyah: 'إلى آية',
      grade: 'التقدير',
      extUpload: 'رفع التسميع',
      extUploaded: 'رُفع التسميع وينتظر ربط المشرف',
      extLinked: 'رُبط التسميع وسُجّل للطالب (+{v} نقطة)',
      rejectTitle: 'رفض الطلب',
      reasonOpt: 'السبب (اختياري)',
      reject: 'رفض',
      rejected: 'رُفض الطلب',
      extNewShort: 'تسميع جديد',
      noRequests: 'لا طلبات بعد',
      linked: 'رُبط',
      rejectedChip: 'مرفوض',
      pending: 'بانتظار الربط',
      linkedTo: 'رُبط بـ {matched_name}',
      reasonV: 'السبب: {reject_reason}',
      pickStudent: 'اختيار طالب',
      deletedReq: 'حُذف الطلب',
      linkedAttended: 'رُبط الاسم وسُجّل حضور الطالب',
      addName: 'إضافة اسم',
      name: 'الاسم',
      add: 'إضافة',
      nameAdded: 'أُضيف الاسم',
      activity: 'النشاط',
      metaLine: '{session_date}{v}{v2} · رفعه {v3}',
      namesN: 'الأسماء ({n})',
      nameDeleted: 'حُذف الاسم',
      linkedLine: 'رُبط: {matched_name} ({matched_code}){v}',
      skipped: 'تُجوهل',
      skip: 'تجاهل',
      nameSkipped: 'تُجوهل الاسم',
      unlink: 'إلغاء الربط',
      uploadNew: 'رفع نشاط جديد',
      activityName: 'اسم النشاط',
      activityType: 'نوع النشاط',
      none: '— بدون —',
      placeOpt: 'المكان (اختياري)',
      attendees: 'الحاضرون — اسم في كل سطر',
      uploadBtn: 'رفع النشاط',
      uploadedN: 'رُفع النشاط بـ {n} اسم',
      uploadFailed: 'تعذّر الرفع — تحقّق من الاتصال',
      upload: 'رفع نشاط',
      empty: 'لا أنشطة مرفوعة بعد',
      countsLine: '{total} اسم · رُبط {matched}{v}',
      reviewed: 'تمت المراجعة',
      pendingN: 'بانتظار ({pending})',
      waitingAdmin: 'بانتظار المشرف',
      pickStudentTitle: 'اختر الطالب',
      searchPh: 'اسم الطالب أو رقمه',
    ),
    ins: SIns(
      guardianVisibleSuffix: ' · ظاهرة لولي الأمر',
      overdueSuffix: ' · متأخرة {n}',
      noCircle: 'بدون حلقة',
      auditActions: {'delete': 'حذف', 'update': 'تعديل', 'create': 'إضافة'},
      auditTables: {'students_profile': 'طالب', 'circles': 'حلقة', 'stages': 'مرحلة', 'serd_sessions': 'جلسة سرد', 'organization_members': 'عضو'},
      newNote: 'ملاحظة جديدة',
      notePh: 'مثال: يستعجل في أواخر الآيات',
      guardianVisible: 'ظاهرة لولي الأمر',
      noteFailed: 'تعذّر حفظ الملاحظة',
      notesTitle: 'ملاحظات المعلم',
      noNotes: 'لا ملاحظات بعد',
      searchFailed: 'تعذّر البحث. تحقّق من الاتصال.',
      searchPh: 'ابحث: طالب، رقم الطالب، معلم، حلقة',
      noResults: 'لا نتائج',
      students: 'الطلاب',
      staff: 'المعلمون والمشرفون',
      admin: 'مشرف',
      teacher: 'معلم',
      circles: 'الحلقات',
      reviewsTitle: 'المراجعة المقترحة اليوم',
      noReviews: 'لا مراجعات مستحقة اليوم ✓',
      reviewsHint: 'كل سورة تُقترح بعد فاصل يكبر مع التقدير الجيد ويعود ليوم واحد مع الضعيف.',
      challengeTitleRequired: 'عنوان المنافسة مطلوب',
      newChallenge: 'منافسة جديدة',
      editChallenge: 'تعديل المنافسة',
      title: 'العنوان',
      description: 'الوصف',
      metric: 'المقياس',
      deleteChallenge: 'حذف المنافسة',
      sure: 'متأكد؟',
      challenge: 'المنافسة',
      noCircles: 'لا توجد حلقات فيها طلاب بعد',
      boardLine: '{students} طالب  ·  المجموع {total}',
      noChallenges: 'لا توجد منافسات',
      noAudit: 'لا يوجد عمليات مسجّلة بعد',
      auditHint: 'تظهر هنا عمليات الحذف والتعديل الحساسة',
    ),
    live: SLive(
      title: 'التسميع',
      hint: 'اختر السورة والمقطع ثم ابدأ: الآيات تكون مخفية، وتظهر كل كلمة عندما تقرؤها صحيحة. إذا نسيت كلمة أو أخطأت فيها يتوقف التسميع وينبّهك.',
      student: 'الطالب',
      surah: 'السورة',
      type: 'نوع التسميع',
      from: 'من الآية',
      to: 'إلى الآية',
      start: 'ابدأ التسميع',
      unsupported: 'هذا المتصفح لا يدعم التسميع المباشر. استخدم Chrome أو Edge، أو تطبيق بستان القرآن.',
      micDenied: 'لم يُسمح باستخدام الميكروفون. اسمح به من الإعدادات ثم حاول مرة أخرى.',
      network: 'التعرّف على الكلام يحتاج اتصالًا بالإنترنت.',
      listening: 'أستمع إليك… اقرأ من حفظك',
      paused: 'متوقف',
      progress: '{n} من {total} كلمة',
      mistakesN: 'الأخطاء: {n}',
      stopMissing: 'توقّف: نسيت كلمة',
      stopWrong: 'توقّف: أخطأت في كلمة',
      correctIs: 'الصحيح:',
      heard: 'سمعتُ: {w}',
      resume: 'تابع',
      forgot: 'لا أتذكر',
      finish: 'إنهاء وتسليم',
      result: 'نتيجة التسميع',
      score: '{n}% صحيح',
      mistakeList: 'الكلمات التي أخطأت فيها:',
      resultNote: 'النتيجة من التعرّف على الكلام في جهازك، والمعلم هو من يعتمد التسميع.',
      note: 'ملاحظة للمعلم (اختياري)',
      send: 'أرسل للمعلم',
      sending: 'جارٍ الإرسال…',
      sent: 'أُرسل التسميع لمعلمك، وسيصلك إشعار بقراره.',
      again: 'سمّع من جديد',
      appAudio: 'يُسجَّل صوتك من بداية التسميع ويُرسل مع النتيجة ليسمعه المعلم.',
      recording: 'تسجيل',
      withAudio: 'التسجيل الصوتي مرفق ({t})',
      retry: 'أعد الإرسال',
      notSent: 'لم يُرسل التسميع بعد. تأكد من الاتصال واضغط «أعد الإرسال».',
      nothingHeard: 'لم أسمع شيئًا من التلاوة، فلم يُرسل التسميع. تأكد من الميكروفون وسمّع من جديد.',
      mine: 'تسميعاتي',
      error: 'حدث خطأ، حاول مرة أخرى.',
      fab: 'سمّع',
      liveBadge: 'تسميع مباشر',
      loading: 'جارٍ تحميل الآيات…',
      appNoAudio: 'في التطبيق يُرسل التسميع بنتيجته دون تسجيل صوتي.',
      appUnsupported: 'التعرّف على الكلام غير متاح على هذا الجهاز. ثبّت تطبيق Google أو فعّل خدمة التعرّف على الكلام من إعدادات الجهاز.',
    ),
    mem: SMem(
      modules: {'students': 'الطلاب', 'circles': 'الحلقات', 'attendance': 'الحضور', 'serd': 'السرد القرآني وطلبات التسميع', 'points': 'النقاط', 'badges': 'الشارات', 'market': 'سوق النقاط', 'circle-challenges': 'منافسات الحلقات', 'activities': 'الأنشطة', 'calendar': 'التقويم', 'announcements': 'الإعلانات', 'chat': 'المحادثات', 'notifications': 'الإشعارات', 'reports': 'التقارير', 'certificates': 'الشهادات'},
      status: {'active': 'نشط', 'invited': 'مدعو', 'suspended': 'موقوف'},
      password8: 'كلمة السر 8 أحرف على الأقل',
      passwordChanged: 'تم تغيير كلمة السر',
      accountSaved: 'حُفظت حالة الحساب',
      removeTitle: 'حذف من المركز',
      removeBody: 'متأكد إنك بدك تحذف "{fullName}" من المركز؟ رح يفقد كل صلاحياته هنا فورًا.',
      editTitle: 'تعديل عضو',
      selfNote: 'لا يمكنك تعديل أو حذف صلاحياتك الخاصة من هنا - اطلب من مدير آخر إن وجد.',
      role: 'الدور',
      statusLabel: 'الحالة',
      modulesTitle: 'الوحدات التي يمكنه الوصول لها',
      viewOnly: 'حساب عرض فقط',
      viewOnlyHint: 'يرى ولا يعدّل: يبقى دوره كما هو لكن لا يُحفظ له أي تغيير في هذا المركز.',
      changePassword: 'تغيير كلمة السر',
      newPassword: 'كلمة سر جديدة (8 أحرف على الأقل)',
      teacherCreated: 'تم إنشاء حساب المعلم',
      newTeacher: 'معلم جديد',
      teacherHint: 'يدخل المعلم برمز المركز + رقمه (أو بريده) + كلمة السر.',
      required: 'مطلوب',
      loginId: 'رقم الدخول أو البريد الإلكتروني',
      min8: '8 أحرف على الأقل',
      createAccount: 'إنشاء الحساب',
      inviteCreated: 'تم إنشاء الدعوة',
      inviteError: 'حدث خطأ أثناء الدعوة',
      inviteTitle: 'دعوة عضو جديد',
      email: 'البريد الإلكتروني',
      inviteBtn: 'إنشاء دعوة',
      pendingInvites: 'دعوات لسه ما انضمّت',
      contactTitle: 'التواصل',
      contactHint: 'يُفضّل مع رمز الدولة، مثل ‎+962791234567',
    ),
    mistakes: SMistakes(
      title: 'مواضع الأخطاء المتكررة',
      hint: 'من اختبارات المعلم في المصحف والفحص الآلي للتسميعات المسجّلة، في آخر {days} يومًا. ركّز عليها في المراجعة.',
      summary: '{sessions} تسميع · {mistakes} خطأ',
      bySurah: 'حسب السورة',
      byAyah: 'الآيات الأكثر خطأ',
      byWord: 'الكلمات الأكثر خطأ',
      times: '×{n}',
      none: 'لا توجد أخطاء مسجّلة في هذه الفترة.',
      ayah: '{surah} : {ayah}',
    ),
    mkt: SMkt(
      rateTitle: 'سعر تحويل النقاط',
      perPoints: 'كل (نقطة)',
      equals: '= (قيمة)',
      currency: 'رمز العملة',
      rateHint: 'يسري التغيير على النقاط التي تُحوَّل بعده فقط؛ ما تحوّل سابقًا يبقى بقيمته.',
      rateInvalid: 'أدخل أرقامًا صحيحة ورمز العملة',
      rateSaved: 'تم حفظ السعر',
      cancelOrder: 'إلغاء الطلب',
      cancelOrderBody: 'يُعاد الرصيد والمخزون. متأكد؟',
      no: 'لا',
      yes: 'نعم',
      orderCancelled: 'أُلغي الطلب',
      newItem: 'عنصر جديد',
      adminOnly: 'إدارة السوق للمدير فقط',
      items: 'العناصر',
      ordersN: 'الطلبات ({pending})',
      orders: 'الطلبات',
      balances: 'الأرصدة',
      noOrders: 'لا توجد طلبات',
      delivered: 'تم التسليم',
      walletLine: '{earnedPoints} نقطة  ·  المصروف {v}',
      disabled: 'السوق معطّل حاليًا (يُفعَّل من إعدادات المركز)',
      rateLine: 'كل {pointsPerUnit} نقطة = {v}',
      rateSub: 'سعر تحويل النقاط إلى عملة',
      noItems: 'لا توجد عناصر بعد',
      unlimited: 'مخزون غير محدود',
      stockN: 'المخزون: {n}',
      inactiveSuffix: '  ·  غير فعّال',
      nameRequired: 'الاسم والسعر مطلوبان',
      noUpload: 'لا تملك صلاحية رفع الصور',
      uploadFailed: 'تعذّر رفع الصورة',
      tooBig3: 'الصورة كبيرة (الحد 3 ميغابايت)',
      deleteItem: 'حذف العنصر',
      deleteItemBody: 'الطلبات السابقة تحتفظ باسمه وسعره. متأكد؟',
      editItem: 'تعديل عنصر',
      name: 'الاسم',
      description: 'الوصف',
      uploadDevice: 'رفع من الجهاز',
      removeImage: 'إزالة الصورة',
      imageLink: 'أو الصق رابط الصورة (https)',
      priceIn: 'السعر ({symbol})',
      stock: 'المخزون (فارغ = بلا حد)',
      active: 'فعّال (يظهر للطلاب)',
    ),
    nav: SNav(
      items: {'/dashboard': 'لوحة التحكم', '/sync': 'المزامنة', '/attention': 'طلاب يحتاجون اهتمام', '/review-plan': 'ورد المراجعة اليومي', '/students': 'الطلاب', '/circles': 'الحلقات', '/attendance': 'الحضور', '/gatherings': 'المجالس والأنشطة', '/recitations': 'التسميعات المسجّلة', '/external-recitations': 'التسميع الخارجي', '/reviews': 'المراجعة المقترحة', '/search': 'بحث شامل', '/quran': 'المصحف', '/serd': 'السرد القرآني', '/stages': 'المراحل', '/points': 'النقاط', '/badges': 'الشارات', '/market': 'سوق النقاط', '/circle-challenges': 'منافسات الحلقات', '/activities': 'الأنشطة', '/announcements': 'الإعلانات', '/calendar': 'التقويم', '/chat': 'المحادثات', '/notifications': 'الإشعارات', '/reports': 'التقارير', '/certificates': 'الشهادات', '/fees': 'الرسوم', '/members': 'الأعضاء والأدوار', '/deletion-requests': 'طلبات حذف البيانات', '/audit': 'سجل العمليات', '/site': 'الموقع العام', '/settings': 'إعدادات المركز'},
      sections: {'teaching': 'التعليم', 'motivation': 'التحفيز', 'comms': 'التواصل', 'admin': 'إدارة المركز'},
      switchCenter: 'تبديل المركز',
      menu: 'القائمة',
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
      events: {'announcement': 'إعلان جديد', 'calendar_entry': 'فعالية جديدة في التقويم', 'center_closed': 'إجازة أو إغلاق', 'event_reminder': 'تذكير بالفعاليات', 'waitlist_promoted': 'الترقية من قائمة الانتظار', 'serd_assigned': 'سرد مطلوب مني', 'serd_approved': 'اعتماد السرد', 'serd_rejected': 'عدم اعتماد السرد', 'market_fulfilled': 'تسليم طلب السوق', 'market_cancelled': 'إلغاء طلب السوق', 'badge_awarded': 'الشارات', 'weekly_digest': 'ملخص الأسبوع', 'attendance_reminder': 'تذكير تسجيل الحضور', 'teacher_checkin_reminder': 'تذكير المعلم بتسجيل حضوره', 'student_idle_teacher': 'تنبيه المعلم: طالب متأخر عن التسميع', 'student_idle': 'تذكير الطالب المتأخر عن التسميع', 'student_absences': 'تنبيه المشرف: غياب متكرر', 'deletion_request': 'طلبات حذف البيانات', 'deletion_reviewed': 'نتيجة طلب حذف بياناتي', 'gathering_submitted': 'رفع مجلس جديد', 'external_submitted': 'تسميع خارجي جديد', 'external_reviewed': 'نتيجة التسميع الخارجي', 'assistant_assigned': 'تعيين معلم مساعد', 'billing_reminder': 'تذكير الاشتراك', 'billing_reviewed': 'نتيجة مراجعة الدفع', 'capacity_warning': 'سعة الخطة', 'billing_downgraded': 'التحويل للخطة المجانية', 'fee_payment': 'إيصال دفع الرسوم', 'fee_overdue': 'تذكير الرسوم المستحقة', 'recitation_submitted': 'تسميع مسجّل جديد للمراجعة', 'recitation_reviewed': 'مراجعة التسميع المسجّل', 'wird_reminder': 'تذكير بورد اليوم'},
      types: 'أنواع الإشعارات',
      instantTitle: 'لتصل الإشعارات فورًا',
      instantBody: 'الهاتف يوفّر البطارية بتأخير إشعارات هذا التطبيق. اسمح له بالعمل دون قيود لتصلك الرسائل لحظة إرسالها.',
      instantBattery: 'إيقاف توفير البطارية',
      instantBatteryHint: 'اختر «كل التطبيقات» ← بستان القرآن ← «عدم التحسين» أو «غير مقيّد».',
      instantAutostart: 'السماح بالتشغيل التلقائي',
      instantAutostartHint: 'في هواتف {maker} فعّل «التشغيل التلقائي» لبستان القرآن، وإلا توقفت الإشعارات حين يُغلق التطبيق.',
      instantOk: 'الإشعارات تصل فورًا على هذا الهاتف',
    ),
    org: SOrg(
      circleStatus: {'active': 'نشطة', 'archived': 'مؤرشفة'},
      attStatus: {'present': 'حاضر', 'absent': 'غائب', 'excused': 'مستأذن', 'late': 'متأخر'},
      outboxAttendance: 'كشف حضور {sessionDate} ({n} طالب)',
      saveErrorRetry: 'حدث خطأ أثناء الحفظ - حاول مرة أخرى',
      deleteCircle: 'حذف الحلقة',
      deleteCircleBody: 'متأكد إنك بدك تحذف هذي الحلقة؟ لا يمكن التراجع.',
      editCircle: 'تعديل الحلقة',
      addCircle: 'إضافة حلقة',
      circleName: 'اسم الحلقة',
      stage: 'المرحلة',
      noStage: 'بدون مرحلة',
      teacher: 'المعلم',
      noTeacher: 'بدون معلم',
      capacity: 'السعة (عدد الطلاب)',
      assistants: 'المعلمون المساعدون',
      assistantsHint: 'يرثون صلاحيات معلم هذه الحلقة عليها فقط ويظهرون بوسم «معلم مساعد».',
      noOtherTeachers: 'لا معلمون آخرون في المركز',
      status: 'الحالة',
      addCircleBtn: 'إضافة الحلقة',
      noCircles: 'لا يوجد حلقات بعد',
      noCirclesHint: 'أنشئ أول حلقة ثم أضف إليها الطلاب',
      capacityN: 'السعة {capacity}',
      gradesLoadFailed: 'تعذّر تحميل التقديرات',
      keyRule: 'المفتاح حروف إنجليزية صغيرة/أرقام/_ فقط، والاسم مطلوب',
      gradesSaved: 'تم حفظ التقديرات',
      gradesTitle: 'تقديرات التسميع والنقاط',
      gradesHint: 'أسماء التقديرات وعدد النقاط لكل تقدير. تُحفظ النقاط على كل تسميع لحظة تسجيله، فتغييرها يسري على التسميعات القادمة فقط.',
      name: 'الاسم',
      points: 'النقاط',
      addGrade: 'إضافة تقدير جديد',
      keyField: 'المفتاح (مثل outstanding)',
      nameField: 'الاسم (مثل متميز)',
      saveGrades: 'حفظ التقديرات',
      gradesAdminOnly: 'بس المدير يقدر يعدّل التقديرات والنقاط.',
      stageTaken: 'الاسم أو الكود مستخدم من قبل بهذا المركز',
      deleteStage: 'حذف المرحلة',
      deleteStageBody: 'متأكد إنك بدك تحذف هذي المرحلة؟',
      editStage: 'تعديل المرحلة',
      addStage: 'إضافة مرحلة',
      stageName: 'اسم المرحلة',
      stageNamePh: 'تمهيدي',
      stageCode: 'رقم المرحلة برقم الطالب (خانة أو خانتين، مثل 2). إذا تركته فاضيًا يُستخدم ترتيب المرحلة',
      stageOrder: 'ترتيب المرحلة',
      addStageBtn: 'إضافة المرحلة',
      noStages: 'لا يوجد مراحل بعد',
      noStagesHint: 'المراحل تنظّم الحلقات وتُستخدم في ترقيم الطلاب',
      orderN: 'الترتيب {sortOrder}',
      circlesLoadFailed: 'تعذّر تحميل الحلقات',
      studentsLoadFailed: 'تعذّر تحميل طلاب الحلقة',
      attSaved: 'تم حفظ الحضور بنجاح',
      saveAtt: 'حفظ الحضور',
      circle: 'الحلقة',
      dateV: 'التاريخ:  {v}',
      pickCircle: 'اختر الحلقة لتسجيل الحضور',
      pickCircleHint: 'ثم حدّد حالة كل طالب واحفظ',
      noStudents: 'لا يوجد طلاب بهذي الحلقة',
      allPresent: 'تحديد الكل حاضر',
      deleteActivity: 'حذف النشاط',
      deleteActivityBody: 'متأكد إنك بدك تحذف هذا النشاط؟',
      editActivity: 'تعديل النشاط',
      newActivity: 'نشاط جديد',
      title: 'العنوان',
      description: 'الوصف',
      whenOpt: 'الموعد (اختياري)',
      addActivity: 'إضافة النشاط',
      noActivities: 'لا يوجد أنشطة بعد',
      noActivitiesHint: 'أضف أنشطة المركز ليراها الجميع',
      noTime: 'بدون موعد محدد',
      siteIntro: 'صفحة تعريفية عامة عن مركزك، تُعرض للزوار غير المسجّلين.',
      siteEnable: 'فعّل الصفحة العامة',
      heroTitle: 'عنوان رئيسي',
      heroBody: 'نص تعريفي',
      contactEmail: 'بريد التواصل',
      siteAdminOnly: 'بس المدير يقدر يعدّل إعدادات الموقع العام.',
    ),
    plan: SPlan(
      graceTrial: '🍂 انتهت الفترة التجريبية — بستانكم ينتظر السقاية: جدّدوا من لوحة التحكم على الويب',
      gracePaid: '🍂 انتهى اشتراك المركز — بستانكم ينتظر السقاية: جدّدوا من لوحة التحكم على الويب',
      soonTrial: '🌿 تنتهي الفترة التجريبية خلال {days}',
      soonPaid: '🌿 ينتهي اشتراك المركز خلال {days}',
      days: {'one': 'يوم واحد', 'two': 'يومين', 'many': '{n} أيام'},
      students: {'one': 'طالب واحد', 'two': 'طالبان', 'many': '{n} طلاب'},
      studentsFull: '🌳 امتلأ البستان: وصل المركز للحد الأقصى من الطلاب ({max})',
      studentsLeft: '🌿 تبقى {n} يمكن إضافتهم ضمن الخطة',
      teachersFull: '🌳 وصل المركز للحد الأقصى من المعلمين ({max})',
      oneTeacherLeft: '🌿 تبقى إضافة معلم واحد فقط ضمن الخطة',
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
    prof: SProf(
      thisMonth: 'هذا الشهر',
      lastMonth: 'الشهر الماضي',
      last90: 'آخر 3 أشهر',
      vsPrev: 'مقارنة بالفترة السابقة',
      same: 'بلا تغيير',
      newV: 'جديد',
      recitations: 'التسميعات',
      reciting: 'طلاب سمّعوا',
      points: 'النقاط',
      attendance: 'الحضور',
      serdHeard: 'سرد استمع له',
      serdApproved: 'سرد معتمد',
      daysPresent: 'أيام حضوره',
      teacherDays: 'أيام حضور المعلم',
      students: 'الطلاب',
      circles: 'الحلقات',
      assistant: 'مساعد',
      teacher: 'المعلم',
      assistants: 'المساعدون',
      recent: 'آخر التسميعات',
      teacherAtt: 'حضور المعلم',
      nothing: 'لا شيء في هذه الفترة',
      lastRec: 'آخر تسميع: {v}',
      never: 'لم يسمّع بعد',
      today: 'اليوم',
      daysAgo: 'منذ {n} يوم',
      profile: 'الملف',
      myProfile: 'ملفي وإنجازي',
      message: 'مراسلة',
      call: 'اتصال',
      notAllowed: 'ليست لديك صلاحية لعرض هذا الملف',
      goalTitle: 'هدف الحفظ والختمة',
      memorized: '{n} من {total} صفحة',
      percentQuran: '{p}% من القرآن',
      pace: 'السرعة الفعلية',
      paceV: '{n} صفحة/يوم دوام',
      goalPace: 'الهدف',
      goalPaceV: '{n} صفحة يوميًا',
      sinceStart: 'منذ بدء الهدف: {actual} من {expected} صفحة',
      forecast: 'الختمة المتوقعة',
      forecastGoal: 'بسرعة الهدف',
      noPace: 'لا حفظ جديد مؤخرًا',
      noGoal: 'لم يُحدَّد هدف بعد',
      goalStatus: {'ahead': 'متقدّم', 'on_track': 'على الخطة', 'behind': 'متأخر', 'done': 'أتمّ الهدف'},
      setGoal: 'تحديد الهدف',
      editGoal: 'تعديل الهدف',
      pagesPerDay: 'صفحات في كل يوم دوام',
      targetPages: 'الهدف بالصفحات (604 = الختمة)',
      note: 'ملاحظة (اختياري)',
      save: 'حفظ',
      clearGoal: 'إلغاء الهدف',
      goalSaved: 'حُفظ الهدف',
      invalidPages: 'أدخل عددًا بين 0.25 و20',
      outboxGoal: 'هدف حفظ {name}',
      whatsapp: 'واتساب',
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
      credit: 'النص: الرسم العثماني برواية حفص عن عاصم · التلاوات: everyayah.com و quran.com · النص الاحتياطي: tanzil.net',
      bookmarks: 'العلامات',
      mark: 'إضافة علامة',
      repeatN: 'تكرار الآية {n} مرات',
      play: 'تشغيل',
      pause: 'إيقاف',
      sync: 'طريقة الاستماع',
      syncNone: 'السورة كاملة (بدون متابعة)',
      syncAyah: 'متابعة بالآية',
      syncWord: 'متابعة بالكلمة',
      reciter: 'القارئ',
      noTimings: 'لا توجد توقيتات كلمات لهذا القارئ في هذه السورة بعد — المتابعة تتم بالآية.',
      noSurahAudio: 'لا توجد تلاوة كاملة لهذه السورة — اختر المتابعة بالآية',
      fontSize: 'حجم الخط',
      testMode: 'اختبار ذاتي',
      testHint: 'وضع الاختبار: الآيات مخفية — اضغط على آية لكشفها، أو شغّل التلاوة لتنكشف معها.',
      revealPage: 'كشف الصفحة',
      hidePage: 'إخفاء الصفحة',
      prevPage: 'الصفحة السابقة',
      nextPage: 'الصفحة التالية',
      readingSettings: 'إعدادات القراءة',
    ),
    rec: SRec(
      pickGrade: 'اختر تقييم التلاوة',
      pickSurah: 'اختر السورة',
      enterRange: 'أدخل نطاق الآيات',
      rangeOrder: 'آية النهاية يجب أن تكون بعد آية البداية أو تساويها',
      tooFar: 'سورة {v} فيها {v2} آية فقط',
      partial: 'حُفظ {saved}، ولم يُحفظ الباقي: {message}',
      newTitle: 'تسجيل إنجاز يومي',
      editTitle: 'تعديل التسميع',
      prefilled: 'مُعبّأ من جدول المراجعة المقترح — عدّله إن لزم',
      dateToday: 'تاريخ التسميع: اليوم',
      dateV: 'تاريخ التسميع: {year}/{month}/{day}',
      type: 'نوع الإنجاز',
      addSurah: 'إضافة سورة أخرى لنفس الجلسة',
      grade: 'تقييم التلاوة',
      notes: 'ملاحظات الشيخ (اختياري)',
      saveBtn: 'حفظ التسميع',
      saveEdit: 'حفظ التعديل',
      fromAyah: 'من آية',
      toAyah: 'إلى آية',
      maxV: 'الحد {max}',
      searchSurah: 'ابحث باسم السورة أو رقمها',
      ayahsN: '{v} آية',
      absenceFailed: 'تعذّر حفظ الغياب',
      lessonTitle: 'وضع الحصة',
      studentXofY: 'الطالب {v} من {n}',
      plan: 'الخطة المطلوبة منه',
      recordBtn: 'رصد التسميع',
      absent: 'غائب',
      later: 'لاحقًا',
      nobody: 'لا أحد بانتظار التسميع في هذه الحلقة الآن',
      done: 'انتهت الحصة',
      summary: 'سمّع {_recited}  •  غائب {_absent}  •  مؤجَّل {n}',
      anotherRound: 'جولة أخرى على من تبقّى',
      finish: 'إنهاء والعودة',
      circle: 'الحلقة',
      doneToday: 'سمّع اليوم {done} من {total}',
      outboxAttendance: 'حضور {studentName}: {status}',
      outboxRecitation: 'تسميع {studentName} — سورة {surah} ({ayahFrom}–{ayahTo})',
      today: 'اليوم',
      dayMonth: '{day}/{month}',
      addNote: 'إضافة ملاحظة',
      saveWithPoints: 'حفظ التسميع  •  {n}+ نقطة',
      change: 'تغيير',
      wholeSurah: 'السورة كاملة',
    ),
    recite: SRecite(
      rangeTitle: 'تكرار مقطع',
      from: 'من الآية',
      to: 'إلى الآية',
      times: 'مرات المقطع',
      rangeHint: 'يُعاد المقطع من الآية {from} إلى الآية {to}، {times} مرات. تكرار كل آية يبقى كما اخترته.',
      loop: 'المرة {n} من {total}',
      rangeOff: 'إيقاف تكرار المقطع',
      recite: 'سمّع',
      reciteTitle: 'التسميع للنظام',
      reciteHint: 'اختر المقطع، ثم اضغط «ابدأ التسجيل» واقرأ من حفظك. الآيات تُخفى أثناء التسجيل.',
      student: 'الطالب',
      type: 'نوع التسميع',
      start: 'ابدأ التسجيل',
      stop: 'إنهاء التسجيل',
      recording: 'جارٍ التسجيل… اقرأ من حفظك',
      micDenied: 'لم يُسمح باستخدام الميكروفون. اسمح به من إعدادات المتصفح ثم حاول مرة أخرى.',
      micMissing: 'هذا المتصفح لا يدعم التسجيل.',
      tooLong: 'الحد الأقصى للتسجيل {n} دقائق، فقسّم المقطع.',
      uploading: 'جارٍ رفع التسجيل…',
      checking: 'جارٍ فحص التسميع…',
      uploadFailed: 'تعذّر رفع التسجيل، حاول مرة أخرى.',
      result: 'نتيجة التسميع',
      score: 'المطابقة {n}%',
      correct: 'صحيحة',
      missing: 'ناقصة',
      wrong: 'مختلفة',
      extra: 'زائدة',
      legend: 'الكلمات الناقصة بالأحمر، والمختلفة بالبرتقالي على الصفحة.',
      unavailable: 'تعذّر الفحص الآلي الآن. يمكنك إرسال التسجيل للمعلم وسيستمع إليه.',
      autoNote: 'الفحص الآلي تقريبي: يكشف الكلمات الناقصة أو المختلفة، ولا يحكم على التجويد والتشكيل. حكم المعلم هو المعتمد.',
      note: 'ملاحظة للمعلم (اختياري)',
      send: 'أرسل للمعلم',
      sent: 'أُرسل التسميع لمعلمك، وسيصلك إشعار بقراره.',
      again: 'سجّل من جديد',
      cancel: 'إلغاء',
      testStudent: 'اختبار طالب',
      testTitle: 'اختبار طالب في المصحف',
      testHint: 'الآيات مخفية: اضغط على آية لكشفها، ثم اضغط على الكلمة التي أخطأ فيها الطالب لتعليمها، واضغط مرة أخرى لإزالة العلامة.',
      mistakes: 'الأخطاء: {n}',
      grade: 'التقدير',
      save: 'احفظ في سجل الطالب',
      saved: 'حُفظ الاختبار في سجل {name} (+{points} نقطة).',
      chooseStudent: 'اختر الطالب',
      noStudents: 'لا يوجد طلاب يمكنك اختبارهم.',
      badRange: 'المقطع غير صالح.',
      error: 'حدث خطأ، حاول مرة أخرى.',
      myTitle: 'تسميعاتي المسجّلة',
      inboxTitle: 'التسميعات المسجّلة',
      inboxHint: 'تسميعات أرسلها طلاب حلقاتك من المصحف. استمع ثم اعتمد التسميع ليُسجَّل في سجل الطالب، أو أعده بملاحظة.',
      pending: 'بانتظار المراجعة',
      reviewed: 'تمت مراجعتها',
      none: 'لا توجد تسميعات.',
      approve: 'اعتماد',
      reject: 'إعادة',
      rejectNote: 'سبب الإعادة أو ملاحظة للطالب',
      teacherNote: 'ملاحظة المعلم: {note}',
      studentNote: 'ملاحظة الطالب: {note}',
      autoScore: 'الفحص الآلي {n}%',
      noAuto: 'بدون فحص آلي',
      heardAs: 'الكلمات التي اختلفت:',
      missingWords: 'الكلمات الناقصة:',
      openMushaf: 'افتح في المصحف',
      teacherTest: 'اختبار المعلم',
      markedMistakes: 'الأخطاء المعلَّمة: {list}',
      statusDraft: 'لم يُرسل',
      statusSubmitted: 'بانتظار المعلم',
      statusApproved: 'معتمد',
      statusRejected: 'مُعاد',
      reviewedBy: 'راجعه {name}',
      ayahRange: 'سورة {surah} {from}–{to}',
      waitingN: '{n} تسميع مسجّل بانتظار مراجعتك',
      recheck: 'أعد الفحص الآلي',
      testNote: 'ملاحظة (اختياري)',
      micDeniedApp: 'لم يُسمح باستخدام الميكروفون. اسمح به من إعدادات الجهاز ثم حاول مرة أخرى.',
      play: 'استمع',
      apply: 'تطبيق',
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
      sumTitle: 'تقرير {center}',
      sumActive: 'الطلاب النشطون: {students_active}',
      sumPoints: 'النقاط: {points}',
      sumAttendance: 'نسبة الحضور: {v}',
      sumSerd: 'سرد معتمد: {serd_approved}',
      sumRecitations: 'التسميعات: {recitations} ({reciting_students} طالب)',
      sumCircle: '• {name}: {recitations} تسميع، حضور {v}',
    ),
    rplan: SRplan(
      title: 'ورد المراجعة اليومي',
      hint: 'يقترح النظام لكل طالب صفحات المراجعة التالية من محفوظه بالترتيب. اعتمدها بضغطة، وتظهر للطالب وولي أمره.',
      range: 'من {from} إلى {to}',
      ayahRef: '{surah} {ayah}',
      pagesN: '{n} صفحات (ص {a}–{b})',
      approve: 'اعتماد',
      approveAll: 'اعتماد الكل',
      approvedN: 'اعتُمد {n}',
      recite: 'تسميع',
      skip: 'إلغاء',
      status: {'suggested': 'مقترح', 'approved': 'معتمد', 'done': 'سمّعه ✓', 'pending': 'بانتظار الرفع'},
      none: 'لا يوجد طلاب لهم محفوظ بعد',
      cycleStart: 'بداية دورة جديدة',
      today: 'ورد المراجعة اليوم',
      reviewPages: 'صفحات المراجعة اليومية (فارغ = تلقائي)',
      outbox: 'اعتماد مراجعة {name}',
    ),
    serd: SSerd(
      overdueSuffix: '  ·  متأخر',
      inactiveSuffix: '  ·  غير فعّال',
      passSuffix: '  ·  نجاح {n}%',
      wholeJuz: 'الجزء كاملاً',
      noCircle: 'بدون حلقة',
      linkStudent: 'اربط السرد بطالب',
      approved: 'تم الاعتماد',
      rejectTitle: 'رفض السرد',
      rejectReason: 'سبب الرفض (اختياري)',
      reject: 'رفض',
      rejected: 'تم الرفض',
      deleteTitle: 'حذف السرد',
      deleteBody: 'سيُحذف هذا السرد وتُخصم نقاطه إن كان معتمدًا. متأكد؟',
      deleted: 'تم الحذف',
      approve: 'اعتماد',
      reapprove: 'إعادة اعتماد',
      certIssued: 'صدرت الشهادة — تجدها في شاشة الشهادات',
      issueCert: 'إصدار شهادة',
      schedule: 'جدولة سرد',
      report: 'التقرير',
      settings: 'الإعدادات',
      record: 'رصد سرد',
      all: 'الكل',
      pending: 'بانتظار الاعتماد',
      scheduled: 'مجدول',
      approvedChip: 'معتمد',
      rejectedChip: 'مرفوض',
      empty: 'لا يوجد سرد',
      requestedN: 'سرد مطلوب ({n})',
      assigned: 'مخصّص لك',
      openAny: 'عام — أي معلم يستطيع رصده{v}',
      recordShort: 'رصد',
      mine: 'سردي',
      mineEmpty: 'لم ترصد أي سرد بعد. استخدم زر «رصد سرد».',
      saved: 'تم الحفظ',
      wholeAlways: 'الجزء كاملاً (دائمًا)',
      newErrorType: 'نوع خطأ جديد',
      editErrorType: 'تعديل نوع الخطأ',
      name: 'الاسم',
      perErrors: 'كل (عدد أخطاء)',
      deductPct: '= خصم %',
      active: 'فعّال',
      fillAll: 'أكمل الاسم والأرقام',
      stagePortions: 'المقادير المسموحة لهذه المرحلة',
      stagePass: 'حد نجاح خاص % (اتركه فارغًا للعام)',
      settingsTitle: 'إعدادات السرد',
      settingsHint: 'التغييرات تسري على السرد القادم فقط؛ السرد السابق يحتفظ بدرجته ونقاطه وحد نجاحه.',
      general: 'عام للمركز',
      passPct: 'حد النجاح %',
      wholePoints: 'نقاط الجزء الكامل',
      defaultPortions: 'المقادير المسموحة افتراضيًا',
      wholeNumbers: 'أدخل أرقامًا صحيحة',
      saveGeneral: 'حفظ الإعدادات العامة',
      errorTypes: 'أنواع الأخطاء وأوزانها',
      perRule: 'كل {errorsPerUnit} = {percentPerUnit}%{v}',
      byStage: 'حسب المرحلة',
      byStageHint: 'مرحلة الصغار قد تسرد نصف جزء أو ربعه ولها حد نجاح خاص.',
      usesGeneral: 'الإعداد العام',
      pickOrType: 'اختر الطالب أو اكتب اسمه',
      pickPart: 'اختر جزءًا واحدًا على الأقل',
      sentScore: 'أُرسل للاعتماد ✓  الدرجة {score}%',
      saveFailedNet: 'تعذّر الحفظ، تأكد من الإنترنت وحاول مرة أخرى',
      newTitle: 'رصد سرد جديد',
      scheduledTitle: 'رصد سرد مجدول',
      pickStudent: 'اختر الطالب',
      typeName: 'أو اكتب اسم الطالب (من خارج حلقاتك)',
      clearPick: 'إلغاء الاختيار',
      dateLine: 'تاريخ السرد: {year}/{month}/{day}',
      parts: 'الأجزاء المسرودة',
      errors: 'عدد الأخطاء',
      perRule2: 'كل {errorsPerUnit} = {percentPerUnit}%',
      expected: 'الدرجة المتوقعة: {v}%  ·  حد النجاح {passPercent}%',
      notesOpt: 'ملاحظات (اختياري)',
      submit: 'إرسال للاعتماد',
      noResults: 'لا نتائج',
      reportTitle: 'تقرير السرد',
      totalSessions: 'إجمالي الجلسات',
      waiting: 'بانتظار',
      avgScore: 'متوسط الدرجة',
      pointsGiven: 'نقاط ممنوحة',
      approvedParts: 'الأجزاء المعتمدة',
      juzLine: 'جزء {juz} — {v}',
      topErrors: 'أكثر الأخطاء (معتمد)',
      examiners: 'المستمعون',
      partsLine: '{v}  ({v2} جزء)',
      examiner: 'المستمع: {examinerName}',
      circleTeacher: 'معلم الحلقة: {circleTeacherName}',
      assignedTo: 'مسند إلى {assignedTeacherName}',
      openToAny: 'مفتوح لأي معلم',
      noStudent: 'غير مرتبط بطالب',
      scoreLabel: 'الدرجة: ',
      resultLine: '  ·  {v} (حد النجاح {passApplied})  ·  +{pointsAwarded} نقطة',
      rejectReasonV: 'سبب الرفض: {rejectReason}',
      whole: 'كامل',
      pickJuz: 'اختر الجزء',
      juzLine2: 'جزء {juz} — {v}',
      addJuz: 'إضافة جزء آخر',
      passed: 'نجح',
      repeat: 'يعيد',
      pickBoth: 'اختر الطالب وجزءًا واحدًا على الأقل',
      scheduledOk: 'تمت جدولة السرد',
      scheduleHint: 'مهمة تظهر للمعلمين ليرصدها من يتفرغ لها، أو تُسند لمعلم بعينه.',
      student: 'الطالب',
      when: 'الموعد: {year}/{month}/{day}',
      partsWanted: 'الأجزاء المطلوبة',
      assign: 'إسناد إلى معلم',
      scheduleBtn: 'جدولة السرد',
      outboxLabel: 'سرد {studentName} — {n} جزء',
      certDone: 'صدرت الشهادة',
      issueAnother: 'إصدار شهادة أخرى',
    ),
    set: SSet(
      loadSome: 'تعذّر تحميل بعض الإعدادات',
      saved: 'تم حفظ الإعدادات',
      fromGallery: 'من المعرض',
      takePhoto: 'التقاط صورة',
      tooBig1: 'الصورة كبيرة (الحد 1 ميغابايت)',
      logoUploaded: 'تم رفع الشعار — اضغط «حفظ الإعدادات» لتطبيقه في كل مكان',
      logoAdminOnly: 'رفع الشعار للمدير فقط',
      logoFailed: 'تعذّر رفع الشعار',
      logoHttps: 'رابط الشعار يجب أن يبدأ بـ https',
      backdateRange: 'مدة الرجوع بتاريخ التسميع بين 0 و365 يومًا',
      intro: 'كل ما يخص مركزك يمكن تخصيصه من هنا.',
      identity: 'الهوية',
      name: 'اسم المركز',
      uploading: 'جاري الرفع...',
      uploadLogo: 'رفع شعار من الجهاز',
      remove: 'إزالة',
      logoLink: 'أو رابط الشعار (https)',
      primary: 'اللون الأساسي (hex)',
      secondary: 'اللون الثانوي (hex)',
      link: 'رابط المركز',
      timezone: 'المنطقة الزمنية',
      saveIdentity: 'حفظ الهوية',
      workdays: 'أيام الدوام',
      workdaysHint: 'تُحسب نسبة الحضور على أيام الدوام فقط، ويمكن تحديد أيام السرد.',
      working: 'دوام',
      serdDay: 'سرد',
      saveWorkdays: 'حفظ أيام الدوام',
      features: 'إعدادات التسميع والمزايا',
      backdate: 'عدد الأيام المسموح الرجوع إليها بتاريخ التسميع',
      countryCode: 'مفتاح الدولة للجوال (مثل 962)',
      whatsapp: 'رابط مجموعة واتساب',
      locationLabel: 'اسم الموقع (للصلاة والتقويم)',
      lat: 'خط العرض',
      lng: 'خط الطول',
      method: 'طريقة حساب الصلاة',
      madhab: 'المذهب (shafi / hanafi)',
      reciters: 'القرّاء في المصحف',
      recitersHint: 'اترك الاختيار فارغًا لإتاحة كل القرّاء.',
      defaultReciter: 'القارئ الافتراضي',
      firstInList: 'الأول في القائمة',
      market: 'تفعيل متجر النقاط',
      tabs: {'identity': 'الهوية', 'workdays': 'أيام الدوام', 'features': 'الميزات', 'contact': 'التواصل والصلاة', 'quran': 'المصحف', 'notif': 'الإشعارات'},
      quranTitle: 'المصحف والقرّاء',
      prayerMethods: {'umm_al_qura': 'أم القرى', 'muslim_world_league': 'رابطة العالم الإسلامي', 'egyptian': 'الهيئة المصرية', 'karachi': 'كراتشي', 'dubai': 'دبي', 'qatar': 'قطر', 'kuwait': 'الكويت', 'moon_sighting_committee': 'لجنة رؤية الهلال', 'singapore': 'سنغافورة', 'turkey': 'تركيا', 'tehran': 'طهران', 'north_america': 'أمريكا الشمالية'},
      majority: 'الجمهور (شافعي/مالكي/حنبلي)',
      hanafi: 'حنفي',
      fees: 'تفعيل رسوم الطلاب (للمراكز غير المجانية)',
      leaderboard: 'تفعيل لوحة الصدارة',
      teacherStudents: 'السماح للمعلم بإدارة طلاب حلقته',
      saveSettings: 'حفظ الإعدادات',
      adminOnly: 'بس المدير يقدر يعدّل إعدادات المركز.',
      loadOne: 'تعذّر تحميل الإعداد',
      digestTitle: 'ملخص الأسبوع للأسر',
      digestHint: 'إشعار أسبوعي لكل أسرة: ما سمّع ابنها وحضوره ونقاطه، بتوقيت المركز.',
      digestEnable: 'تفعيل الملخص الأسبوعي',
      day: 'اليوم',
      hour: 'الساعة',
      digestSaved: 'حُفظ إعداد الملخص الأسبوعي',
      saveFailed: 'تعذّر الحفظ',
      digestSub: 'اليوم والساعة وتفعيله',
      attTitle: 'تذكير المعلم بالحضور',
      attHint: 'في أيام الدوام، بعد الساعة المحددة، يصل المعلم تذكير واحد إن لم يُسجَّل حضور حلقته.',
      attEnable: 'تفعيل التذكير',
      afterHour: 'بعد الساعة',
      attSaved: 'حُفظ إعداد التذكير',
      attTitle2: 'تذكير المعلم بتسجيل الحضور',
      attSub: 'تفعيله والساعة',
      language: 'لغة المركز الافتراضية',
      languageHint: 'تظهر بها الشاشات لمن لم يختر لغة بنفسه. يستطيع كل شخص تغييرها لنفسه من القائمة.',
    ),
    stu: SStu(
      status: {'active': 'نشط', 'paused': 'متوقف', 'graduated': 'تخرّج', 'withdrawn': 'منسحب'},
      noCircle: 'بدون حلقة',
      deleteTitle: 'حذف الطالب',
      deleteBody: 'سيتم حذف "{fullName}" وكل ملفه (الحضور، السرد، النقاط...). لا يمكن التراجع.',
      title: 'الطلاب',
      add: 'إضافة طالب',
      searchPh: 'ابحث بالاسم أو رقم الطالب',
      empty: 'لا يوجد طلاب بعد',
      emptyHint: 'ابدأ بإضافة أول طالب من الزر بالأسفل',
      noMatch: 'لا نتائج مطابقة',
      editDetails: 'تعديل البيانات',
      deleteWithFile: 'حذف الطالب وملفه',
      circleRequired: 'يجب اختيار حلقة للطالب',
      accountCreated: 'تم إنشاء حساب الطالب',
      codeTaken: 'رقم الطالب مستخدم من قبل بهذا المركز',
      saveError: 'حدث خطأ أثناء الحفظ',
      deleteBodyPlain: 'سيتم حذف الطالب وكل ملفه (الحضور، السرد، النقاط...). لا يمكن التراجع.',
      editTitle: 'تعديل بيانات طالب',
      details: 'بيانات الطالب',
      fullName: 'الاسم الكامل',
      nameRequired: 'أدخل اسم الطالب',
      birthDate: 'تاريخ الميلاد (اختياري)',
      tapToPick: 'اضغط للاختيار',
      stageCircle: 'المرحلة والحلقة',
      stage: 'المرحلة',
      allStages: 'كل المراحل',
      circleReq: 'الحلقة (مطلوب)',
      noCircles: 'لا توجد حلقات هنا - أنشئ حلقة أولًا من قسم الحلقات',
      code: 'رقم الطالب',
      codeHint: 'يُقترح تلقائيًا عند اختيار المرحلة، ويمكنك تعديله',
      codeRequired: 'أدخل رقم الطالب',
      contact: 'بيانات التواصل',
      phone: 'رقم الجوال (اختياري)',
      whatsapp: 'رقم الواتساب (اختياري)',
      address: 'العنوان (اختياري)',
      login: 'حساب دخول الطالب',
      password: 'كلمة السر',
      passwordHint: 'اتركها فارغة لإنشاء الملف بدون حساب دخول',
      min8: '8 خانات على الأقل',
      email: 'بريد إلكتروني حقيقي (اختياري)',
      emailHint: 'بدونه يدخل الطالب برقمه مع رمز المركز',
      statusLabel: 'الحالة',
      saveChanges: 'حفظ التعديلات',
      addBtn: 'إضافة الطالب',
      recEdited: 'تم تعديل التسميع',
      recDeleteTitle: 'حذف التسميع',
      recDeleteBody: 'سيُحذف هذا التسميع وتُخصم نقاطه من رصيد الطالب. هل أنت متأكد؟',
      deleted: 'تم الحذف',
      nextPlan: 'الخطة القادمة',
      planPh: 'مثال: حفظ سورة الملك من الآية 1 إلى 15',
      planSaved: 'تم حفظ الخطة',
      linkUpdated: 'تم تحديث الربط',
      pickGuardian: 'اختر ولي الأمر',
      noGuardians: 'لا يوجد أولياء أمور بعد',
      newGuardian: 'حساب ولي أمر جديد',
      guardianName: 'اسم ولي الأمر',
      loginId: 'رقم الدخول أو البريد',
      phoneOpt: 'الجوال (اختياري)',
      password8: 'كلمة السر (8 أحرف على الأقل)',
      create: 'إنشاء',
      guardianIncomplete: 'أكمل الاسم ورقم الدخول وكلمة سر من 8 أحرف على الأقل',
      guardianCreated: 'تم إنشاء حساب ولي الأمر',
      allRecitations: 'كل التسميعات',
      streak: 'سلسلة الأيام',
      weeklyAttendance: 'الحضور الأسبوعي',
      lastRecitation: 'آخر تسميع',
      surahV: 'سورة {v}',
      recLine: '{type} • من آية {ayahFrom} إلى {ayahTo}',
      progress: 'التقدّم',
      partsOf30: '{totalParts} من 30 جزءًا',
      weeklyAttendanceV: 'الحضور الأسبوعي: {v}',
      statsLine: '{totalRecitations} تسميعات  ·  سلسلة {currentStreak} يوم (الأطول {longestStreak})  ·  آخر تسميع {v}',
      noPlan: 'لم تُحدَّد خطة بعد',
      sheikh: 'الشيخ',
      phone2: 'الجوال',
      addressLabel: 'العنوان',
      guardian: 'ولي الأمر',
      noGuardian: 'لا يوجد ولي أمر مرتبط',
      linkedTo: 'المرتبط: {v}',
      newAccount: 'حساب جديد',
      linkExisting: 'ربط بموجود',
      unlink: 'فك الربط',
      log: 'سجل التسميع',
      noRecitations: 'لا يوجد تسميعات بعد',
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
      offlineTitle: 'العمل دون اتصال',
      offlineHint: 'يُنزَّل على هذا الجهاز كل ما تحتاجه: حلقاتك وطلابك وسجلاتهم والسرد والتقويم والرسائل، فيعمل التطبيق دون إنترنت، وما تسجّله يُرفع تلقائيًا عند عودة الاتصال.',
      offlineProgress: 'جاري التنزيل… {done} من {total}',
      offlineNever: 'لم تُنزَّل البيانات على هذا الجهاز بعد',
      offlineLast: 'آخر تنزيل: {time}',
      offlineNow: 'تنزيل البيانات الآن',
      offlineNeedsNet: 'يحتاج اتصالًا بالإنترنت',
    ),
    teach: STeach(
      greeting: '{v}، {v2}',
      findStudent: 'بحث عن طالب',
      noCircle: 'لم يتم تعيينك لأي حلقة بعد',
      noCircleHint: 'اطلب من المشرف إضافتك إلى حلقة، ثم اسحب للأسفل للتحديث.',
      yourCircles: 'حلقاتك ({n})',
      checkedIn: 'سُجّل حضورك ✓',
      checkInFailed: 'تعذّر تسجيل الحضور — تحقّق من الاتصال',
      circleScreen: 'شاشة الحلقة',
      assistant: 'معلم مساعد',
      stage: 'المرحلة: {stageName}',
      doneOf: 'سمّع {done} من {n}',
      checkIn: 'سجّل حضوري اليوم',
      startLesson: 'ابدأ الحصة',
      savedPoints: 'تم الحفظ ✓  +{points} نقطة',
      attendanceFailed: 'تعذّر حفظ الحضور',
      noStudents: 'لا يوجد طلاب في هذه الحلقة بعد.\nاطلب من المشرف إضافة الطلاب إليها.',
      searchPh: 'ابحث باسم الطالب أو رقمه',
      all: 'الكل',
      notToday: 'لم يسمّع اليوم',
      recitedToday: 'سمّع اليوم',
      sort: 'ترتيب القائمة',
      alpha: 'أبجديًا',
      notFirst: 'من لم يسمّع أولًا',
      topPoints: 'الأعلى نقاطًا',
      xOfY: '{n} من {n2}',
      noMatch: 'لا يطابق أحد ما اخترته.',
      showAll: 'إظهار كل الطلاب',
      pointsN: '{totalPoints} نقطة',
      recitedTodayN: 'سمّع اليوم ×{recitedToday}',
      dueReviews: 'مراجعة مستحقة ({n})',
      takeAttendance: 'تسجيل حضور',
      attendanceIs: 'حضور: {value}',
      record: 'رصد تسميع',
      general: 'عامة',
    ),
    ui: SUi(
      credsText: 'رمز المركز: {centerCode}\nالرقم / البريد: {loginId}\nكلمة السر: {password}',
      credsOnce: 'هذا العرض الوحيد لكلمة السر - انسخها الآن وسلّمها.',
      copied: 'تم النسخ',
      copy: 'نسخ',
      done: 'تم',
      skeletonTitle: 'اسم الطالب الكامل هنا',
      skeletonSub: 'معلومات إضافية قصيرة',
      add: 'إضافة',
      search: 'بحث',
      noMatch: 'لا نتائج مطابقة',
      channelName: 'إشعارات بستان القرآن',
      channelDesc: 'الرسائل والتذكيرات والاعتمادات',
      sessionEnded: 'انتهت الجلسة، سجّل الدخول من جديد',
      requestFailed: 'تعذّر تنفيذ الطلب',
      savedOffline: 'حُفظ على جهازك وسيُرفع تلقائيًا عند عودة الاتصال',
      outboxCheckIn: 'تسجيل حضوري في الحلقة',
      outboxNote: 'ملاحظة على طالب',
      outboxGathering: 'نشاط: {title}',
      outboxExternal: 'تسميع خارجي: {name}',
      outboxEditRecitation: 'تعديل تسميع',
      outboxDeleteRecitation: 'حذف تسميع',
      outboxPlan: 'الخطة القادمة لطالب',
      waitingUpload: 'بانتظار الرفع',
    ),
    weekly: SWeekly(
      smartToggle: 'التقرير الأسبوعي الذكي',
      smartHint: 'يضيف: هدف الحفظ، متقدم أو متأخر، المقارنة مع الأسبوع الماضي، وملاحظة المعلم',
      title: 'التقرير الأسبوعي',
      period: 'من {from} إلى {to}',
      thisWeek: 'هذا الأسبوع',
      lastWeek: 'الماضي',
      recitations: 'التسميعات',
      newPages: 'صفحات حفظ جديدة',
      reviews: 'مراجعات',
      points: 'النقاط',
      attendance: 'الحضور',
      attV: '{present} من {days}',
      teacherNote: 'ملاحظة المعلم',
      noNote: 'لا ملاحظة من المعلم هذا الأسبوع',
      nextPlan: 'المطلوب للأسبوع القادم',
      open: 'التقرير الأسبوعي',
    ),
    wird: SWird(
      title: 'ورد اليوم',
      newPart: 'حفظ جديد',
      reviewPart: 'مراجعة',
      fromTeacher: 'حدّده معلمك',
      suggested: 'مقترح',
      done: 'تمّ',
      sent: 'أُرسل للمعلم',
      todo: 'لم يُسمَّع بعد',
      recite: 'سمّع الآن',
      open: 'افتح في المصحف',
      complete: 'أتممت ورد اليوم، بارك الله فيك',
      none: 'لا يوجد ورد بعد: يظهر بعد أول تسميع حفظ جديد في سجلك.',
      dayOff: 'اليوم ليس يوم دوام في المركز، والورد اختياري.',
      pages: '{n} صفحة',
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
    attn: SAttn(
      title: 'Students needing attention',
      hint: 'Most urgent first: behind their goal, not reciting, often absent.',
      none: 'Nobody needs special attention right now 🌿',
      behind: 'Behind their goal by {pages} pages',
      idle: 'Has not recited for {days} working days',
      never: 'Has never recited',
      absences: 'Absent {count} times in two weeks',
      all: 'All',
      filterBehind: 'Behind goal',
      filterIdle: 'Not reciting',
      filterAbsent: 'Absences',
      recite: 'Recite',
      call: 'Call',
      lastRecited: 'Last recitation: {v}',
      count: '{n} students',
    ),
    auth: SAuth(
      thisCenter: 'this center',
      noCenter: 'We found no center with this code; check it and try again',
      badLogin: 'The sign-in number / email or password is wrong',
      notMember: 'This account isn’t registered at {v}',
      serverDown: 'Couldn’t reach the server; check the internet and try again',
      codeFirst: 'Enter the center code first',
      openFailed: 'Couldn’t open the page; try from the browser',
      signInTitle: 'Sign in to your center',
      step1: '1. The center',
      centerCode: 'Center code',
      enterCode: 'Enter the center code',
      noCenterShort: 'No center with this code',
      codeHint: 'The center code is the first part of your center’s link, e.g. eqraa from eqraa.bustan-alquran.com',
      step2: '2. Your account',
      loginId: 'ID / student number or email',
      enterId: 'Enter your number or email',
      password: 'Password',
      enterPassword: 'Enter the password',
      forgot: 'Forgot your password?',
      signInTo: 'Sign in to {name}',
      signIn: 'Sign in',
      whoHint: 'Sign-in for teachers, admins, guardians and students, each with their access in the center.',
      confirmEmail: 'Check your email to confirm the account first, then open the invitation link again to finish joining',
      joinFailed: 'Couldn’t finish joining; check the internet and try again',
      joinTitle: 'Join a center',
      invalidInvite: 'Invalid invitation',
      invalidBody: 'It has expired or was already used. Ask the center admin for a new one.',
      inviteFrom: 'Invitation from {organization_name}',
      asRole: 'To join as {role}',
      signedInAs: 'Signed in as {email}',
      confirmJoin: 'Confirm joining',
      inviteEmail: 'Email (from the invitation)',
      yourPassword: 'Your account password',
      createPassword: 'Create a password (at least 8 characters)',
      signInJoin: 'Sign in and join',
      createJoin: 'Create the account and join',
      noAccount: 'I don’t have an account',
      haveAccount: 'I already have an account',
      ob1: 'Record recitation and memorization',
      ob1Body: 'Every circle, every student, every page memorized or reviewed — one tap from the teacher, with the grade and date always kept.',
      ob2: 'Stay in touch with the center',
      ob2Body: 'Messages, announcements and instant notifications between admins, teachers, students and guardians — each center private.',
      ob3: 'Points and badges that keep them going',
      ob3Body: 'Every recitation earns points and every milestone a badge — a small market and circle challenges make memorizing a daily habit they love.',
      openSignup: 'Open {_signupUrl} in your browser to register a new center',
      skip: 'Skip',
      signInBtn: 'Sign in',
      next: 'Next',
      registerCenter: 'Register a new center on the website ↗',
      pickCenter: 'Choose the center',
      noCenters: 'Your account isn’t linked to any center yet',
      noCentersHint: 'Ask the center admin to invite you, or sign in with another account',
    ),
    badgesStaff: SBadgesStaff(
      rules: {'manual': 'Manual (given by the supervisor)', 'points_threshold': 'Reaching a points total', 'recitations_count': 'Number of recitations', 'grade_count': 'Recitations with a given grade', 'streak_days': 'Days in a row with a recitation', 'weekly_attendance': 'Weekly attendance rate', 'juz_complete': 'Completing a whole juz in serd', 'serd_passed_count': 'Number of passed serd'},
      manual: 'manual',
      auto: 'automatic',
      expiresSuffix: '  ·  expires {date}',
      nameRequired: 'The badge name is required',
      pickStudent: 'Choose the student',
      awarded: 'Badge given',
      pickCircle: 'Choose the circle',
      awardedN: 'Given to {n} students',
      deleteTitle: 'Delete badge',
      deleteBody: 'It is removed from every student. Are you sure?',
      newTitle: 'New badge',
      badge: 'Badge',
      icon: 'Icon',
      name: 'Name',
      description: 'Description',
      rule: 'Rule',
      threshold: 'Condition value',
      juzNo: 'Juz number (1–30)',
      percent: 'Percentage (1–100)',
      count: 'Count needed',
      grade: 'Grade',
      duration: 'Badge duration in days (empty = permanent)',
      active: 'Active',
      giveManually: 'Give the badge by hand',
      toStudent: 'To a student',
      toCircle: 'To a whole circle',
      holdersN: 'Holders ({n})',
      noHolders: 'Not given to anyone yet',
      revoked: 'Badge taken back',
      revoke: 'Take back',
      reevaluate: 'Re-check everyone',
      reevaluated: 'Badges re-checked for every student',
      intro: 'Automatic badges are given as soon as their condition is met. Manual ones are given by the supervisor, or by a teacher to their circle’s students.',
      empty: 'No badges yet',
      expiresAfter: 'Expires after {durationDays} days',
      inactive: 'Inactive',
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
      withReg: ' — with registration',
      notWorking: ' — not a working day',
      workingDay: 'Working day',
      notWorkingDay: 'Not a working day',
      pickTypeTitle: 'Choose the type and write the title',
      deleteBody: 'This item and all its registrations will be deleted. Are you sure?',
      addTitle: 'Add to the calendar',
      type: 'Type',
      titleField: 'Title',
      description: 'Description',
      fromV: 'From: {v}',
      toV: 'To: {v}',
      timeOpt: 'Time (optional)',
      place: 'Place',
      whoSees: 'Who sees it',
      audienceLabel: 'Audience',
      oneCircle: 'A specific circle',
      allCircles: 'All circles',
      oneStage: 'A specific stage',
      allStages: 'All stages',
      workingSection: 'Working day',
      overrideType: 'Override the type’s setting',
      typeMakes: 'The type makes it: {v}',
      offDaysHint: 'Non-working days don’t count toward students’ attendance rate.',
      registrationSection: 'Registration',
      seats: 'Seats (empty = unlimited)',
      closesAt: 'Registration closes: {v}',
      removeDeadline: 'Remove the deadline',
      open: 'Registration open',
      saved: 'Saved',
      newType: 'New type',
      editType: 'Edit type',
      name: 'Name',
      hasRegistration: 'Takes registrations',
      needsGuardian: 'Needs guardian consent',
      active: 'Active',
      typeNameRequired: 'The type name is required',
      typesTitle: 'Calendar item types',
      typesHint: 'Earlier items keep their type’s settings from when they were added, so editing a type doesn’t change old attendance rates.',
      working: 'Working',
      guardianConsent: 'Guardian consent',
      inactive: 'Inactive',
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
    cfeat: SCfeat(
      names: {'students': 'Students', 'circles': 'Circles', 'attendance': 'Attendance & gatherings', 'serd': 'Quran serd', 'points': 'Points', 'badges': 'Badges', 'market': 'Points market', 'circle-challenges': 'Circle challenges', 'activities': 'Activities', 'calendar': 'Calendar', 'announcements': 'Announcements', 'chat': 'Messages', 'notifications': 'Notifications', 'reports': 'Reports', 'certificates': 'Certificates', 'fees': 'Student fees', 'quran': 'Mushaf', 'recitations': 'Recorded and live recitation', 'wird': 'Daily portion and its reminder', 'garden_tree': 'The growing tree'},
      tab: 'Center features',
      title: 'Features the center uses',
      hint: 'Switch off what your center does not need and it disappears from everyone’s menus; switch it back on any time. What is available here is what your plan includes.',
      notInPlan: 'Not in your plan',
      save: 'Save features',
      saved: 'Center features saved',
      off: 'This feature is switched off in your center.',
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
    dash: SDash(
      takeAttendance: 'Take attendance',
      addStudent: 'Add student',
      serdSession: 'Serd session',
      newAnnouncement: 'New announcement',
      calendar: 'Calendar',
      title: 'Dashboard',
      greeting: '{v} — assalamu alaykum',
      yourCirclesToday: 'Your circles today',
      noCircle: 'You haven’t been assigned to a circle yet — ask the supervisor to add you.',
      notWorkingDay: 'Today isn’t a working day at your center',
      studentsN: '{students} students',
      recitedN: 'Recited {recited}',
      presentN: 'Present {present}',
      absentN: 'Absent {absent}',
      students: 'Students',
      teachers: 'Teachers',
      circles: 'Circles',
      todayAttendance: 'Today’s attendance',
      shortcuts: 'Quick shortcuts',
      centerAdmin: 'Center admin',
      waitSerd: 'Serd awaiting approval',
      waitMarket: 'Market requests awaiting a decision',
      waitGatherings: 'Gatherings with names to link',
      waitExternal: 'External recitations to link',
      needsYou: 'Needs your attention',
      nothingWaiting: 'Nothing is waiting for you ✓',
      inactiveN: 'No recitation for two weeks ({inactive_total})',
      thisWeek: 'This week',
      weekRecitations: '{recitations} recitations',
      weekReciting: '{reciting_students} students recited',
      weekPoints: '{points} points',
      weekAttendance: 'Attendance {v}',
      upcomingEvents: 'Upcoming events',
      notYet: 'Hasn’t recited yet',
      registered: 'registered',
      dropoutRisk: 'Dropout risk',
      noRisk: 'No student at risk of dropping out ✓',
      teacherPerf: 'Teacher activity (7 days)',
      recitationsWord: 'recitations',
      riskTags: {'never': 'Never recited', 'regressed': 'Stopped after being regular', 'slowing': 'Slowing down', 'attendance_gap': 'Attends but doesn’t recite'},
      idleDays: '{n} working days',
      perfLine: '{circles} circles · {students} students · present {days} days',
    ),
    fees: SFees(
      title: 'Fees',
      collectedMonth: 'Collected this month',
      outstanding: 'Owed by students',
      owingN: 'Owing',
      filter: {'all': 'All', 'owing': 'Owing', 'noPlan': 'No plan'},
      search: 'Search by student name or number',
      none: 'No students',
      exempt: 'Exempt',
      discountV: '{n}% off',
      noPlan: 'No plan',
      owes: 'Owes',
      credit: 'In credit',
      settled: 'Nothing due',
      dueSoFar: 'Due so far',
      paidTotal: 'Paid',
      upcoming: 'Coming up',
      plan: 'Plan: {name}',
      periods: {'monthly': 'Monthly', 'term': 'Per term', 'once': 'One-off'},
      recordTitle: 'Record a payment',
      amount: 'Amount',
      amountInvalid: 'Enter a valid amount',
      method: 'Method',
      methods: {'cash': 'Cash', 'transfer': 'Transfer', 'card': 'Card', 'wallet': 'E-wallet', 'other': 'Other'},
      paidOn: 'Payment date: {date}',
      note: 'Note (optional)',
      record: 'Record payment',
      recorded: 'Payment recorded ✓',
      outbox: 'Payment {name}: {amount}',
      pendingUpload: 'Waiting to upload',
      charges: 'Charges',
      payments: 'Payments',
      status: {'open': 'Due', 'waived': 'Waived', 'cancelled': 'Cancelled'},
      notYetDue: 'Not yet due',
      waive: 'Waive',
      cancelCharge: 'Cancel charge',
      reopen: 'Reopen',
      cancelChargeConfirm: 'Cancel this charge? (for a mistake; to forgive it use “Waive”)',
      receiptNo: 'Receipt no. {n}',
      receiptTitle: 'Payment receipt',
      voidPayment: 'Void payment',
      voidReason: 'Reason (optional)',
      voidConfirm: 'Void this payment? The receipt stays on record, stamped “Void”.',
      voided: 'Void',
      noCharges: 'No charges',
      noPayments: 'No payments',
      balanceAfter: 'Student’s remaining balance',
      byLabel: 'Received by',
      share: 'Share',
      receiptText: '{center}\n{title} — {no}\n{student}\n{amount} · {date} · {method}\n{left}',
      manageOnWeb: 'Plans, assigning them to students, settings and the report are on the website dashboard.',
      adminOnly: 'Only the admin manages fees',
      openAccount: 'Fees account',
    ),
    garden: SGarden(
      online: 'Online',
      offline: 'Offline',
      noInternet: 'Network has no internet',
      syncCenter: 'Sync center',
      offlineWaiting: 'Offline · {n} waiting',
      syncing: 'Uploading',
      waitingN: '{n} waiting',
      failedN: '{n} not uploaded',
      tabHome: 'Home',
      tabStudents: 'Students',
      tabSerd: 'Serd',
      tabChat: 'Messages',
      tabMore: 'More',
      seeAll: 'See all',
      moreTitle: 'All sections',
      checkedInShort: 'Checked in',
      checkInShort: 'Check in',
      studentsN: 'Students ({n})',
      statCircles: 'Circles',
      statStudents: 'Students',
      statRecited: 'Recited',
      statPresent: 'Present',
      quickTitle: 'Shortcuts',
      account: 'Account',
      notificationPrefs: 'Notification preferences',
      statJuz: 'Juz',
      statPoints: 'Points',
      statStreak: 'Day streak',
      explore: 'Explore',
      statAttendance: 'Attendance',
      itemsN: '{n} items',
    ),
    gather: SGather(
      noCircle: 'No circle',
      okLinked: 'Name linked',
      skippedSuffix: ' · {n} skipped',
      actionFailed: 'That didn’t go through — check your connection',
      extNew: 'External recitation',
      studentName: 'Student name',
      type: 'Type',
      surah: 'Surah',
      fromAyah: 'From ayah',
      toAyah: 'To ayah',
      grade: 'Grade',
      extUpload: 'Upload recitation',
      extUploaded: 'Recitation uploaded; waiting for the supervisor to link it',
      extLinked: 'Recitation linked and recorded for the student (+{v} points)',
      rejectTitle: 'Reject the request',
      reasonOpt: 'Reason (optional)',
      reject: 'Reject',
      rejected: 'Request rejected',
      extNewShort: 'New recitation',
      noRequests: 'No requests yet',
      linked: 'Linked',
      rejectedChip: 'Rejected',
      pending: 'Waiting to be linked',
      linkedTo: 'Linked to {matched_name}',
      reasonV: 'Reason: {reject_reason}',
      pickStudent: 'Choose a student',
      deletedReq: 'Request deleted',
      linkedAttended: 'Name linked and the student’s attendance recorded',
      addName: 'Add a name',
      name: 'Name',
      add: 'Add',
      nameAdded: 'Name added',
      activity: 'Activity',
      metaLine: '{session_date}{v}{v2} · uploaded by {v3}',
      namesN: 'Names ({n})',
      nameDeleted: 'Name removed',
      linkedLine: 'Linked: {matched_name} ({matched_code}){v}',
      skipped: 'Skipped',
      skip: 'Skip',
      nameSkipped: 'Name skipped',
      unlink: 'Unlink',
      uploadNew: 'Upload a new activity',
      activityName: 'Activity name',
      activityType: 'Activity type',
      none: '— None —',
      placeOpt: 'Place (optional)',
      attendees: 'Attendees — one name per line',
      uploadBtn: 'Upload activity',
      uploadedN: 'Activity uploaded with {n} names',
      uploadFailed: 'Upload failed — check your connection',
      upload: 'Upload activity',
      empty: 'No activities uploaded yet',
      countsLine: '{total} names · {matched} linked{v}',
      reviewed: 'Reviewed',
      pendingN: 'Waiting ({pending})',
      waitingAdmin: 'Waiting for the supervisor',
      pickStudentTitle: 'Choose the student',
      searchPh: 'Student name or number',
    ),
    ins: SIns(
      guardianVisibleSuffix: ' · visible to the guardian',
      overdueSuffix: ' · {n} days overdue',
      noCircle: 'No circle',
      auditActions: {'delete': 'Deleted', 'update': 'Edited', 'create': 'Added'},
      auditTables: {'students_profile': 'student', 'circles': 'circle', 'stages': 'stage', 'serd_sessions': 'serd session', 'organization_members': 'member'},
      newNote: 'New note',
      notePh: 'e.g. rushes at the ends of ayahs',
      guardianVisible: 'Visible to the guardian',
      noteFailed: 'Couldn’t save the note',
      notesTitle: 'Teacher’s notes',
      noNotes: 'No notes yet',
      searchFailed: 'Search failed. Check your connection.',
      searchPh: 'Search: student, student number, teacher, circle',
      noResults: 'No results',
      students: 'Students',
      staff: 'Teachers & admins',
      admin: 'Admin',
      teacher: 'Teacher',
      circles: 'Circles',
      reviewsTitle: 'Suggested review today',
      noReviews: 'No reviews due today ✓',
      reviewsHint: 'Each surah comes back after a gap that grows with good grades and drops to one day with weak ones.',
      challengeTitleRequired: 'The challenge title is required',
      newChallenge: 'New challenge',
      editChallenge: 'Edit challenge',
      title: 'Title',
      description: 'Description',
      metric: 'Measure',
      deleteChallenge: 'Delete challenge',
      sure: 'Are you sure?',
      challenge: 'Challenge',
      noCircles: 'No circles with students yet',
      boardLine: '{students} students  ·  total {total}',
      noChallenges: 'No challenges',
      noAudit: 'No actions recorded yet',
      auditHint: 'Sensitive deletions and edits show up here',
    ),
    live: SLive(
      title: 'Recite',
      hint: 'Choose the surah and the passage, then start: the ayahs are hidden and each word appears when you say it right. If you forget or get a word wrong, it stops and tells you.',
      student: 'Student',
      surah: 'Surah',
      type: 'Type',
      from: 'From ayah',
      to: 'To ayah',
      start: 'Start',
      unsupported: 'This browser can’t follow a recitation live. Use Chrome or Edge, or the Bustan Al-Quran app.',
      micDenied: 'Microphone access was not allowed. Allow it in the settings and try again.',
      network: 'Speech recognition needs an internet connection.',
      listening: 'Listening… recite from memory',
      paused: 'Paused',
      progress: '{n} of {total} words',
      mistakesN: 'Mistakes: {n}',
      stopMissing: 'Stop: a word was forgotten',
      stopWrong: 'Stop: a word was wrong',
      correctIs: 'Correct:',
      heard: 'I heard: {w}',
      resume: 'Continue',
      forgot: 'I don’t remember',
      finish: 'Finish and send',
      result: 'Result',
      score: '{n}% correct',
      mistakeList: 'Words with mistakes:',
      resultNote: 'The result comes from your device’s speech recognition; your teacher approves the recitation.',
      note: 'Note for the teacher (optional)',
      send: 'Send to the teacher',
      sending: 'Sending…',
      sent: 'Sent to your teacher. You will be notified of the decision.',
      again: 'Recite again',
      appAudio: 'Your voice is recorded from the start and sent with the result for your teacher to hear.',
      recording: 'Recording',
      withAudio: 'Recording attached ({t})',
      retry: 'Send again',
      notSent: 'The recitation was not sent yet. Check the connection and tap “Send again”.',
      nothingHeard: 'Nothing of the recitation was heard, so it was not sent. Check the microphone and recite again.',
      mine: 'My recitations',
      error: 'Something went wrong. Try again.',
      fab: 'Recite',
      liveBadge: 'Live recitation',
      loading: 'Loading the ayahs…',
      appNoAudio: 'In the app the recitation is sent with its result, without a recording.',
      appUnsupported: 'Speech recognition is not available on this device. Install the Google app or turn on speech recognition in the device settings.',
    ),
    mem: SMem(
      modules: {'students': 'Students', 'circles': 'Circles', 'attendance': 'Attendance', 'serd': 'Quran serd & recitation requests', 'points': 'Points', 'badges': 'Badges', 'market': 'Points market', 'circle-challenges': 'Circle challenges', 'activities': 'Activities', 'calendar': 'Calendar', 'announcements': 'Announcements', 'chat': 'Messages', 'notifications': 'Notifications', 'reports': 'Reports', 'certificates': 'Certificates'},
      status: {'active': 'Active', 'invited': 'Invited', 'suspended': 'Suspended'},
      password8: 'The password must be at least 8 characters',
      passwordChanged: 'Password changed',
      accountSaved: 'Account status saved',
      removeTitle: 'Remove from the center',
      removeBody: 'Remove “{fullName}” from the center? They lose all their access here right away.',
      editTitle: 'Edit member',
      selfNote: 'You can’t change or remove your own access here — ask another admin if there is one.',
      role: 'Role',
      statusLabel: 'Status',
      modulesTitle: 'Sections they can access',
      viewOnly: 'View-only account',
      viewOnlyHint: 'Sees but can’t change: their role stays the same, but none of their changes are saved in this center.',
      changePassword: 'Change password',
      newPassword: 'New password (at least 8 characters)',
      teacherCreated: 'Teacher account created',
      newTeacher: 'New teacher',
      teacherHint: 'The teacher signs in with the center code + their number (or email) + the password.',
      required: 'Required',
      loginId: 'Sign-in number or email',
      min8: 'At least 8 characters',
      createAccount: 'Create the account',
      inviteCreated: 'Invitation created',
      inviteError: 'Something went wrong with the invitation',
      inviteTitle: 'Invite a new member',
      email: 'Email',
      inviteBtn: 'Create invitation',
      pendingInvites: 'Invitations not accepted yet',
      contactTitle: 'Contact',
      contactHint: 'Preferably with the country code, e.g. +962791234567',
    ),
    mistakes: SMistakes(
      title: 'Recurring mistakes',
      hint: 'From the teacher\'s tests in the mushaf and the automatic checks of recorded recitations, over the last {days} days. Focus on them when reviewing.',
      summary: '{sessions} recitations · {mistakes} mistakes',
      bySurah: 'By surah',
      byAyah: 'Ayahs with the most mistakes',
      byWord: 'Words with the most mistakes',
      times: '×{n}',
      none: 'No mistakes recorded in this period.',
      ayah: '{surah} : {ayah}',
    ),
    mkt: SMkt(
      rateTitle: 'Points exchange rate',
      perPoints: 'Every (points)',
      equals: '= (value)',
      currency: 'Currency symbol',
      rateHint: 'The change applies only to points converted from now on; earlier conversions keep their value.',
      rateInvalid: 'Enter whole numbers and a currency symbol',
      rateSaved: 'Rate saved',
      cancelOrder: 'Cancel the order',
      cancelOrderBody: 'The balance and stock will be returned. Are you sure?',
      no: 'No',
      yes: 'Yes',
      orderCancelled: 'Order cancelled',
      newItem: 'New item',
      adminOnly: 'Only the admin manages the market',
      items: 'Items',
      ordersN: 'Orders ({pending})',
      orders: 'Orders',
      balances: 'Balances',
      noOrders: 'No orders',
      delivered: 'Delivered',
      walletLine: '{earnedPoints} points  ·  spent {v}',
      disabled: 'The market is off right now (turn it on in the center settings)',
      rateLine: 'Every {pointsPerUnit} points = {v}',
      rateSub: 'Points-to-currency exchange rate',
      noItems: 'No items yet',
      unlimited: 'Unlimited stock',
      stockN: 'Stock: {n}',
      inactiveSuffix: '  ·  inactive',
      nameRequired: 'The name and price are required',
      noUpload: 'You can’t upload images',
      uploadFailed: 'Could not upload the image',
      tooBig3: 'The image is too big (3 MB max)',
      deleteItem: 'Delete item',
      deleteItemBody: 'Earlier orders keep its name and price. Are you sure?',
      editItem: 'Edit item',
      name: 'Name',
      description: 'Description',
      uploadDevice: 'Upload from the device',
      removeImage: 'Remove image',
      imageLink: 'Or paste the image link (https)',
      priceIn: 'Price ({symbol})',
      stock: 'Stock (empty = unlimited)',
      active: 'Active (shown to students)',
    ),
    nav: SNav(
      items: {'/dashboard': 'Dashboard', '/attention': 'Students needing attention', '/review-plan': 'Daily review portions', '/sync': 'Sync', '/students': 'Students', '/circles': 'Circles', '/attendance': 'Attendance', '/gatherings': 'Gatherings & activities', '/recitations': 'Recorded recitations', '/external-recitations': 'External recitations', '/reviews': 'Suggested review', '/search': 'Search', '/quran': 'Quran', '/serd': 'Quran serd', '/stages': 'Stages', '/points': 'Points', '/badges': 'Badges', '/market': 'Points market', '/circle-challenges': 'Circle challenges', '/activities': 'Activities', '/announcements': 'Announcements', '/calendar': 'Calendar', '/chat': 'Messages', '/notifications': 'Notifications', '/reports': 'Reports', '/certificates': 'Certificates', '/fees': 'Fees', '/members': 'Members & roles', '/deletion-requests': 'Data deletion requests', '/audit': 'Activity log', '/site': 'Public page', '/settings': 'Center settings'},
      sections: {'teaching': 'Teaching', 'motivation': 'Motivation', 'comms': 'Communication', 'admin': 'Center management'},
      switchCenter: 'Switch center',
      menu: 'Menu',
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
      events: {'announcement': 'New announcement', 'calendar_entry': 'New calendar event', 'center_closed': 'Holiday or closure', 'event_reminder': 'Event reminders', 'waitlist_promoted': 'Moved up from the waiting list', 'serd_assigned': 'A serd assigned to me', 'serd_approved': 'Serd approved', 'serd_rejected': 'Serd not approved', 'market_fulfilled': 'Market order delivered', 'market_cancelled': 'Market order cancelled', 'badge_awarded': 'Badges', 'weekly_digest': 'Weekly digest', 'attendance_reminder': 'Attendance reminder', 'teacher_checkin_reminder': 'Teacher check-in reminder', 'student_idle_teacher': 'Teacher alert: student behind on recitation', 'student_idle': 'Reminder to a student behind on recitation', 'student_absences': 'Admin alert: repeated absence', 'deletion_request': 'Data deletion requests', 'deletion_reviewed': 'Outcome of my data deletion request', 'gathering_submitted': 'New gathering submitted', 'external_submitted': 'New external recitation', 'external_reviewed': 'External recitation outcome', 'assistant_assigned': 'Assistant teacher assigned', 'billing_reminder': 'Subscription reminder', 'billing_reviewed': 'Payment review outcome', 'capacity_warning': 'Plan capacity', 'billing_downgraded': 'Moved to the free plan', 'fee_payment': 'Fee payment receipt', 'fee_overdue': 'Fees due reminder', 'recitation_submitted': 'New recorded recitation to review', 'recitation_reviewed': 'Recorded recitation reviewed', 'wird_reminder': 'Today\'s portion reminder'},
      types: 'Notification types',
      instantTitle: 'Get notifications instantly',
      instantBody: 'The phone is saving battery by delaying this app’s notifications. Let it run unrestricted so messages arrive the moment they are sent.',
      instantBattery: 'Turn off battery saving',
      instantBatteryHint: 'Choose “All apps” → Bustan Al-Quran → “Don’t optimise” or “Unrestricted”.',
      instantAutostart: 'Allow auto-start',
      instantAutostartHint: 'On {maker} phones turn on “Auto-start” for Bustan Al-Quran, or notifications stop when the app is closed.',
      instantOk: 'Notifications arrive instantly on this phone',
    ),
    org: SOrg(
      circleStatus: {'active': 'Active', 'archived': 'Archived'},
      attStatus: {'present': 'Present', 'absent': 'Absent', 'excused': 'Excused', 'late': 'Late'},
      outboxAttendance: 'Attendance sheet {sessionDate} ({n} students)',
      saveErrorRetry: 'Something went wrong while saving — try again',
      deleteCircle: 'Delete circle',
      deleteCircleBody: 'Delete this circle? This can’t be undone.',
      editCircle: 'Edit circle',
      addCircle: 'Add circle',
      circleName: 'Circle name',
      stage: 'Stage',
      noStage: 'No stage',
      teacher: 'Teacher',
      noTeacher: 'No teacher',
      capacity: 'Capacity (students)',
      assistants: 'Assistant teachers',
      assistantsHint: 'They get this circle’s teacher access for this circle only and show with an “Assistant teacher” tag.',
      noOtherTeachers: 'No other teachers in the center',
      status: 'Status',
      addCircleBtn: 'Add the circle',
      noCircles: 'No circles yet',
      noCirclesHint: 'Create the first circle, then add students to it',
      capacityN: 'Capacity {capacity}',
      gradesLoadFailed: 'Could not load the grades',
      keyRule: 'The key takes only lowercase English letters/digits/_, and the name is required',
      gradesSaved: 'Grades saved',
      gradesTitle: 'Recitation grades & points',
      gradesHint: 'Grade names and the points for each. Points are stored on each recitation when it’s recorded, so changes apply to future recitations only.',
      name: 'Name',
      points: 'Points',
      addGrade: 'Add a new grade',
      keyField: 'Key (e.g. outstanding)',
      nameField: 'Name (e.g. Outstanding)',
      saveGrades: 'Save grades',
      gradesAdminOnly: 'Only the admin can change the grades and points.',
      stageTaken: 'That name or code is already used in this center',
      deleteStage: 'Delete stage',
      deleteStageBody: 'Delete this stage?',
      editStage: 'Edit stage',
      addStage: 'Add stage',
      stageName: 'Stage name',
      stageNamePh: 'Preparatory',
      stageCode: 'Stage number in the student number (1-2 digits, e.g. 2). Left empty, the stage order is used',
      stageOrder: 'Stage order',
      addStageBtn: 'Add the stage',
      noStages: 'No stages yet',
      noStagesHint: 'Stages organize circles and are used to number students',
      orderN: 'Order {sortOrder}',
      circlesLoadFailed: 'Could not load the circles',
      studentsLoadFailed: 'Could not load the circle’s students',
      attSaved: 'Attendance saved',
      saveAtt: 'Save attendance',
      circle: 'Circle',
      dateV: 'Date:  {v}',
      pickCircle: 'Choose the circle to take attendance',
      pickCircleHint: 'Then set each student’s status and save',
      noStudents: 'No students in this circle',
      allPresent: 'Mark everyone present',
      deleteActivity: 'Delete activity',
      deleteActivityBody: 'Delete this activity?',
      editActivity: 'Edit activity',
      newActivity: 'New activity',
      title: 'Title',
      description: 'Description',
      whenOpt: 'Time (optional)',
      addActivity: 'Add activity',
      noActivities: 'No activities yet',
      noActivitiesHint: 'Add the center’s activities for everyone to see',
      noTime: 'No set time',
      siteIntro: 'A public page about your center, shown to visitors who aren’t signed in.',
      siteEnable: 'Turn on the public page',
      heroTitle: 'Headline',
      heroBody: 'Introduction',
      contactEmail: 'Contact email',
      siteAdminOnly: 'Only the admin can change the public page settings.',
    ),
    plan: SPlan(
      graceTrial: '🍂 The trial has ended — your garden is waiting to be watered: renew from the web dashboard',
      gracePaid: '🍂 The center’s subscription has ended — your garden is waiting to be watered: renew from the web dashboard',
      soonTrial: '🌿 The trial ends in {days}',
      soonPaid: '🌿 The center’s subscription ends in {days}',
      days: {'one': '1 day', 'two': '2 days', 'many': '{n} days'},
      students: {'one': '1 student', 'two': '2 students', 'many': '{n} students'},
      studentsFull: '🌳 The garden is full: the center has reached its student limit ({max})',
      studentsLeft: '🌿 {n} more can be added on the plan',
      teachersFull: '🌳 The center has reached its teacher limit ({max})',
      oneTeacherLeft: '🌿 Only one more teacher can be added on the plan',
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
    prof: SProf(
      thisMonth: 'This month',
      lastMonth: 'Last month',
      last90: 'Last 3 months',
      vsPrev: 'Compared with the period before',
      same: 'No change',
      newV: 'New',
      recitations: 'Recitations',
      reciting: 'Students who recited',
      points: 'Points',
      attendance: 'Attendance',
      serdHeard: 'Serd heard',
      serdApproved: 'Serd approved',
      daysPresent: 'Days present',
      teacherDays: 'Teacher’s days present',
      students: 'Students',
      circles: 'Circles',
      assistant: 'Assistant',
      teacher: 'Teacher',
      assistants: 'Assistants',
      recent: 'Latest recitations',
      teacherAtt: 'Teacher attendance',
      nothing: 'Nothing in this period',
      lastRec: 'Last: {v}',
      never: 'Not yet',
      today: 'Today',
      daysAgo: '{n} days ago',
      profile: 'Profile',
      myProfile: 'My profile & results',
      message: 'Message',
      call: 'Call',
      notAllowed: 'You don’t have access to this profile',
      goalTitle: 'Memorization goal & khatm',
      memorized: '{n} of {total} pages',
      percentQuran: '{p}% of the Quran',
      pace: 'Actual pace',
      paceV: '{n} pages/working day',
      goalPace: 'Goal',
      goalPaceV: '{n} pages a day',
      sinceStart: 'Since the goal started: {actual} of {expected} pages',
      forecast: 'Expected finish',
      forecastGoal: 'At the goal pace',
      noPace: 'No new memorisation lately',
      noGoal: 'No goal set yet',
      goalStatus: {'ahead': 'Ahead', 'on_track': 'On track', 'behind': 'Behind', 'done': 'Done'},
      setGoal: 'Set goal',
      editGoal: 'Edit goal',
      pagesPerDay: 'Pages per working day',
      targetPages: 'Target in pages (604 = whole Quran)',
      note: 'Note (optional)',
      save: 'Save',
      clearGoal: 'Remove goal',
      goalSaved: 'Goal saved',
      invalidPages: 'Enter a number between 0.25 and 20',
      outboxGoal: 'Memorization goal for {name}',
      whatsapp: 'WhatsApp',
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
      credit: 'Text: Uthmani script, Hafs from Asim · Recitations: everyayah.com and quran.com · Fallback text: tanzil.net',
      bookmarks: 'Bookmarks',
      mark: 'Add bookmark',
      repeatN: 'Repeat the ayah {n} times',
      play: 'Play',
      pause: 'Pause',
      sync: 'Listening',
      syncNone: 'Whole surah (no following)',
      syncAyah: 'Follow the ayah',
      syncWord: 'Follow the word',
      reciter: 'Reciter',
      noTimings: 'No word timings for this reciter in this surah yet — following by ayah instead.',
      noSurahAudio: 'No whole-surah recitation for this surah — choose "Follow the ayah"',
      fontSize: 'Text size',
      testMode: 'Self-test',
      testHint: 'Self-test: the ayahs are hidden — tap an ayah to reveal it, or play the recitation to reveal along with it.',
      revealPage: 'Reveal page',
      hidePage: 'Hide page',
      prevPage: 'Previous page',
      nextPage: 'Next page',
      readingSettings: 'Reading settings',
    ),
    rec: SRec(
      pickGrade: 'Choose the recitation grade',
      pickSurah: 'Choose the surah',
      enterRange: 'Enter the ayah range',
      rangeOrder: 'The last ayah must be the same as or after the first',
      tooFar: 'Surah {v} has only {v2} ayahs',
      partial: '{saved} saved; the rest weren’t: {message}',
      newTitle: 'Record today’s progress',
      editTitle: 'Edit recitation',
      prefilled: 'Filled in from the suggested review plan — change it if needed',
      dateToday: 'Recitation date: today',
      dateV: 'Recitation date: {year}/{month}/{day}',
      type: 'Kind of progress',
      addSurah: 'Add another surah to this session',
      grade: 'Recitation grade',
      notes: 'Teacher’s notes (optional)',
      saveBtn: 'Save recitation',
      saveEdit: 'Save changes',
      fromAyah: 'From ayah',
      toAyah: 'To ayah',
      maxV: 'Max {max}',
      searchSurah: 'Search by surah name or number',
      ayahsN: '{v} ayahs',
      absenceFailed: 'Couldn’t save the absence',
      lessonTitle: 'Lesson mode',
      studentXofY: 'Student {v} of {n}',
      plan: 'Their assigned plan',
      recordBtn: 'Record the recitation',
      absent: 'Absent',
      later: 'Later',
      nobody: 'No one in this circle is waiting to recite right now',
      done: 'The lesson is over',
      summary: 'Recited {_recited}  •  absent {_absent}  •  postponed {n}',
      anotherRound: 'Another round for those left',
      finish: 'Finish and go back',
      circle: 'Circle',
      doneToday: '{done} of {total} recited today',
      outboxAttendance: 'Attendance {studentName}: {status}',
      outboxRecitation: 'Recitation {studentName} — surah {surah} ({ayahFrom}–{ayahTo})',
      today: 'Today',
      dayMonth: '{day}/{month}',
      addNote: 'Add a note',
      saveWithPoints: 'Save recitation  •  +{n} pts',
      change: 'Change',
      wholeSurah: 'Whole surah',
    ),
    recite: SRecite(
      rangeTitle: 'Repeat a passage',
      from: 'From ayah',
      to: 'To ayah',
      times: 'Times',
      rangeHint: 'The passage from ayah {from} to ayah {to} plays {times} times. Each ayah’s own repeat stays as chosen.',
      loop: 'Round {n} of {total}',
      rangeOff: 'Stop repeating',
      recite: 'Recite',
      reciteTitle: 'Recite to the system',
      reciteHint: 'Choose the passage, press “Start recording” and recite from memory. The ayahs are hidden while recording.',
      student: 'Student',
      type: 'Type',
      start: 'Start recording',
      stop: 'Stop recording',
      recording: 'Recording… recite from memory',
      micDenied: 'Microphone access was not allowed. Allow it in the browser settings and try again.',
      micMissing: 'This browser can’t record.',
      tooLong: 'Recordings are limited to {n} minutes; split the passage.',
      uploading: 'Uploading the recording…',
      checking: 'Checking the recitation…',
      uploadFailed: 'The recording could not be uploaded. Try again.',
      result: 'Result',
      score: '{n}% match',
      correct: 'correct',
      missing: 'missing',
      wrong: 'different',
      extra: 'extra',
      legend: 'Missing words are red and different words orange on the page.',
      unavailable: 'The automatic check is not available now. You can still send the recording to your teacher.',
      autoNote: 'The automatic check is approximate: it finds missing or different words, not tajweed or vowels. Your teacher’s judgement is what counts.',
      note: 'Note for the teacher (optional)',
      send: 'Send to the teacher',
      sent: 'Sent to your teacher. You will be notified of the decision.',
      again: 'Record again',
      cancel: 'Cancel',
      testStudent: 'Test a student',
      testTitle: 'Testing a student in the mushaf',
      testHint: 'The ayahs are hidden: tap an ayah to uncover it, then tap a word the student got wrong to mark it (tap again to unmark).',
      mistakes: 'Mistakes: {n}',
      grade: 'Grade',
      save: 'Save to the student’s record',
      saved: 'Saved to {name}’s record (+{points} points).',
      chooseStudent: 'Choose the student',
      noStudents: 'There are no students you can test.',
      badRange: 'Invalid passage.',
      error: 'Something went wrong. Try again.',
      myTitle: 'My recorded recitations',
      inboxTitle: 'Recorded recitations',
      inboxHint: 'Recitations your students sent from the mushaf. Listen, then approve to add it to the student’s record, or return it with a note.',
      pending: 'Waiting',
      reviewed: 'Reviewed',
      none: 'No recitations.',
      approve: 'Approve',
      reject: 'Return',
      rejectNote: 'Reason or a note for the student',
      teacherNote: 'Teacher’s note: {note}',
      studentNote: 'Student’s note: {note}',
      autoScore: 'Automatic check {n}%',
      noAuto: 'No automatic check',
      heardAs: 'Words that differed:',
      missingWords: 'Missing words:',
      openMushaf: 'Open in the mushaf',
      teacherTest: 'Teacher’s test',
      markedMistakes: 'Marked mistakes: {list}',
      statusDraft: 'Not sent',
      statusSubmitted: 'Waiting for the teacher',
      statusApproved: 'Approved',
      statusRejected: 'Returned',
      reviewedBy: 'Reviewed by {name}',
      ayahRange: 'Surah {surah} {from}–{to}',
      waitingN: '{n} recorded recitations waiting for your review',
      recheck: 'Run the automatic check again',
      testNote: 'Note (optional)',
      micDeniedApp: 'Microphone access was not allowed. Allow it in the device settings and try again.',
      play: 'Listen',
      apply: 'Apply',
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
      sumTitle: '{center} report',
      sumActive: 'Active students: {students_active}',
      sumPoints: 'Points: {points}',
      sumAttendance: 'Attendance rate: {v}',
      sumSerd: 'Approved serd: {serd_approved}',
      sumRecitations: 'Recitations: {recitations} ({reciting_students} students)',
      sumCircle: '• {name}: {recitations} recitations, attendance {v}',
    ),
    rplan: SRplan(
      title: 'Daily review portions',
      hint: 'For each student the system suggests the next pages of what they memorised, in order. Approve with one tap; the student and the family then see it.',
      range: 'From {from} to {to}',
      ayahRef: '{surah} {ayah}',
      pagesN: '{n} pages (p. {a}–{b})',
      approve: 'Approve',
      approveAll: 'Approve all',
      approvedN: '{n} approved',
      recite: 'Recite',
      skip: 'Cancel',
      status: {'suggested': 'Suggested', 'approved': 'Approved', 'done': 'Done ✓', 'pending': 'Waiting to upload'},
      none: 'No students with memorised pages yet',
      cycleStart: 'A new round starts',
      today: 'Today’s review',
      reviewPages: 'Daily review pages (empty = automatic)',
      outbox: 'Approve review for {name}',
    ),
    serd: SSerd(
      overdueSuffix: '  ·  overdue',
      inactiveSuffix: '  ·  inactive',
      passSuffix: '  ·  pass {n}%',
      wholeJuz: 'Whole juz',
      noCircle: 'No circle',
      linkStudent: 'Link the serd to a student',
      approved: 'Approved',
      rejectTitle: 'Reject the serd',
      rejectReason: 'Reason for rejecting (optional)',
      reject: 'Reject',
      rejected: 'Rejected',
      deleteTitle: 'Delete the serd',
      deleteBody: 'This serd will be deleted and its points taken off if it was approved. Are you sure?',
      deleted: 'Deleted',
      approve: 'Approve',
      reapprove: 'Approve again',
      certIssued: 'Certificate issued — find it on the certificates screen',
      issueCert: 'Issue a certificate',
      schedule: 'Schedule a serd',
      report: 'Report',
      settings: 'Settings',
      record: 'Record a serd',
      all: 'All',
      pending: 'Awaiting approval',
      scheduled: 'Scheduled',
      approvedChip: 'Approved',
      rejectedChip: 'Rejected',
      empty: 'No serd',
      requestedN: 'Requested serd ({n})',
      assigned: 'Assigned to you',
      openAny: 'Open — any teacher can record it{v}',
      recordShort: 'Record',
      mine: 'My serd',
      mineEmpty: 'You haven’t recorded any serd yet. Use the “Record a serd” button.',
      saved: 'Saved',
      wholeAlways: 'Whole juz (always)',
      newErrorType: 'New error type',
      editErrorType: 'Edit error type',
      name: 'Name',
      perErrors: 'Every (errors)',
      deductPct: '= deduct %',
      active: 'Active',
      fillAll: 'Fill in the name and numbers',
      stagePortions: 'Portions allowed for this stage',
      stagePass: 'Own pass mark % (leave empty for the general one)',
      settingsTitle: 'Serd settings',
      settingsHint: 'Changes apply to future serd only; earlier serd keep their score, points and pass mark.',
      general: 'Center-wide',
      passPct: 'Pass mark %',
      wholePoints: 'Points for a whole juz',
      defaultPortions: 'Portions allowed by default',
      wholeNumbers: 'Enter whole numbers',
      saveGeneral: 'Save general settings',
      errorTypes: 'Error types and their weights',
      perRule: 'Every {errorsPerUnit} = {percentPerUnit}%{v}',
      byStage: 'By stage',
      byStageHint: 'A young stage may recite half or a quarter of a juz and have its own pass mark.',
      usesGeneral: 'General setting',
      pickOrType: 'Choose the student or type their name',
      pickPart: 'Choose at least one juz',
      sentScore: 'Sent for approval ✓  score {score}%',
      saveFailedNet: 'Could not save; check the internet and try again',
      newTitle: 'Record a new serd',
      scheduledTitle: 'Record a scheduled serd',
      pickStudent: 'Choose the student',
      typeName: 'Or type the student’s name (from outside your circles)',
      clearPick: 'Clear the choice',
      dateLine: 'Serd date: {year}/{month}/{day}',
      parts: 'Juz recited',
      errors: 'Number of errors',
      perRule2: 'Every {errorsPerUnit} = {percentPerUnit}%',
      expected: 'Expected score: {v}%  ·  pass mark {passPercent}%',
      notesOpt: 'Notes (optional)',
      submit: 'Send for approval',
      noResults: 'No results',
      reportTitle: 'Serd report',
      totalSessions: 'Total sessions',
      waiting: 'Pending',
      avgScore: 'Average score',
      pointsGiven: 'Points awarded',
      approvedParts: 'Approved juz',
      juzLine: 'Juz {juz} — {v}',
      topErrors: 'Most common errors (approved)',
      examiners: 'Examiners',
      partsLine: '{v}  ({v2} juz)',
      examiner: 'Examiner: {examinerName}',
      circleTeacher: 'Circle teacher: {circleTeacherName}',
      assignedTo: 'Assigned to {assignedTeacherName}',
      openToAny: 'Open to any teacher',
      noStudent: 'Not linked to a student',
      scoreLabel: 'Score: ',
      resultLine: '  ·  {v} (pass mark {passApplied})  ·  +{pointsAwarded} points',
      rejectReasonV: 'Reason for rejecting: {rejectReason}',
      whole: 'Whole',
      pickJuz: 'Choose the juz',
      juzLine2: 'Juz {juz} — {v}',
      addJuz: 'Add another juz',
      passed: 'passed',
      repeat: 'retake',
      pickBoth: 'Choose the student and at least one juz',
      scheduledOk: 'Serd scheduled',
      scheduleHint: 'A task shown to teachers for whoever is free to record it, or assigned to one teacher.',
      student: 'Student',
      when: 'Date: {year}/{month}/{day}',
      partsWanted: 'Juz requested',
      assign: 'Assign to a teacher',
      scheduleBtn: 'Schedule the serd',
      outboxLabel: 'Serd {studentName} — {n} juz',
      certDone: 'Certificate issued',
      issueAnother: 'Issue another certificate',
    ),
    set: SSet(
      loadSome: 'Some settings could not be loaded',
      saved: 'Settings saved',
      fromGallery: 'From the gallery',
      takePhoto: 'Take a photo',
      tooBig1: 'The image is too big (1 MB max)',
      logoUploaded: 'Logo uploaded — tap “Save identity” to apply it everywhere',
      logoAdminOnly: 'Only the admin can upload the logo',
      logoFailed: 'Could not upload the logo',
      logoHttps: 'The logo link must start with https',
      backdateRange: 'The backdating limit must be between 0 and 365 days',
      intro: 'Everything about your center can be customized here.',
      identity: 'Identity',
      name: 'Center name',
      uploading: 'Uploading...',
      uploadLogo: 'Upload a logo from the device',
      remove: 'Remove',
      logoLink: 'Or the logo link (https)',
      primary: 'Primary color (hex)',
      secondary: 'Secondary color (hex)',
      link: 'Center link',
      timezone: 'Time zone',
      saveIdentity: 'Save identity',
      workdays: 'Working days',
      workdaysHint: 'Attendance rates count working days only; serd days can be marked too.',
      working: 'Working',
      serdDay: 'Serd',
      saveWorkdays: 'Save working days',
      features: 'Recitation & feature settings',
      backdate: 'How many days back a recitation can be dated',
      countryCode: 'Phone country code (e.g. 962)',
      whatsapp: 'WhatsApp group link',
      locationLabel: 'Location name (for prayer times and the calendar)',
      lat: 'Latitude',
      lng: 'Longitude',
      method: 'Prayer calculation method',
      madhab: 'Madhab (shafi / hanafi)',
      reciters: 'Reciters in the mushaf',
      recitersHint: 'Leave it empty to offer every reciter.',
      defaultReciter: 'Default reciter',
      firstInList: 'First in the list',
      market: 'Turn on the points market',
      tabs: {'identity': 'Identity', 'workdays': 'Working days', 'features': 'Features', 'contact': 'Contact & prayer', 'quran': 'Mushaf', 'notif': 'Notifications'},
      quranTitle: 'Mushaf & reciters',
      prayerMethods: {'umm_al_qura': 'Umm al-Qura', 'muslim_world_league': 'Muslim World League', 'egyptian': 'Egyptian authority', 'karachi': 'Karachi', 'dubai': 'Dubai', 'qatar': 'Qatar', 'kuwait': 'Kuwait', 'moon_sighting_committee': 'Moonsighting Committee', 'singapore': 'Singapore', 'turkey': 'Turkey', 'tehran': 'Tehran', 'north_america': 'North America (ISNA)'},
      majority: 'Majority (Shafi‘i / Maliki / Hanbali)',
      hanafi: 'Hanafi',
      fees: 'Turn on student fees (for centers that charge)',
      leaderboard: 'Turn on the leaderboard',
      teacherStudents: 'Let teachers manage their circle’s students',
      saveSettings: 'Save settings',
      adminOnly: 'Only the admin can change the center settings.',
      loadOne: 'Could not load the setting',
      digestTitle: 'Weekly family digest',
      digestHint: 'A weekly notification to each family: their child’s recitations, attendance and points, on the center’s time.',
      digestEnable: 'Turn on the weekly digest',
      day: 'Day',
      hour: 'Hour',
      digestSaved: 'Weekly digest setting saved',
      saveFailed: 'Could not save',
      digestSub: 'Day, hour and on/off',
      attTitle: 'Teacher attendance reminder',
      attHint: 'On working days, after the set hour, the teacher gets one reminder if their circle’s attendance hasn’t been taken.',
      attEnable: 'Turn on the reminder',
      afterHour: 'After',
      attSaved: 'Reminder setting saved',
      attTitle2: 'Teacher reminder to take attendance',
      attSub: 'On/off and hour',
      language: 'Center’s default language',
      languageHint: 'Screens show in this language for anyone who hasn’t picked one. Everyone can still switch for themselves from the menu.',
    ),
    stu: SStu(
      status: {'active': 'Active', 'paused': 'Paused', 'graduated': 'Graduated', 'withdrawn': 'Withdrawn'},
      noCircle: 'No circle',
      deleteTitle: 'Delete student',
      deleteBody: '“{fullName}” and their whole file (attendance, serd, points...) will be deleted. This can’t be undone.',
      title: 'Students',
      add: 'Add student',
      searchPh: 'Search by name or student number',
      empty: 'No students yet',
      emptyHint: 'Start by adding the first student with the button below',
      noMatch: 'No matching results',
      editDetails: 'Edit details',
      deleteWithFile: 'Delete the student and their file',
      circleRequired: 'Choose a circle for the student',
      accountCreated: 'Student account created',
      codeTaken: 'That student number is already used in this center',
      saveError: 'Something went wrong while saving',
      deleteBodyPlain: 'The student and their whole file (attendance, serd, points...) will be deleted. This can’t be undone.',
      editTitle: 'Edit student',
      details: 'Student details',
      fullName: 'Full name',
      nameRequired: 'Enter the student’s name',
      birthDate: 'Date of birth (optional)',
      tapToPick: 'Tap to choose',
      stageCircle: 'Stage & circle',
      stage: 'Stage',
      allStages: 'All stages',
      circleReq: 'Circle (required)',
      noCircles: 'No circles here — create one first in the circles section',
      code: 'Student number',
      codeHint: 'Suggested automatically when you pick the stage; you can change it',
      codeRequired: 'Enter the student number',
      contact: 'Contact details',
      phone: 'Mobile number (optional)',
      whatsapp: 'WhatsApp number (optional)',
      address: 'Address (optional)',
      login: 'Student sign-in account',
      password: 'Password',
      passwordHint: 'Leave it empty to create the file without a sign-in account',
      min8: 'At least 8 characters',
      email: 'Real email (optional)',
      emailHint: 'Without it, the student signs in with their number and the center code',
      statusLabel: 'Status',
      saveChanges: 'Save changes',
      addBtn: 'Add the student',
      recEdited: 'Recitation updated',
      recDeleteTitle: 'Delete recitation',
      recDeleteBody: 'This recitation will be deleted and its points taken off the student’s balance. Are you sure?',
      deleted: 'Deleted',
      nextPlan: 'Next plan',
      planPh: 'e.g. memorize Surah Al-Mulk, ayahs 1 to 15',
      planSaved: 'Plan saved',
      linkUpdated: 'Link updated',
      pickGuardian: 'Choose the guardian',
      noGuardians: 'No guardians yet',
      newGuardian: 'New guardian account',
      guardianName: 'Guardian’s name',
      loginId: 'Sign-in number or email',
      phoneOpt: 'Mobile (optional)',
      password8: 'Password (at least 8 characters)',
      create: 'Create',
      guardianIncomplete: 'Fill in the name, sign-in number and a password of at least 8 characters',
      guardianCreated: 'Guardian account created',
      allRecitations: 'All recitations',
      streak: 'Day streak',
      weeklyAttendance: 'Weekly attendance',
      lastRecitation: 'Last recitation',
      surahV: 'Surah {v}',
      recLine: '{type} • ayahs {ayahFrom} to {ayahTo}',
      progress: 'Progress',
      partsOf30: '{totalParts} of 30 juz',
      weeklyAttendanceV: 'Weekly attendance: {v}',
      statsLine: '{totalRecitations} recitations  ·  {currentStreak}-day streak (longest {longestStreak})  ·  last recitation {v}',
      noPlan: 'No plan set yet',
      sheikh: 'Teacher',
      phone2: 'Mobile',
      addressLabel: 'Address',
      guardian: 'Guardian',
      noGuardian: 'No guardian linked',
      linkedTo: 'Linked: {v}',
      newAccount: 'New account',
      linkExisting: 'Link an existing one',
      unlink: 'Unlink',
      log: 'Recitation log',
      noRecitations: 'No recitations yet',
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
      offlineTitle: 'Working offline',
      offlineHint: 'Everything you need is kept on this phone — your circles, students and their records, serd, the calendar and messages — so the app works without internet, and what you record uploads by itself when you’re back online.',
      offlineProgress: 'Downloading… {done} of {total}',
      offlineNever: 'Nothing downloaded to this phone yet',
      offlineLast: 'Last downloaded: {time}',
      offlineNow: 'Download now',
      offlineNeedsNet: 'Needs an internet connection',
    ),
    teach: STeach(
      greeting: '{v}, {v2}',
      findStudent: 'Find a student',
      noCircle: 'You haven’t been assigned to a circle yet',
      noCircleHint: 'Ask the supervisor to add you to a circle, then pull down to refresh.',
      yourCircles: 'Your circles ({n})',
      checkedIn: 'Your attendance is recorded ✓',
      checkInFailed: 'Couldn’t record attendance — check your connection',
      circleScreen: 'Circle screen',
      assistant: 'Assistant teacher',
      stage: 'Stage: {stageName}',
      doneOf: '{done} of {n} recited',
      checkIn: 'Check me in today',
      startLesson: 'Start lesson',
      savedPoints: 'Saved ✓  +{points} points',
      attendanceFailed: 'Couldn’t save attendance',
      noStudents: 'No students in this circle yet.\nAsk the supervisor to add them.',
      searchPh: 'Search by student name or number',
      all: 'All',
      notToday: 'Not recited today',
      recitedToday: 'Recited today',
      sort: 'Sort the list',
      alpha: 'Alphabetically',
      notFirst: 'Not recited first',
      topPoints: 'Most points',
      xOfY: '{n} of {n2}',
      noMatch: 'No one matches what you picked.',
      showAll: 'Show all students',
      pointsN: '{totalPoints} points',
      recitedTodayN: 'Recited today ×{recitedToday}',
      dueReviews: 'Review due ({n})',
      takeAttendance: 'Take attendance',
      attendanceIs: 'Attendance: {value}',
      record: 'Record a recitation',
      general: 'General',
    ),
    ui: SUi(
      credsText: 'Center code: {centerCode}\nNumber / email: {loginId}\nPassword: {password}',
      credsOnce: 'This is the only time the password is shown — copy it now and hand it over.',
      copied: 'Copied',
      copy: 'Copy',
      done: 'Done',
      skeletonTitle: 'Student’s full name here',
      skeletonSub: 'A little extra information',
      add: 'Add',
      search: 'Search',
      noMatch: 'No matching results',
      channelName: 'Bustan Al-Quran notifications',
      channelDesc: 'Messages, reminders and approvals',
      sessionEnded: 'Your session ended; sign in again',
      requestFailed: 'The request didn’t go through',
      savedOffline: 'Saved on your device; it uploads automatically when you’re back online',
      outboxCheckIn: 'My check-in at the circle',
      outboxNote: 'A note on a student',
      outboxGathering: 'Activity: {title}',
      outboxExternal: 'External recitation: {name}',
      outboxEditRecitation: 'Recitation edit',
      outboxDeleteRecitation: 'Recitation delete',
      outboxPlan: 'A student\'s next plan',
      waitingUpload: 'Waiting to upload',
    ),
    weekly: SWeekly(
      smartToggle: 'Smart weekly report',
      smartHint: 'Adds: the memorization goal, ahead or behind, last-week comparison and the teacher’s note',
      title: 'Weekly report',
      period: '{from} to {to}',
      thisWeek: 'This week',
      lastWeek: 'Last week',
      recitations: 'Recitations',
      newPages: 'New pages',
      reviews: 'Reviews',
      points: 'Points',
      attendance: 'Attendance',
      attV: '{present} of {days}',
      teacherNote: 'Teacher’s note',
      noNote: 'No note from the teacher this week',
      nextPlan: 'For next week',
      open: 'Weekly report',
    ),
    wird: SWird(
      title: 'Today\'s portion',
      newPart: 'New memorization',
      reviewPart: 'Review',
      fromTeacher: 'Set by your teacher',
      suggested: 'Suggested',
      done: 'Done',
      sent: 'Sent to the teacher',
      todo: 'Not recited yet',
      recite: 'Recite now',
      open: 'Open in the mushaf',
      complete: 'Today\'s portion is complete, may Allah bless you',
      none: 'No portion yet: it appears after the first new memorization in your record.',
      dayOff: 'Today is not a working day at the center; the portion is optional.',
      pages: '{n} pages',
    ),
  );

  static const tr = S(
    lang: 'tr',
    common: SCommon(
      appName: 'Bustan Al-Quran',
      signOut: 'Çıkış yap',
      loadFailed: 'Veriler yüklenemedi',
      checkConnection: 'İnternet bağlantınızı kontrol edip tekrar deneyin',
      retry: 'Tekrar dene',
      noPermission: 'Bunu yapma izniniz yok',
      linkedData: 'Başka veriler buna bağlı olduğu için yapılamıyor',
      offline: 'İnternet bağlantısı yok, tekrar deneyin',
      cancel: 'İptal',
      save: 'Kaydet',
      delete: 'Sil',
      edit: 'Düzenle',
      send: 'Gönder',
      close: 'Kapat',
      confirm: 'Onayla',
      language: 'Dil',
      goodMorning: 'Günaydın',
      goodEvening: 'İyi akşamlar',
      listSep: ', ',
    ),
    labels: SLabels(
      recitationType: {'new_memorization': 'Yeni ezber', 'recent_review': 'Yakın tekrar', 'distant_review': 'Uzak tekrar'},
      attendance: {'present': 'Geldi', 'absent': 'Gelmedi', 'late': 'Geç kaldı', 'excused': 'İzinli'},
      purchase: {'pending': 'Teslim bekleniyor', 'fulfilled': 'Teslim edildi', 'cancelled': 'İptal edildi'},
      metric: {'points': 'Öğrenci başına ortalama puan', 'recitations': 'Öğrenci başına ortalama dinletme', 'attendance': 'Öğrenci başına ortalama devam günü'},
      challengeStatus: {'upcoming': 'Yaklaşan', 'active': 'Sürüyor', 'ended': 'Bitti'},
      serdStatus: {'scheduled': 'Planlandı', 'submitted': 'Onay bekliyor', 'approved': 'Onaylandı', 'rejected': 'Reddedildi'},
      months: ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'],
      rule: {'manual': 'Yönetici tarafından verildi', 'points_threshold': '{n} puan', 'recitations_count': '{n} dinletme', 'grade_count': '“{grade}” notlu {n} dinletme', 'streak_days': 'Art arda {n} gün', 'weekly_attendance': 'Haftalık %{n} devam', 'juz_complete': 'Serdde {n}. cüzü tamamla', 'serd_passed_count': '{n} başarılı serd oturumu'},
      juz: '{n}. cüz',
      portion: '{ord} {den}',
      portionDen: {'2': 'yarım', '4': 'çeyrek', '8': 'sekizde bir'},
      portionOrd: ['1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.'],
      audience: {'all': 'Herkes', 'teachers': 'Öğretmenler', 'students': 'Öğrenciler', 'guardians': 'Veliler'},
      consent: {'not_required': '—', 'pending': 'Onay bekleniyor', 'approved': 'Onaylandı', 'declined': 'Reddedildi'},
      source: {'self': 'Kendisi kaydoldu', 'guardian': 'Velisi kaydetti', 'teacher': 'Öğretmen kaydetti', 'admin': 'Yönetici kaydetti'},
      registration: {'none': 'Kayıt yok', 'ended': 'Bitti', 'closed': 'Kayıt kapalı', 'full': 'Tüm yerler doldu', 'open': 'Kayıt açık'},
      weekdays: ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'],
      certKind: {'serd': 'Kur’an serdi', 'memorization': 'Ezber tamamlandı', 'excellence': 'Üstün başarı', 'attendance': 'Düzenli devam', 'custom': 'Özel'},
      deletionStatus: {'pending': 'İnceleniyor', 'approved': 'Onaylandı', 'rejected': 'Reddedildi', 'completed': 'Tamamlandı'},
      roles: {'admin': 'Yönetici', 'teacher': 'Öğretmen', 'student': 'Öğrenci', 'guardian': 'Veli'},
    ),
    banners: SBanners(
      viewer: 'Bu bir görüntüleme hesabı — veriler salt okunurdur',
      billingLock: '🍂 Merkezin aboneliği sona erdi — yenilenene kadar veriler salt okunurdur',
    ),
    portal: SPortal(
      tabHome: 'Ana sayfa',
      tabRecord: 'Kaydım',
      tabAccount: 'Hesap',
      noChildren: 'Hesabınıza bağlı çocuk yok',
      notLinked: 'Hesabınız bir öğrenci profiline bağlı değil',
      askAdmin: 'Hesabınızı bağlamak için merkez yönetimiyle iletişime geçin',
      studentMissing: 'Öğrencinin profili bulunamadı',
      noStudent: 'Bağlı öğrenci profili yok',
      hello: 'Merhaba, {name}',
      sheikh: 'Hoca {name}',
      noCircle: 'Henüz bir halkaya atanmadı',
      progressTitle: 'Ezber ilerlemesi',
      partsOf30: '30 cüzden {n}',
      nextPlan: 'Sonraki planınız: {plan}',
      goalQuran: 'Kur’an ezberini tamamlamaya',
      goalPoints: '{n} puana ulaşmaya',
      unitJuz: 'cüz',
      unitPoints: 'puan',
      remaining: '{n} {unit} kaldı',
      announcements: 'Duyurular',
      upcoming: 'Yaklaşanlar',
      prayers: ['İmsak', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'],
      statsTitle: 'İstatistikleriniz',
      statAyahs: 'Bu haftaki ayetler',
      statAttendance: 'Haftalık devam',
      statTotal: 'Toplam dinletme',
      statLast: 'Son dinletme',
      weekTitle: 'Haftanız',
      weekCount: 'Bu hafta {n} dinletme',
      weekBetter: 'Geçen haftadan iyi (+{n})',
      weekWorse: 'Geçen haftadan az ({n})',
      weekSame: 'Geçen haftayla aynı',
      streak: 'Güncel seri: {n} gün  ·  En uzun: {best}',
      streakRecord: '🎉 Yeni kişisel rekor seri!',
      yourBadges: 'Rozetleriniz',
      calendar: 'Takvim ve etkinlikler',
      calendarSub: 'Tatiller, geziler ve yarışmalar — ve kayıt',
      chat: 'Mesajlar',
      announcementsLink: 'Duyurular',
      report: 'Rapor',
      reportSub: 'Seçtiğiniz dönem için dinletme, devam ve serd',
      certificates: 'Sertifikalar',
      quran: 'Kur’an',
      quranSub: 'Okuyun, dinleyin ve yer imi ekleyin',
      privacy: 'Hesabım ve verilerim',
      privacySub: 'Hesabın ve verilerin silinmesini isteyin',
      notifications: 'Bildirimler',
      badges: 'Rozetler',
      market: 'Market',
      serd: 'Kur’an serdi',
      recent: 'Son dinletmeler',
      noRecitations: 'Henüz dinletme yok',
      studentCode: 'Öğrenci numarası',
      circle: 'Halka',
      stage: 'Aşama',
      teacher: 'Hoca',
      phone: 'Telefon',
      address: 'Adres',
      languageHint: 'Uygulama dili',
    ),
    record: SRecord(
      tabRecitations: 'Dinletme',
      tabAttendance: 'Devam',
      tabSerd: 'Serd',
      thisMonth: 'Bu ay',
      recitations: 'Dinletmeler',
      ayahs: 'Ayetler',
      attendance: 'Devam',
      points: 'Puan',
      breakdown: 'Puan dağılımı',
      noAttendance: 'Henüz yoklama kaydı yok',
      search: 'Sure veya nota göre ara',
      all: 'Tümü',
      noResults: 'Sonuç yok',
      session: 'Bir oturumda {n} dinletme',
    ),
    badges: SBadges(
      title: 'Rozetler ve yarışma',
      mine: 'Rozetlerim',
      none: 'Merkezinizin henüz rozeti yok',
      earned: '✓ Kazanıldı {date}',
      expires: '  ·  bitiş {date}',
      manual: 'Yönetici tarafından verildi',
      board: 'Onur tablosu — {circle}',
      points: '{n} puan',
      challenge: 'Halka yarışması: {title}',
    ),
    market: SMarket(
      title: 'Puan marketi',
      disabled: 'Market şu anda merkezinizde etkin değil',
      balance: 'Bakiye',
      earned: '{n} puandan  ·  harcanan {spent}',
      pending: '  ·  bir dönüşüm birimini tamamlamayı bekleyen {n} puan',
      available: 'Satın alınabilir',
      empty: 'Şu anda mevcut bir şey yok',
      stock: 'Kalan: {n}',
      bought: 'Sipariş verildi ✓ — merkez teslim edecek',
      soldOut: 'Tükendi',
      buy: 'Satın al',
      tooPoor: 'Yetersiz bakiye',
      orders: 'Siparişlerim',
      noOrders: 'Henüz sipariş yok',
      cancelled: 'Sipariş iptal edildi ve bakiye iade edildi',
    ),
    serdCard: SSerdCard(
      none: 'Henüz onaylanmış serd yok',
      sessions: 'Onaylanan oturumlar',
      average: 'Ortalama',
      best: 'En iyi',
      covered: 'Kapsanan',
      juzCount: '{n} cüz',
      complete: 'Tamamlanan cüzler: {list}',
      partial: 'Kısmi: {list}',
      partialItem: '{juz}. cüz — {e}/8',
    ),
    ann: SAnn(
      title: 'Duyurular',
      newTitle: 'Yeni duyuru',
      none: 'Duyuru yok',
      draft: 'Taslak',
      required: 'Başlık ve metin zorunludur',
      deleteTitle: 'Duyuruyu sil',
      sure: 'Emin misiniz?',
      fieldTitle: 'Başlık',
      fieldBody: 'Metin',
      audience: 'Hedef kitle',
      circleOptional: 'Belirli bir halka (isteğe bağlı)',
      allCircles: 'Tüm halkalar',
      pin: 'En üste sabitle',
      publish: 'Şimdi yayımla',
      publishHint: 'Hedef kitle ilk yayımlandığında bilgilendirilir',
      editTitle: 'Duyuruyu düzenle',
      yourCircle: 'Halkanız',
    ),
    attn: SAttn(
      title: 'İlgi bekleyen öğrenciler',
      hint: 'En acil olan önce: hedefinin gerisinde, dinletmeyen, sık devamsız.',
      none: 'Şu anda özel ilgi bekleyen kimse yok 🌿',
      behind: 'Hedefinin {pages} sayfa gerisinde',
      idle: '{days} çalışma günüdür dinletmedi',
      never: 'Hiç dinletmedi',
      absences: 'İki haftada {count} kez gelmedi',
      all: 'Tümü',
      filterBehind: 'Hedefin gerisinde',
      filterIdle: 'Dinletmeyen',
      filterAbsent: 'Devamsızlık',
      recite: 'Dinlet',
      call: 'Ara',
      lastRecited: 'Son dinletme: {v}',
      count: '{n} öğrenci',
    ),
    auth: SAuth(
      thisCenter: 'bu merkez',
      noCenter: 'Bu kodla bir merkez bulamadık; kontrol edip tekrar deneyin',
      badLogin: 'Giriş numarası / e-posta veya şifre hatalı',
      notMember: 'Bu hesap {v} merkezinde kayıtlı değil',
      serverDown: 'Sunucuya ulaşılamadı; internetinizi kontrol edip tekrar deneyin',
      codeFirst: 'Önce merkez kodunu girin',
      openFailed: 'Sayfa açılamadı; tarayıcıdan deneyin',
      signInTitle: 'Merkezinize giriş yapın',
      step1: '1. Merkez',
      centerCode: 'Merkez kodu',
      enterCode: 'Merkez kodunu girin',
      noCenterShort: 'Bu kodla merkez yok',
      codeHint: 'Merkez kodu, merkezinizin bağlantısının ilk kısmıdır; ör. eqraa.bustan-alquran.com için eqraa',
      step2: '2. Hesabınız',
      loginId: 'Kimlik / öğrenci numarası veya e-posta',
      enterId: 'Numaranızı veya e-postanızı girin',
      password: 'Şifre',
      enterPassword: 'Şifreyi girin',
      forgot: 'Şifrenizi mi unuttunuz?',
      signInTo: '{name} merkezine giriş',
      signIn: 'Giriş yap',
      whoHint: 'Öğretmenler, yöneticiler, veliler ve öğrenciler için giriş; her biri merkezdeki yetkisiyle.',
      confirmEmail: 'Önce hesabı onaylamak için e-postanızı kontrol edin, sonra katılımı tamamlamak için davet bağlantısını yeniden açın',
      joinFailed: 'Katılım tamamlanamadı; internetinizi kontrol edip tekrar deneyin',
      joinTitle: 'Bir merkeze katıl',
      invalidInvite: 'Geçersiz davet',
      invalidBody: 'Süresi dolmuş veya zaten kullanılmış. Merkez yöneticisinden yenisini isteyin.',
      inviteFrom: '{organization_name} davetiyesi',
      asRole: '{role} olarak katılmak için',
      signedInAs: '{email} olarak giriş yapıldı',
      confirmJoin: 'Katılımı onayla',
      inviteEmail: 'E-posta (davetten)',
      yourPassword: 'Hesap şifreniz',
      createPassword: 'Bir şifre oluşturun (en az 8 karakter)',
      signInJoin: 'Giriş yap ve katıl',
      createJoin: 'Hesabı oluştur ve katıl',
      noAccount: 'Hesabım yok',
      haveAccount: 'Zaten hesabım var',
      ob1: 'Dinletme ve ezberi kaydedin',
      ob1Body: 'Her halka, her öğrenci, ezberlenen veya tekrar edilen her sayfa — öğretmenden tek dokunuşla, not ve tarih her zaman saklanır.',
      ob2: 'Merkezle bağlantıda kalın',
      ob2Body: 'Yöneticiler, öğretmenler, öğrenciler ve veliler arasında mesajlar, duyurular ve anlık bildirimler — her merkez kendine özel.',
      ob3: 'Motivasyonu koruyan puan ve rozetler',
      ob3Body: 'Her dinletme puan, her aşama bir rozet kazandırır — küçük bir market ve halka yarışmaları ezberi sevilen bir günlük alışkanlığa dönüştürür.',
      openSignup: 'Yeni bir merkez kaydetmek için tarayıcınızda {_signupUrl} adresini açın',
      skip: 'Atla',
      signInBtn: 'Giriş yap',
      next: 'İleri',
      registerCenter: 'Web sitesinde yeni bir merkez kaydedin ↗',
      pickCenter: 'Merkezi seçin',
      noCenters: 'Hesabınız henüz hiçbir merkeze bağlı değil',
      noCentersHint: 'Merkez yöneticisinden sizi davet etmesini isteyin veya başka bir hesapla giriş yapın',
    ),
    badgesStaff: SBadgesStaff(
      rules: {'manual': 'Elle (yönetici verir)', 'points_threshold': 'Bir puan toplamına ulaşma', 'recitations_count': 'Dinletme sayısı', 'grade_count': 'Belirli bir notla dinletmeler', 'streak_days': 'Art arda dinletmeli günler', 'weekly_attendance': 'Haftalık devam oranı', 'juz_complete': 'Serdde tam bir cüzü tamamlama', 'serd_passed_count': 'Başarılı serd sayısı'},
      manual: 'elle',
      auto: 'otomatik',
      expiresSuffix: '  ·  bitiş {date}',
      nameRequired: 'Rozet adı zorunludur',
      pickStudent: 'Öğrenciyi seçin',
      awarded: 'Rozet verildi',
      pickCircle: 'Halkayı seçin',
      awardedN: '{n} öğrenciye verildi',
      deleteTitle: 'Rozeti sil',
      deleteBody: 'Tüm öğrencilerden kaldırılır. Emin misiniz?',
      newTitle: 'Yeni rozet',
      badge: 'Rozet',
      icon: 'Simge',
      name: 'Ad',
      description: 'Açıklama',
      rule: 'Kural',
      threshold: 'Koşul değeri',
      juzNo: 'Cüz numarası (1–30)',
      percent: 'Yüzde (1–100)',
      count: 'Gereken sayı',
      grade: 'Not',
      duration: 'Rozet süresi, gün (boş = kalıcı)',
      active: 'Etkin',
      giveManually: 'Rozeti elle ver',
      toStudent: 'Bir öğrenciye',
      toCircle: 'Tüm halkaya',
      holdersN: 'Sahipleri ({n})',
      noHolders: 'Henüz kimseye verilmedi',
      revoked: 'Rozet geri alındı',
      revoke: 'Geri al',
      reevaluate: 'Herkesi yeniden kontrol et',
      reevaluated: 'Rozetler tüm öğrenciler için yeniden kontrol edildi',
      intro: 'Otomatik rozetler koşulları sağlanır sağlanmaz verilir. Elle olanları yönetici verir veya öğretmen kendi halkasının öğrencilerine verir.',
      empty: 'Henüz rozet yok',
      expiresAfter: '{durationDays} gün sonra biter',
      inactive: 'Pasif',
    ),
    cal: SCal(
      settingLoadFailed: 'Ayar yüklenemedi',
      reminderTitle: 'Kayıtlılara hatırlat',
      reminderHours: 'Etkinlik başlamadan kaç saat önce — 0 = kapalı',
      reminderHelp: 'Kayıtlı öğrencilere ve velilerine gönderilir',
      reminderSaved: 'Hatırlatma ayarı kaydedildi',
      saveFailed: 'Kaydedilemedi',
      title: 'Takvim ve etkinlikler',
      reminderTip: 'Etkinlik öncesi hatırlatma',
      types: 'Kayıt türleri',
      add: 'Ekle',
      legend: 'Çalışma günleri: {total} günden {working}  ·  gri = tatil  ·  “Serd” = serd günü',
      thisMonth: 'Bu ay',
      nothing: 'Burada bir şey yok',
      youRegistered: 'Kaydoldunuz ✓',
      dayOff: 'Tatil',
      serdScheduled: 'Planlanmış serd: {name}',
      serd: 'Serd',
      linkCopied: 'Onay bağlantısı kopyalandı',
      registeredDone: 'Kaydedildi',
      resultOf: '{name} sonucu',
      rank: 'Sıra',
      note: 'Not',
      resultSaved: 'Sonuç kaydedildi',
      details: 'Ayrıntılar',
      registration: 'Kayıt',
      participants: 'Kayıtlı ({n})',
      registerStudent: 'Öğrenci kaydet',
      noParticipants: 'Henüz kimse kaydolmadı',
      waitlistCount: 'Bekleme listesi ({n})',
      circle: '{name} halkası',
      stage: '{name} aşaması',
      workDay: 'Çalışma günü',
      taken: 'Kayıtlı: {n}',
      waiting: 'Bekleyen: {n}',
      deadline: 'Son tarih: {date}',
      needsConsent: 'Veli onayı gerekir',
      unregister: 'Kaydı iptal et',
      unregistered: 'Kayıt iptal edildi',
      staffRegistered: 'Öğretmen veya yönetici tarafından kaydedildi — iptal için onlarla iletişime geçin',
      register: 'Kaydol',
      waitlisted: 'Bekleme listesine eklendi',
      joinWaitlist: 'Bekleme listesine katıl',
      leftWaitlist: 'Bekleme listesinden çıkıldı',
      leaveWaitlist: 'Bekleme listesinden çık',
      registeredChip: 'Kayıtlı ✓',
      waitingChip: 'Bekliyor',
      consent: 'Veli onayı: {status}',
      copyLink: 'Bağlantıyı kopyala',
      result: 'Sonuç: {rank}. sıra',
      rankN: '{rank}. sıra',
      copyConsent: 'Onay bağlantısını kopyala',
      consentRecorded: 'Onay kaydedildi',
      phoneConsent: 'Telefonla onay',
      declineRecorded: 'Ret kaydedildi',
      decline: 'Reddetti',
      resultBtn: 'Sonuç',
      searchStudent: 'Öğrenci adı veya numarasıyla ara',
      onDay: '{day}. gündeki kayıtlar',
      takenShort: '{n} kayıtlı',
      offDay: 'Çalışma günü değil (devam oranına sayılmaz)',
      unregisterQ: '{name} kaydı iptal edilsin mi?',
      withReg: ' — kayıtlı',
      notWorking: ' — çalışma günü değil',
      workingDay: 'Çalışma günü',
      notWorkingDay: 'Çalışma günü değil',
      pickTypeTitle: 'Türü seçin ve başlığı yazın',
      deleteBody: 'Bu öğe ve tüm kayıtları silinecek. Emin misiniz?',
      addTitle: 'Takvime ekle',
      type: 'Tür',
      titleField: 'Başlık',
      description: 'Açıklama',
      fromV: 'Başlangıç: {v}',
      toV: 'Bitiş: {v}',
      timeOpt: 'Saat (isteğe bağlı)',
      place: 'Yer',
      whoSees: 'Kim görür',
      audienceLabel: 'Hedef kitle',
      oneCircle: 'Belirli bir halka',
      allCircles: 'Tüm halkalar',
      oneStage: 'Belirli bir aşama',
      allStages: 'Tüm aşamalar',
      workingSection: 'Çalışma günü',
      overrideType: 'Türün ayarını geçersiz kıl',
      typeMakes: 'Türe göre: {v}',
      offDaysHint: 'Çalışılmayan günler öğrencilerin devam oranına sayılmaz.',
      registrationSection: 'Kayıt',
      seats: 'Kontenjan (boş = sınırsız)',
      closesAt: 'Kayıt kapanışı: {v}',
      removeDeadline: 'Son tarihi kaldır',
      open: 'Kayıt açık',
      saved: 'Kaydedildi',
      newType: 'Yeni tür',
      editType: 'Türü düzenle',
      name: 'Ad',
      hasRegistration: 'Kayıt alır',
      needsGuardian: 'Veli onayı gerekir',
      active: 'Etkin',
      typeNameRequired: 'Tür adı zorunludur',
      typesTitle: 'Takvim öğesi türleri',
      typesHint: 'Önceki öğeler eklendikleri andaki tür ayarlarını korur, bu yüzden bir türü düzenlemek eski devam oranlarını değiştirmez.',
      working: 'Çalışma',
      guardianConsent: 'Veli onayı',
      inactive: 'Pasif',
    ),
    cert: SCert(
      failed: 'İşlem tamamlanamadı',
      issueTitle: 'Sertifika düzenle',
      student: 'Öğrenci',
      kind: 'Tür',
      fieldTitle: 'Sertifika başlığı',
      fieldText: 'Metin (isteğe bağlı)',
      issue: 'Sertifikayı düzenle',
      serdHint: 'Serd sertifikaları onaydan sonra serd ekranından düzenlenir.',
      issued: 'Sertifika düzenlendi',
      revokeTitle: 'Sertifikayı iptal et',
      reason: 'Neden (isteğe bağlı)',
      revoke: 'İptal et',
      revoked: 'Sertifika iptal edildi',
      customizeTitle: 'Sertifikayı merkezinize göre özelleştirin',
      signer: 'İmzalayanın adı',
      signerRole: 'Unvanı',
      footer: 'Alt bilgi satırı',
      serdTitle: 'Serd sertifikası başlığı',
      autoSerd: 'Başarılı bir oturum onaylandığında serd sertifikasını otomatik düzenle',
      futureOnly: 'Değişiklikler yalnızca gelecekteki sertifikalara uygulanır; düzenlenmiş olanlar olduğu gibi kalır.',
      saved: 'Ayarlar kaydedildi',
      title: 'Sertifikalar',
      customize: 'Sertifikayı özelleştir',
      add: 'Sertifika',
      none: 'Henüz sertifika yok',
      revokedMark: ' · iptal edildi',
      one: 'Sertifika',
      notFound: 'Sertifika bulunamadı',
      linkCopied: 'Doğrulama bağlantısı kopyalandı',
      copyLink: 'Sertifikanın doğrulama bağlantısını kopyala',
      pdfHint: 'Yazdırılabilir PDF için sertifikayı bir tarayıcıda açıp “Yazdır / PDF olarak kaydet” seçin.',
      titleHint: 'Üstün başarı sertifikası',
      signerRoleHint: 'Merkez müdürü',
    ),
    cfeat: SCfeat(
      names: {'students': 'Öğrenciler', 'circles': 'Halkalar', 'attendance': 'Yoklama ve toplantılar', 'serd': 'Kur’an serdi', 'points': 'Puanlar', 'badges': 'Rozetler', 'market': 'Puan marketi', 'circle-challenges': 'Halka yarışmaları', 'activities': 'Etkinlikler', 'calendar': 'Takvim', 'announcements': 'Duyurular', 'chat': 'Mesajlar', 'notifications': 'Bildirimler', 'reports': 'Raporlar', 'certificates': 'Sertifikalar', 'fees': 'Öğrenci ücretleri', 'quran': 'Mushaf', 'recitations': 'Kayıtlı ve canlı dinletme', 'wird': 'Günlük vird ve hatırlatması', 'garden_tree': 'Büyüyen ağaç'},
      tab: 'Merkez özellikleri',
      title: 'Merkezin kullandığı özellikler',
      hint: 'Merkezinizin ihtiyaç duymadığını kapatın, herkesin menüsünden kalkar; istediğiniz zaman geri açın. Burada açılabilenler planınızın kapsadıklarıdır.',
      notInPlan: 'Planınızda yok',
      save: 'Özellikleri kaydet',
      saved: 'Merkez özellikleri kaydedildi',
      off: 'Bu özellik merkezinizde kapalı.',
    ),
    chat: SChat(
      title: 'Mesajlar',
      newChat: 'Yeni konuşma',
      none: 'Henüz konuşma yok',
      noneHint: 'Aşağıdaki düğmeyle yenisini başlatın',
      deletedLast: '🚫 Bir mesaj silindi',
      you: 'Siz: ',
      searchName: 'Ada göre ara',
      noContacts: 'Mesaj gönderebileceğiniz kimse yok',
      uploadFailed: 'Görsel yüklenemedi',
      sendFailed: 'Gönderilemedi — bağlantınızı kontrol edip tekrar deneyin',
      stillFailing: 'Hâlâ gönderilemedi',
      gallery: 'Galeriden',
      camera: 'Fotoğraf çek',
      imageSize: 'En büyük görsel boyutu 5 MB',
      editTitle: 'Mesajı düzenle',
      deleteTitle: 'Mesajı sil',
      deleteBody: 'Sizin ve karşı tarafın için silinecek ve geri alınamaz.',
      deleteFailed: 'Silinemedi — bağlantınızı kontrol edin',
      unmute: 'Sesi aç',
      start: 'Konuşmayı başlatın',
      deleted: 'Bu mesaj silindi',
      notSent: 'Gönderilmedi — yeniden denemek için dokunun',
      sending: 'Gönderiliyor...',
      edited: ' · düzenlendi',
      attach: 'Görsel ekle',
      caption: 'Açıklama ekleyin (isteğe bağlı)...',
      cantReply: 'Şu anda bu kullanıcıya mesaj gönderemezsiniz',
      mute: 'Sessize al',
      write: 'Mesajınızı yazın...',
    ),
    dash: SDash(
      takeAttendance: 'Yoklama al',
      addStudent: 'Öğrenci ekle',
      serdSession: 'Serd oturumu',
      newAnnouncement: 'Yeni duyuru',
      calendar: 'Takvim',
      title: 'Kontrol paneli',
      greeting: '{v} — esselâmü aleyküm',
      yourCirclesToday: 'Bugünkü halkalarınız',
      noCircle: 'Henüz bir halkaya atanmadınız — yöneticiden sizi eklemesini isteyin.',
      notWorkingDay: 'Bugün merkezinizde çalışma günü değil',
      studentsN: '{students} öğrenci',
      recitedN: 'Dinleten {recited}',
      presentN: 'Gelen {present}',
      absentN: 'Gelmeyen {absent}',
      students: 'Öğrenciler',
      teachers: 'Öğretmenler',
      circles: 'Halkalar',
      todayAttendance: 'Bugünkü yoklama',
      shortcuts: 'Hızlı kısayollar',
      centerAdmin: 'Merkez yönetimi',
      waitSerd: 'Onay bekleyen serd',
      waitMarket: 'Karar bekleyen market talepleri',
      waitGatherings: 'Bağlanacak isimleri olan toplantılar',
      waitExternal: 'Bağlanacak dış dinletmeler',
      needsYou: 'İlginizi bekleyenler',
      nothingWaiting: 'Sizi bekleyen bir şey yok ✓',
      inactiveN: 'İki haftadır dinletme yok ({inactive_total})',
      thisWeek: 'Bu hafta',
      weekRecitations: '{recitations} dinletme',
      weekReciting: '{reciting_students} öğrenci dinletti',
      weekPoints: '{points} puan',
      weekAttendance: 'Devam {v}',
      upcomingEvents: 'Yaklaşan etkinlikler',
      notYet: 'Henüz dinletmedi',
      registered: 'kayıtlı',
      dropoutRisk: 'Bırakma riski',
      noRisk: 'Bırakma riski olan öğrenci yok ✓',
      teacherPerf: 'Öğretmen etkinliği (7 gün)',
      recitationsWord: 'dinletme',
      riskTags: {'never': 'Hiç dinletmedi', 'regressed': 'Düzenliyken bıraktı', 'slowing': 'Yavaşlıyor', 'attendance_gap': 'Geliyor ama dinletmiyor'},
      idleDays: '{n} çalışma günü',
      perfLine: '{circles} halka · {students} öğrenci · {days} gün geldi',
    ),
    fees: SFees(
      title: 'Ücretler',
      collectedMonth: 'Bu ay tahsil edilen',
      outstanding: 'Öğrencilerin borcu',
      owingN: 'Borçlu',
      filter: {'all': 'Tümü', 'owing': 'Borçlu', 'noPlan': 'Plansız'},
      search: 'Öğrenci adı veya numarasıyla ara',
      none: 'Öğrenci yok',
      exempt: 'Muaf',
      discountV: '%{n} indirim',
      noPlan: 'Plan yok',
      owes: 'Borcu var',
      credit: 'Alacaklı',
      settled: 'Borç yok',
      dueSoFar: 'Bugüne kadar ödenecek',
      paidTotal: 'Ödenen',
      upcoming: 'Yaklaşan ücretler',
      plan: 'Plan: {name}',
      periods: {'monthly': 'Aylık', 'term': 'Dönemlik', 'once': 'Tek seferlik'},
      recordTitle: 'Ödeme kaydet',
      amount: 'Tutar',
      amountInvalid: 'Geçerli bir tutar girin',
      method: 'Ödeme yöntemi',
      methods: {'cash': 'Nakit', 'transfer': 'Havale', 'card': 'Kart', 'wallet': 'E-cüzdan', 'other': 'Diğer'},
      paidOn: 'Ödeme tarihi: {date}',
      note: 'Not (isteğe bağlı)',
      record: 'Ödemeyi kaydet',
      recorded: 'Ödeme kaydedildi ✓',
      outbox: 'Ödeme {name}: {amount}',
      pendingUpload: 'Yüklenmeyi bekliyor',
      charges: 'Ücretler',
      payments: 'Ödemeler',
      status: {'open': 'Ödenecek', 'waived': 'Muaf tutuldu', 'cancelled': 'İptal edildi'},
      notYetDue: 'Henüz vadesi gelmedi',
      waive: 'Muaf tut',
      cancelCharge: 'Ücreti iptal et',
      reopen: 'Yeniden aç',
      cancelChargeConfirm: 'Bu ücret iptal edilsin mi? (giriş hatası için; bağışlamak için “Muaf tut”u kullanın)',
      receiptNo: 'Makbuz no. {n}',
      receiptTitle: 'Tahsilat makbuzu',
      voidPayment: 'Ödemeyi iptal et',
      voidReason: 'Neden (isteğe bağlı)',
      voidConfirm: 'Bu ödeme iptal edilsin mi? Makbuz “İptal” damgasıyla kayıtlı kalır.',
      voided: 'İptal',
      noCharges: 'Ücret yok',
      noPayments: 'Ödeme yok',
      balanceAfter: 'Öğrencinin kalan borcu',
      byLabel: 'Teslim alan',
      share: 'Paylaş',
      receiptText: '{center}\n{title} — {no}\n{student}\n{amount} · {date} · {method}\n{left}',
      manageOnWeb: 'Planlar, öğrencilere atanmaları, ayarlar ve rapor web panelindedir.',
      adminOnly: 'Ücretleri yalnızca yönetici yönetir',
      openAccount: 'Ücret hesabı',
    ),
    garden: SGarden(
      online: 'Çevrimiçi',
      offline: 'Çevrimdışı',
      noInternet: 'Ağda internet yok',
      syncCenter: 'Eşitleme merkezi',
      offlineWaiting: 'Çevrimdışı · {n} bekliyor',
      syncing: 'Yükleniyor',
      waitingN: '{n} bekliyor',
      failedN: '{n} yüklenmedi',
      tabHome: 'Ana sayfa',
      tabStudents: 'Öğrenciler',
      tabSerd: 'Serd',
      tabChat: 'Mesajlar',
      tabMore: 'Daha fazla',
      seeAll: 'Tümünü gör',
      moreTitle: 'Tüm bölümler',
      checkedInShort: 'Giriş yapıldı',
      checkInShort: 'Giriş yap',
      studentsN: 'Öğrenciler ({n})',
      statCircles: 'Halkalar',
      statStudents: 'Öğrenciler',
      statRecited: 'Dinleten',
      statPresent: 'Gelen',
      quickTitle: 'Kısayollar',
      account: 'Hesap',
      notificationPrefs: 'Bildirim tercihleri',
      statJuz: 'Cüz',
      statPoints: 'Puan',
      statStreak: 'Gün serisi',
      explore: 'Keşfet',
      statAttendance: 'Devam',
      itemsN: '{n} öğe',
    ),
    gather: SGather(
      noCircle: 'Halka yok',
      okLinked: 'İsim bağlandı',
      skippedSuffix: ' · {n} atlandı',
      actionFailed: 'Gerçekleşmedi — bağlantınızı kontrol edin',
      extNew: 'Dış dinletme',
      studentName: 'Öğrenci adı',
      type: 'Tür',
      surah: 'Sure',
      fromAyah: 'Başlangıç ayeti',
      toAyah: 'Bitiş ayeti',
      grade: 'Not',
      extUpload: 'Dinletmeyi yükle',
      extUploaded: 'Dinletme yüklendi; yöneticinin bağlaması bekleniyor',
      extLinked: 'Dinletme bağlandı ve öğrenciye kaydedildi (+{v} puan)',
      rejectTitle: 'Talebi reddet',
      reasonOpt: 'Neden (isteğe bağlı)',
      reject: 'Reddet',
      rejected: 'Talep reddedildi',
      extNewShort: 'Yeni dinletme',
      noRequests: 'Henüz talep yok',
      linked: 'Bağlandı',
      rejectedChip: 'Reddedildi',
      pending: 'Bağlanmayı bekliyor',
      linkedTo: '{matched_name} kişisine bağlandı',
      reasonV: 'Neden: {reject_reason}',
      pickStudent: 'Bir öğrenci seçin',
      deletedReq: 'Talep silindi',
      linkedAttended: 'İsim bağlandı ve öğrencinin devamı kaydedildi',
      addName: 'İsim ekle',
      name: 'Ad',
      add: 'Ekle',
      nameAdded: 'İsim eklendi',
      activity: 'Etkinlik',
      metaLine: '{session_date}{v}{v2} · yükleyen {v3}',
      namesN: 'İsimler ({n})',
      nameDeleted: 'İsim kaldırıldı',
      linkedLine: 'Bağlı: {matched_name} ({matched_code}){v}',
      skipped: 'Atlandı',
      skip: 'Atla',
      nameSkipped: 'İsim atlandı',
      unlink: 'Bağlantıyı kaldır',
      uploadNew: 'Yeni etkinlik yükle',
      activityName: 'Etkinlik adı',
      activityType: 'Etkinlik türü',
      none: '— Yok —',
      placeOpt: 'Yer (isteğe bağlı)',
      attendees: 'Katılanlar — her satıra bir isim',
      uploadBtn: 'Etkinliği yükle',
      uploadedN: 'Etkinlik {n} isimle yüklendi',
      uploadFailed: 'Yükleme başarısız — bağlantınızı kontrol edin',
      upload: 'Etkinlik yükle',
      empty: 'Henüz yüklenmiş etkinlik yok',
      countsLine: '{total} isim · {matched} bağlı{v}',
      reviewed: 'İncelendi',
      pendingN: 'Bekleyen ({pending})',
      waitingAdmin: 'Yönetici bekleniyor',
      pickStudentTitle: 'Öğrenciyi seçin',
      searchPh: 'Öğrenci adı veya numarası',
    ),
    ins: SIns(
      guardianVisibleSuffix: ' · veliye görünür',
      overdueSuffix: ' · {n} gün gecikmiş',
      noCircle: 'Halka yok',
      auditActions: {'delete': 'Silindi', 'update': 'Düzenlendi', 'create': 'Eklendi'},
      auditTables: {'students_profile': 'öğrenci', 'circles': 'halka', 'stages': 'aşama', 'serd_sessions': 'serd oturumu', 'organization_members': 'üye'},
      newNote: 'Yeni not',
      notePh: 'ör. ayet sonlarında acele ediyor',
      guardianVisible: 'Veliye görünür',
      noteFailed: 'Not kaydedilemedi',
      notesTitle: 'Öğretmen notları',
      noNotes: 'Henüz not yok',
      searchFailed: 'Arama başarısız. Bağlantınızı kontrol edin.',
      searchPh: 'Ara: öğrenci, öğrenci numarası, öğretmen, halka',
      noResults: 'Sonuç yok',
      students: 'Öğrenciler',
      staff: 'Öğretmenler ve yöneticiler',
      admin: 'Yönetici',
      teacher: 'Öğretmen',
      circles: 'Halkalar',
      reviewsTitle: 'Bugün önerilen tekrar',
      noReviews: 'Bugün tekrar zamanı gelen yok ✓',
      reviewsHint: 'Her sure, iyi notlarla uzayan ve zayıf notlarla bir güne inen bir aradan sonra geri gelir.',
      challengeTitleRequired: 'Yarışma başlığı zorunludur',
      newChallenge: 'Yeni yarışma',
      editChallenge: 'Yarışmayı düzenle',
      title: 'Başlık',
      description: 'Açıklama',
      metric: 'Ölçüt',
      deleteChallenge: 'Yarışmayı sil',
      sure: 'Emin misiniz?',
      challenge: 'Yarışma',
      noCircles: 'Henüz öğrencisi olan halka yok',
      boardLine: '{students} öğrenci  ·  toplam {total}',
      noChallenges: 'Yarışma yok',
      noAudit: 'Henüz kaydedilmiş işlem yok',
      auditHint: 'Hassas silme ve düzenlemeler burada görünür',
    ),
    live: SLive(
      title: 'Dinlet',
      hint: 'Sureyi ve bölümü seçip başlayın: ayetler gizlidir, her kelime doğru okuduğunuzda görünür. Bir kelimeyi unutur ya da yanlış okursanız durur ve sizi uyarır.',
      student: 'Öğrenci',
      surah: 'Sure',
      type: 'Tür',
      from: 'Ayetten',
      to: 'Ayete',
      start: 'Başla',
      unsupported: 'Bu tarayıcı canlı dinletmeyi desteklemiyor. Chrome veya Edge ya da Bustan Al-Quran uygulamasını kullanın.',
      micDenied: 'Mikrofon izni verilmedi. Ayarlardan izin verip tekrar deneyin.',
      network: 'Konuşma tanıma internet bağlantısı gerektirir.',
      listening: 'Dinliyorum… ezberden okuyun',
      paused: 'Duraklatıldı',
      progress: '{total} kelimeden {n}',
      mistakesN: 'Hatalar: {n}',
      stopMissing: 'Dur: bir kelime unutuldu',
      stopWrong: 'Dur: bir kelime yanlış',
      correctIs: 'Doğrusu:',
      heard: 'Duyduğum: {w}',
      resume: 'Devam',
      forgot: 'Hatırlamıyorum',
      finish: 'Bitir ve gönder',
      result: 'Sonuç',
      score: '%{n} doğru',
      mistakeList: 'Hatalı kelimeler:',
      resultNote: 'Sonuç cihazınızın konuşma tanımasından gelir; dinletmeyi öğretmeniniz onaylar.',
      note: 'Öğretmene not (isteğe bağlı)',
      send: 'Öğretmene gönder',
      sending: 'Gönderiliyor…',
      sent: 'Öğretmeninize gönderildi. Karar size bildirilecek.',
      again: 'Yeniden dinlet',
      appAudio: 'Sesiniz baştan kaydedilir ve öğretmeniniz dinlesin diye sonuçla birlikte gönderilir.',
      recording: 'Kayıt',
      withAudio: 'Ses kaydı ekli ({t})',
      retry: 'Tekrar gönder',
      notSent: 'Dinletme henüz gönderilmedi. Bağlantıyı kontrol edip “Tekrar gönder”e dokunun.',
      nothingHeard: 'Okumadan hiçbir şey duyulmadı, bu yüzden gönderilmedi. Mikrofonu kontrol edip yeniden dinletin.',
      mine: 'Dinletmelerim',
      error: 'Bir hata oluştu. Tekrar deneyin.',
      fab: 'Dinlet',
      liveBadge: 'Canlı dinletme',
      loading: 'Ayetler yükleniyor…',
      appNoAudio: 'Uygulamada dinletme ses kaydı olmadan sonucuyla gönderilir.',
      appUnsupported: 'Bu cihazda konuşma tanıma yok. Google uygulamasını yükleyin veya cihaz ayarlarından konuşma tanımayı açın.',
    ),
    mem: SMem(
      modules: {'students': 'Öğrenciler', 'circles': 'Halkalar', 'attendance': 'Yoklama', 'serd': 'Kur’an serdi ve dinletme talepleri', 'points': 'Puanlar', 'badges': 'Rozetler', 'market': 'Puan marketi', 'circle-challenges': 'Halka yarışmaları', 'activities': 'Etkinlikler', 'calendar': 'Takvim', 'announcements': 'Duyurular', 'chat': 'Mesajlar', 'notifications': 'Bildirimler', 'reports': 'Raporlar', 'certificates': 'Sertifikalar'},
      status: {'active': 'Aktif', 'invited': 'Davet edildi', 'suspended': 'Askıya alındı'},
      password8: 'Şifre en az 8 karakter olmalıdır',
      passwordChanged: 'Şifre değiştirildi',
      accountSaved: 'Hesap durumu kaydedildi',
      removeTitle: 'Merkezden çıkar',
      removeBody: '“{fullName}” merkezden çıkarılsın mı? Buradaki tüm erişimini hemen kaybeder.',
      editTitle: 'Üyeyi düzenle',
      selfNote: 'Burada kendi erişiminizi değiştiremez veya kaldıramazsınız — varsa başka bir yöneticiye sorun.',
      role: 'Rol',
      statusLabel: 'Durum',
      modulesTitle: 'Erişebileceği bölümler',
      viewOnly: 'Yalnızca görüntüleme hesabı',
      viewOnlyHint: 'Görür ama değiştiremez: rolü aynı kalır, ancak bu merkezde yaptığı hiçbir değişiklik kaydedilmez.',
      changePassword: 'Şifreyi değiştir',
      newPassword: 'Yeni şifre (en az 8 karakter)',
      teacherCreated: 'Öğretmen hesabı oluşturuldu',
      newTeacher: 'Yeni öğretmen',
      teacherHint: 'Öğretmen merkez kodu + numarası (veya e-postası) + şifresiyle giriş yapar.',
      required: 'Zorunlu',
      loginId: 'Giriş numarası veya e-posta',
      min8: 'En az 8 karakter',
      createAccount: 'Hesabı oluştur',
      inviteCreated: 'Davet oluşturuldu',
      inviteError: 'Davette bir sorun oluştu',
      inviteTitle: 'Yeni üye davet et',
      email: 'E-posta',
      inviteBtn: 'Davet oluştur',
      pendingInvites: 'Henüz kabul edilmemiş davetler',
      contactTitle: 'İletişim',
      contactHint: 'Tercihen ülke koduyla, ör. +962791234567',
    ),
    mistakes: SMistakes(
      title: 'Tekrarlanan hatalar',
      hint: 'Son {days} gündeki öğretmen sınavlarından ve kayıtlı dinletmelerin otomatik kontrolünden. Tekrarda bunlara odaklanın.',
      summary: '{sessions} dinletme · {mistakes} hata',
      bySurah: 'Sureye göre',
      byAyah: 'En çok hata yapılan ayetler',
      byWord: 'En çok hata yapılan kelimeler',
      times: '×{n}',
      none: 'Bu dönemde kayıtlı hata yok.',
      ayah: '{surah} : {ayah}',
    ),
    mkt: SMkt(
      rateTitle: 'Puan dönüşüm oranı',
      perPoints: 'Her (puan)',
      equals: '= (değer)',
      currency: 'Para birimi simgesi',
      rateHint: 'Değişiklik yalnızca bundan sonra dönüştürülen puanlara uygulanır; önceki dönüşümler değerini korur.',
      rateInvalid: 'Tam sayılar ve bir para birimi simgesi girin',
      rateSaved: 'Oran kaydedildi',
      cancelOrder: 'Siparişi iptal et',
      cancelOrderBody: 'Bakiye ve stok iade edilecek. Emin misiniz?',
      no: 'Hayır',
      yes: 'Evet',
      orderCancelled: 'Sipariş iptal edildi',
      newItem: 'Yeni ürün',
      adminOnly: 'Marketi yalnızca yönetici yönetir',
      items: 'Ürünler',
      ordersN: 'Siparişler ({pending})',
      orders: 'Siparişler',
      balances: 'Bakiyeler',
      noOrders: 'Sipariş yok',
      delivered: 'Teslim edildi',
      walletLine: '{earnedPoints} puan  ·  harcanan {v}',
      disabled: 'Market şu anda kapalı (merkez ayarlarından açın)',
      rateLine: 'Her {pointsPerUnit} puan = {v}',
      rateSub: 'Puan-para dönüşüm oranı',
      noItems: 'Henüz ürün yok',
      unlimited: 'Sınırsız stok',
      stockN: 'Stok: {n}',
      inactiveSuffix: '  ·  pasif',
      nameRequired: 'Ad ve fiyat zorunludur',
      noUpload: 'Görsel yükleyemezsiniz',
      uploadFailed: 'Görsel yüklenemedi',
      tooBig3: 'Görsel çok büyük (en fazla 3 MB)',
      deleteItem: 'Ürünü sil',
      deleteItemBody: 'Önceki siparişler adını ve fiyatını korur. Emin misiniz?',
      editItem: 'Ürünü düzenle',
      name: 'Ad',
      description: 'Açıklama',
      uploadDevice: 'Cihazdan yükle',
      removeImage: 'Görseli kaldır',
      imageLink: 'Ya da görsel bağlantısını yapıştırın (https)',
      priceIn: 'Fiyat ({symbol})',
      stock: 'Stok (boş = sınırsız)',
      active: 'Etkin (öğrencilere gösterilir)',
    ),
    nav: SNav(
      items: {'/dashboard': 'Kontrol paneli', '/attention': 'İlgi bekleyen öğrenciler', '/review-plan': 'Günlük tekrar payları', '/sync': 'Eşitleme', '/students': 'Öğrenciler', '/circles': 'Halkalar', '/attendance': 'Yoklama', '/gatherings': 'Toplantılar ve etkinlikler', '/external-recitations': 'Dış dinletmeler', '/recitations': 'Kayıtlı dinletmeler', '/reviews': 'Önerilen tekrar', '/search': 'Ara', '/quran': 'Kur’an', '/serd': 'Kur’an serdi', '/stages': 'Aşamalar', '/points': 'Puanlar', '/badges': 'Rozetler', '/market': 'Puan marketi', '/circle-challenges': 'Halka yarışmaları', '/activities': 'Etkinlikler', '/announcements': 'Duyurular', '/calendar': 'Takvim', '/chat': 'Mesajlar', '/notifications': 'Bildirimler', '/reports': 'Raporlar', '/certificates': 'Sertifikalar', '/members': 'Üyeler ve roller', '/deletion-requests': 'Veri silme talepleri', '/audit': 'İşlem kaydı', '/site': 'Herkese açık sayfa', '/settings': 'Merkez ayarları', '/fees': 'Ücretler'},
      sections: {'teaching': 'Öğretim', 'motivation': 'Motivasyon', 'comms': 'İletişim', 'admin': 'Merkez yönetimi'},
      switchCenter: 'Merkez değiştir',
      menu: 'Menü',
    ),
    notif: SNotif(
      now: 'Şimdi',
      minutesAgo: '{n} dk önce',
      hoursAgo: '{n} sa önce',
      today: 'Bugün',
      yesterday: 'Dün',
      title: 'Bildirimler',
      markAll: 'Tümünü okundu say',
      prefs: 'Aldıklarım',
      none: 'Bildirim yok',
      notSaved: 'Değişiklik kaydedilmedi. Bağlantınızı kontrol edip tekrar deneyin.',
      noPush: 'Anlık bildirimler uygulamanın bu sürümünde etkin değil — bunları yalnızca uygulama içinde göreceksiniz.',
      noPermission: 'Uygulamanın bildirim göndermesine izin verilmedi. Telefonun Ayarlar → Uygulamalar → Bustan Al-Quran → Bildirimler bölümünü açıp etkinleştirin.',
      paused: 'Merkez bildirimleri şimdilik duraklattı — uygulama içi liste çalışmaya devam ediyor.',
      quiet: 'Telefon bildirimleri {from} ile {to} arasında bekletilir — sabah gelir.',
      events: {'announcement': 'Yeni duyuru', 'calendar_entry': 'Takvimde yeni etkinlik', 'center_closed': 'Tatil veya kapanış', 'event_reminder': 'Etkinlik hatırlatmaları', 'waitlist_promoted': 'Bekleme listesinden kayıt', 'serd_assigned': 'Bana atanan serd', 'serd_approved': 'Serd onayı', 'serd_rejected': 'Serd onaylanmadı', 'market_fulfilled': 'Market siparişi teslim edildi', 'market_cancelled': 'Market siparişi iptal edildi', 'badge_awarded': 'Rozetler', 'weekly_digest': 'Haftalık özet', 'attendance_reminder': 'Yoklama hatırlatması', 'teacher_checkin_reminder': 'Öğretmen giriş hatırlatması', 'student_idle_teacher': 'Öğretmen uyarısı: dinletmede geride kalan öğrenci', 'student_idle': 'Dinletmede geride kalan öğrenciye hatırlatma', 'student_absences': 'Yönetici uyarısı: tekrarlanan devamsızlık', 'deletion_request': 'Veri silme talepleri', 'deletion_reviewed': 'Veri silme talebimin sonucu', 'gathering_submitted': 'Yeni toplantı gönderildi', 'external_submitted': 'Yeni dış dinletme', 'external_reviewed': 'Dış dinletme sonucu', 'assistant_assigned': 'Yardımcı öğretmen ataması', 'billing_reminder': 'Abonelik hatırlatması', 'billing_reviewed': 'Ödeme inceleme sonucu', 'capacity_warning': 'Plan kapasitesi', 'billing_downgraded': 'Ücretsiz plana geçiş', 'fee_payment': 'Ücret ödeme makbuzu', 'fee_overdue': 'Ödenmesi gereken ücret hatırlatması', 'recitation_submitted': 'İncelenecek yeni kayıtlı dinletme', 'recitation_reviewed': 'Kayıtlı dinletme incelendi', 'wird_reminder': 'Bugünün virdi hatırlatması'},
      types: 'Bildirim türleri',
      instantTitle: 'Bildirimleri anında alın',
      instantBody: 'Telefon, bu uygulamanın bildirimlerini geciktirerek pil tasarrufu yapıyor. Mesajların gönderildiği anda gelmesi için kısıtlamasız çalışmasına izin verin.',
      instantBattery: 'Pil tasarrufunu kapat',
      instantBatteryHint: '“Tüm uygulamalar” → Bustan Al-Quran → “Optimize etme” veya “Kısıtlamasız” seçin.',
      instantAutostart: 'Otomatik başlatmaya izin ver',
      instantAutostartHint: '{maker} telefonlarda Bustan Al-Quran için “Otomatik başlat”ı açın, yoksa uygulama kapandığında bildirimler durur.',
      instantOk: 'Bildirimler bu telefona anında gelir',
    ),
    org: SOrg(
      circleStatus: {'active': 'Aktif', 'archived': 'Arşivlendi'},
      attStatus: {'present': 'Geldi', 'absent': 'Gelmedi', 'excused': 'İzinli', 'late': 'Geç kaldı'},
      outboxAttendance: 'Yoklama listesi {sessionDate} ({n} öğrenci)',
      saveErrorRetry: 'Kaydederken bir sorun oluştu — tekrar deneyin',
      deleteCircle: 'Halkayı sil',
      deleteCircleBody: 'Bu halka silinsin mi? Bu geri alınamaz.',
      editCircle: 'Halkayı düzenle',
      addCircle: 'Halka ekle',
      circleName: 'Halka adı',
      stage: 'Aşama',
      noStage: 'Aşama yok',
      teacher: 'Öğretmen',
      noTeacher: 'Öğretmen yok',
      capacity: 'Kapasite (öğrenci)',
      assistants: 'Yardımcı öğretmenler',
      assistantsHint: 'Yalnızca bu halka için halka öğretmeni erişimi alırlar ve “Yardımcı öğretmen” etiketiyle görünürler.',
      noOtherTeachers: 'Merkezde başka öğretmen yok',
      status: 'Durum',
      addCircleBtn: 'Halkayı ekle',
      noCircles: 'Henüz halka yok',
      noCirclesHint: 'İlk halkayı oluşturun, sonra ona öğrenci ekleyin',
      capacityN: 'Kapasite {capacity}',
      gradesLoadFailed: 'Notlar yüklenemedi',
      keyRule: 'Anahtar yalnızca küçük İngilizce harf/rakam/_ alır ve ad zorunludur',
      gradesSaved: 'Notlar kaydedildi',
      gradesTitle: 'Dinletme notları ve puanları',
      gradesHint: 'Not adları ve her birinin puanı. Puanlar kaydedildiğinde her dinletmede saklanır, bu yüzden değişiklikler yalnızca gelecekteki dinletmelere uygulanır.',
      name: 'Ad',
      points: 'Puan',
      addGrade: 'Yeni not ekle',
      keyField: 'Anahtar (ör. outstanding)',
      nameField: 'Ad (ör. Mükemmel)',
      saveGrades: 'Notları kaydet',
      gradesAdminOnly: 'Notları ve puanları yalnızca yönetici değiştirebilir.',
      stageTaken: 'Bu ad veya kod bu merkezde zaten kullanılıyor',
      deleteStage: 'Aşamayı sil',
      deleteStageBody: 'Bu aşama silinsin mi?',
      editStage: 'Aşamayı düzenle',
      addStage: 'Aşama ekle',
      stageName: 'Aşama adı',
      stageNamePh: 'Hazırlık',
      stageCode: 'Öğrenci numarasındaki aşama numarası (1-2 hane, ör. 2). Boş bırakılırsa aşama sırası kullanılır',
      stageOrder: 'Aşama sırası',
      addStageBtn: 'Aşamayı ekle',
      noStages: 'Henüz aşama yok',
      noStagesHint: 'Aşamalar halkaları düzenler ve öğrencileri numaralandırmada kullanılır',
      orderN: 'Sıra {sortOrder}',
      circlesLoadFailed: 'Halkalar yüklenemedi',
      studentsLoadFailed: 'Halkanın öğrencileri yüklenemedi',
      attSaved: 'Yoklama kaydedildi',
      saveAtt: 'Yoklamayı kaydet',
      circle: 'Halka',
      dateV: 'Tarih:  {v}',
      pickCircle: 'Yoklama almak için halkayı seçin',
      pickCircleHint: 'Sonra her öğrencinin durumunu belirleyip kaydedin',
      noStudents: 'Bu halkada öğrenci yok',
      allPresent: 'Herkesi geldi olarak işaretle',
      deleteActivity: 'Etkinliği sil',
      deleteActivityBody: 'Bu etkinlik silinsin mi?',
      editActivity: 'Etkinliği düzenle',
      newActivity: 'Yeni etkinlik',
      title: 'Başlık',
      description: 'Açıklama',
      whenOpt: 'Zaman (isteğe bağlı)',
      addActivity: 'Etkinlik ekle',
      noActivities: 'Henüz etkinlik yok',
      noActivitiesHint: 'Merkezin etkinliklerini herkesin görmesi için ekleyin',
      noTime: 'Belirli bir zaman yok',
      siteIntro: 'Merkezinizle ilgili, giriş yapmamış ziyaretçilere gösterilen herkese açık bir sayfa.',
      siteEnable: 'Herkese açık sayfayı aç',
      heroTitle: 'Başlık',
      heroBody: 'Tanıtım',
      contactEmail: 'İletişim e-postası',
      siteAdminOnly: 'Herkese açık sayfa ayarlarını yalnızca yönetici değiştirebilir.',
    ),
    plan: SPlan(
      graceTrial: '🍂 Deneme süresi bitti — bahçeniz sulanmayı bekliyor: web panelinden yenileyin',
      gracePaid: '🍂 Merkez aboneliği bitti — bahçeniz sulanmayı bekliyor: web panelinden yenileyin',
      soonTrial: '🌿 Deneme süresi {days} içinde bitiyor',
      soonPaid: '🌿 Merkez aboneliği {days} içinde bitiyor',
      days: {'one': '1 gün', 'two': '2 gün', 'many': '{n} gün'},
      students: {'one': '1 öğrenci', 'two': '2 öğrenci', 'many': '{n} öğrenci'},
      studentsFull: '🌳 Bahçe doldu: merkez öğrenci sınırına ulaştı ({max})',
      studentsLeft: '🌿 Plana {n} daha eklenebilir',
      teachersFull: '🌳 Merkez öğretmen sınırına ulaştı ({max})',
      oneTeacherLeft: '🌿 Plana yalnızca bir öğretmen daha eklenebilir',
    ),
    priv: SPriv(
      updated: 'Talep güncellendi',
      updateFailed: 'Güncellenemedi',
      requestsTitle: 'Veri silme talepleri',
      noRequests: 'Talep yok',
      reviewHint: '“Onayla”, hesabı ve verileri kendiniz sileceğiniz anlamına gelir; ardından talep sahibinin bilgilendirilmesi için “Silindi”ye basın.',
      student: 'Öğrenci: {name}',
      approve: 'Onayla',
      reject: 'Reddet',
      done: 'Silindi',
      confirmTitle: 'Hesabın ve verilerin silinmesini iste',
      confirmBody: 'Talebiniz incelenmek üzere merkez yönetimine gider. Emin misiniz?',
      sendRequest: 'Talebi gönder',
      sendFailed: 'Talep gönderilemedi',
      title: 'Hesabım ve verilerim',
      intro: '{org} merkezinden hesabınızı ve verilerinizi silmesini isteyebilirsiniz. Yönetim talebi inceler ve sonuçtan haberdar edilirsiniz. Bu yalnızca bu merkezi kapsar.',
      last: 'Son talep: {status}',
      reason: 'Neden (isteğe bağlı)',
      submit: 'Hesabımın ve verilerimin silinmesini iste',
    ),
    prof: SProf(
      thisMonth: 'Bu ay',
      lastMonth: 'Geçen ay',
      last90: 'Son 3 ay',
      vsPrev: 'Önceki dönemle karşılaştırma',
      same: 'Değişiklik yok',
      newV: 'Yeni',
      recitations: 'Dinletmeler',
      reciting: 'Dinleten öğrenciler',
      points: 'Puan',
      attendance: 'Devam',
      serdHeard: 'Dinlenen serd',
      serdApproved: 'Onaylanan serd',
      daysPresent: 'Gelinen günler',
      teacherDays: 'Öğretmenin geldiği günler',
      students: 'Öğrenciler',
      circles: 'Halkalar',
      assistant: 'Yardımcı',
      teacher: 'Öğretmen',
      assistants: 'Yardımcılar',
      recent: 'Son dinletmeler',
      teacherAtt: 'Öğretmen devamı',
      nothing: 'Bu dönemde bir şey yok',
      lastRec: 'Son: {v}',
      never: 'Henüz yok',
      today: 'Bugün',
      daysAgo: '{n} gün önce',
      profile: 'Profil',
      myProfile: 'Profilim ve sonuçlarım',
      message: 'Mesaj',
      call: 'Ara',
      notAllowed: 'Bu profile erişiminiz yok',
      goalTitle: 'Ezber hedefi ve hatim',
      memorized: '{total} sayfadan {n}',
      percentQuran: 'Kur’an’ın %{p}’i',
      pace: 'Gerçek tempo',
      paceV: '{n} sayfa/çalışma günü',
      goalPace: 'Hedef',
      goalPaceV: 'Günde {n} sayfa',
      sinceStart: 'Hedef başladığından beri: {expected} sayfadan {actual}',
      forecast: 'Beklenen bitiş',
      forecastGoal: 'Hedef temposunda',
      noPace: 'Son zamanlarda yeni ezber yok',
      noGoal: 'Henüz hedef belirlenmedi',
      goalStatus: {'ahead': 'Önde', 'on_track': 'Planda', 'behind': 'Geride', 'done': 'Tamamlandı'},
      setGoal: 'Hedef belirle',
      editGoal: 'Hedefi düzenle',
      pagesPerDay: 'Çalışma günü başına sayfa',
      targetPages: 'Sayfa olarak hedef (604 = tüm Kur’an)',
      note: 'Not (isteğe bağlı)',
      save: 'Kaydet',
      clearGoal: 'Hedefi kaldır',
      goalSaved: 'Hedef kaydedildi',
      invalidPages: '0,25 ile 20 arasında bir sayı girin',
      outboxGoal: '{name} için ezber hedefi',
      whatsapp: 'WhatsApp',
    ),
    quran: SQuran(
      title: 'Kur’an',
      surahs: 'Sureler',
      search: 'Sure adı veya numarasıyla ara',
      continueReading: 'Okumaya devam et',
      position: '{surah} — {ayah}. ayet',
      ayahs: '{n} ayet',
      noBookmarks: 'Yer imi yok',
      noBookmarksHint: 'Yer imi eklemek için Kur’an’da bir ayete dokunun',
      playFailed: 'Tilavet oynatılamadı — bağlantınızı kontrol edin',
      ayahOf: '{surah} — {ayah}. ayet',
      playFromHere: 'Buradan oynat',
      unmark: 'Yer imini kaldır',
      copyAyah: 'Ayeti kopyala',
      copied: 'Kopyalandı',
      smaller: 'Daha küçük yazı',
      bigger: 'Daha büyük yazı',
      loadFailed: 'Sure yüklenemedi — bağlantınızı kontrol edin',
      repeat: 'Ayeti tekrarla',
      noRepeat: 'Tekrar yok',
      prevAyah: 'Önceki ayet',
      nextAyah: 'Sonraki ayet',
      credit: 'Metin: Osmanî hat, Hafs rivayeti · Tilavetler: everyayah.com ve quran.com · Yedek metin: tanzil.net',
      bookmarks: 'Yer imleri',
      mark: 'Yer imi ekle',
      repeatN: 'Ayeti {n} kez tekrarla',
      play: 'Oynat',
      pause: 'Duraklat',
      sync: 'Dinleme',
      syncNone: 'Tüm sure (takip yok)',
      syncAyah: 'Ayeti takip et',
      syncWord: 'Kelimeyi takip et',
      reciter: 'Kâri',
      noTimings: 'Bu kâri için bu surede henüz kelime zamanlaması yok — ayet ayet takip ediliyor.',
      noSurahAudio: 'Bu sure için tam tilavet yok — "Ayeti takip et" seçin',
      fontSize: 'Yazı boyutu',
      testMode: 'Kendini sına',
      testHint: 'Sınama modu: ayetler gizli — açmak için bir ayete dokunun ya da tilaveti başlatın, onunla birlikte açılsın.',
      revealPage: 'Sayfayı aç',
      hidePage: 'Sayfayı gizle',
      prevPage: 'Önceki sayfa',
      nextPage: 'Sonraki sayfa',
      readingSettings: 'Okuma ayarları',
    ),
    rec: SRec(
      pickGrade: 'Dinletme notunu seçin',
      pickSurah: 'Sureyi seçin',
      enterRange: 'Ayet aralığını girin',
      rangeOrder: 'Son ayet ilk ayetle aynı veya ondan sonra olmalı',
      tooFar: '{v} suresinde yalnızca {v2} ayet var',
      partial: '{saved} kaydedildi; geri kalanı kaydedilemedi: {message}',
      newTitle: 'Bugünün ilerlemesini kaydet',
      editTitle: 'Dinletmeyi düzenle',
      prefilled: 'Önerilen tekrar planından dolduruldu — gerekirse değiştirin',
      dateToday: 'Dinletme tarihi: bugün',
      dateV: 'Dinletme tarihi: {day}.{month}.{year}',
      type: 'İlerleme türü',
      addSurah: 'Bu oturuma başka bir sure ekle',
      grade: 'Dinletme notu',
      notes: 'Öğretmen notları (isteğe bağlı)',
      saveBtn: 'Dinletmeyi kaydet',
      saveEdit: 'Değişiklikleri kaydet',
      fromAyah: 'Başlangıç ayeti',
      toAyah: 'Bitiş ayeti',
      maxV: 'En fazla {max}',
      searchSurah: 'Sure adı veya numarasıyla ara',
      ayahsN: '{v} ayet',
      absenceFailed: 'Devamsızlık kaydedilemedi',
      lessonTitle: 'Ders modu',
      studentXofY: 'Öğrenci {v} / {n}',
      plan: 'Verilen planı',
      recordBtn: 'Dinletmeyi kaydet',
      absent: 'Gelmedi',
      later: 'Sonra',
      nobody: 'Bu halkada şu anda dinletmeyi bekleyen kimse yok',
      done: 'Ders bitti',
      summary: 'Dinleten {_recited}  •  gelmeyen {_absent}  •  ertelenen {n}',
      anotherRound: 'Kalanlar için bir tur daha',
      finish: 'Bitir ve geri dön',
      circle: 'Halka',
      doneToday: 'Bugün {total} öğrenciden {done} dinletti',
      outboxAttendance: 'Yoklama {studentName}: {status}',
      outboxRecitation: 'Dinletme {studentName} — {surah}. sure ({ayahFrom}–{ayahTo})',
      today: 'Bugün',
      dayMonth: '{day}.{month}',
      addNote: 'Not ekle',
      saveWithPoints: 'Dinletmeyi kaydet  •  +{n} puan',
      change: 'Değiştir',
      wholeSurah: 'Surenin tamamı',
    ),
    recite: SRecite(
      rangeTitle: 'Bölüm tekrarı',
      from: 'Ayetten',
      to: 'Ayete',
      times: 'Tekrar sayısı',
      rangeHint: 'Ayet {from} ile {to} arası {times} kez okunur. Her ayetin kendi tekrarı seçtiğiniz gibi kalır.',
      loop: '{total} turdan {n}.',
      rangeOff: 'Tekrarı kapat',
      recite: 'Dinlet',
      reciteTitle: 'Sisteme dinlet',
      reciteHint: 'Bölümü seçin, “Kaydı başlat”a basın ve ezberden okuyun. Kayıt sırasında ayetler gizlenir.',
      student: 'Öğrenci',
      type: 'Tür',
      start: 'Kaydı başlat',
      stop: 'Kaydı bitir',
      recording: 'Kaydediliyor… ezberden okuyun',
      micDenied: 'Mikrofon izni verilmedi. Tarayıcı ayarlarından izin verip tekrar deneyin.',
      micMissing: 'Bu tarayıcı kayıt yapamıyor.',
      tooLong: 'Kayıt en fazla {n} dakika olabilir; bölümü bölün.',
      uploading: 'Kayıt yükleniyor…',
      checking: 'Dinletme kontrol ediliyor…',
      uploadFailed: 'Kayıt yüklenemedi. Tekrar deneyin.',
      result: 'Sonuç',
      score: '%{n} uyum',
      correct: 'doğru',
      missing: 'eksik',
      wrong: 'farklı',
      extra: 'fazla',
      legend: 'Eksik kelimeler kırmızı, farklı kelimeler turuncu gösterilir.',
      unavailable: 'Otomatik kontrol şu an yapılamıyor. Kaydı yine de öğretmeninize gönderebilirsiniz.',
      autoNote: 'Otomatik kontrol yaklaşıktır: eksik veya farklı kelimeleri bulur, tecvid ve harekeleri değerlendirmez. Esas olan öğretmenin kararıdır.',
      note: 'Öğretmene not (isteğe bağlı)',
      send: 'Öğretmene gönder',
      sent: 'Öğretmeninize gönderildi. Karar size bildirilecek.',
      again: 'Yeniden kaydet',
      cancel: 'İptal',
      testStudent: 'Öğrenci sına',
      testTitle: 'Mushafta öğrenci sınavı',
      testHint: 'Ayetler gizli: açmak için ayete dokunun, sonra öğrencinin hata yaptığı kelimeye dokunarak işaretleyin (kaldırmak için tekrar dokunun).',
      mistakes: 'Hatalar: {n}',
      grade: 'Not',
      save: 'Öğrencinin kaydına ekle',
      saved: '{name} kaydına eklendi (+{points} puan).',
      chooseStudent: 'Öğrenciyi seçin',
      noStudents: 'Sınayabileceğiniz öğrenci yok.',
      badRange: 'Geçersiz bölüm.',
      error: 'Bir hata oluştu. Tekrar deneyin.',
      myTitle: 'Kayıtlı dinletmelerim',
      inboxTitle: 'Kayıtlı dinletmeler',
      inboxHint: 'Öğrencilerinizin mushaftan gönderdiği dinletmeler. Dinleyin, sonra öğrencinin kaydına eklemek için onaylayın ya da notla geri gönderin.',
      pending: 'Bekleyen',
      reviewed: 'İncelenen',
      none: 'Dinletme yok.',
      approve: 'Onayla',
      reject: 'Geri gönder',
      rejectNote: 'Sebep ya da öğrenciye not',
      teacherNote: 'Öğretmenin notu: {note}',
      studentNote: 'Öğrencinin notu: {note}',
      autoScore: 'Otomatik kontrol %{n}',
      noAuto: 'Otomatik kontrol yok',
      heardAs: 'Farklı okunan kelimeler:',
      missingWords: 'Eksik kelimeler:',
      openMushaf: 'Mushafta aç',
      teacherTest: 'Öğretmen sınavı',
      markedMistakes: 'İşaretlenen hatalar: {list}',
      statusDraft: 'Gönderilmedi',
      statusSubmitted: 'Öğretmen bekleniyor',
      statusApproved: 'Onaylandı',
      statusRejected: 'Geri gönderildi',
      reviewedBy: '{name} inceledi',
      ayahRange: '{surah} suresi {from}–{to}',
      waitingN: 'İncelemenizi bekleyen {n} kayıtlı dinletme',
      recheck: 'Otomatik kontrolü yeniden çalıştır',
      testNote: 'Not (isteğe bağlı)',
      micDeniedApp: 'Mikrofon izni verilmedi. Cihaz ayarlarından izin verip tekrar deneyin.',
      play: 'Dinle',
      apply: 'Uygula',
    ),
    rep: SRep(
      from: 'Başlangıç {date}',
      to: 'Bitiş {date}',
      title: 'Raporlar',
      loadFailed: 'Rapor yüklenemedi',
      activeStudents: 'Aktif öğrenciler',
      newStudents: 'Yeni öğrenciler',
      recitations: 'Dinletmeler',
      recitingStudents: 'Dinleten öğrenciler',
      points: 'Puan',
      attendanceRate: 'Devam oranı',
      serdApproved: 'Onaylanan serd',
      certsIssued: 'Düzenlenen sertifikalar',
      copied: 'Rapor özeti kopyalandı',
      copySummary: 'Özeti kopyala',
      types: 'Dinletme türleri',
      attendance: 'Devam',
      circles: 'Halkalar',
      teachers: 'Öğretmenler',
      top: 'En çok puan',
      studentTitle: 'Öğrenci raporu',
      student: 'Öğrenci',
      noStudent: 'Hesabınıza bağlı öğrenci yok',
      teacher: ' · Öğretmen: {name}',
      periodRecitations: 'Dönemdeki dinletmeler',
      periodPoints: 'Dönemdeki puan',
      totalPoints: 'Toplam puan',
      progress: 'İlerleme',
      savedParts: 'Ezberlenen cüzler',
      serd: 'Kur’an serdi',
      badges: 'Rozetler',
      certificates: 'Sertifikalar',
      log: 'Dinletme kaydı',
      none: 'Bu dönemde dinletme yok',
      circleLine: '{teacher} · {students} öğrenci\\n{recitations} dinletme · {points} puan · {attendance} devam',
      teacherLine: '{recitations} dinletme · {points} puan',
      sumTitle: '{center} raporu',
      sumActive: 'Aktif öğrenciler: {students_active}',
      sumPoints: 'Puan: {points}',
      sumAttendance: 'Devam oranı: {v}',
      sumSerd: 'Onaylanan serd: {serd_approved}',
      sumRecitations: 'Dinletmeler: {recitations} ({reciting_students} öğrenci)',
      sumCircle: '• {name}: {recitations} dinletme, devam {v}',
    ),
    rplan: SRplan(
      title: 'Günlük tekrar payları',
      hint: 'Sistem her öğrenci için ezberlediklerinin sıradaki sayfalarını önerir. Tek dokunuşla onaylayın; ardından öğrenci ve ailesi görür.',
      range: '{from} ile {to} arası',
      ayahRef: '{surah} {ayah}',
      pagesN: '{n} sayfa (s. {a}–{b})',
      approve: 'Onayla',
      approveAll: 'Tümünü onayla',
      approvedN: '{n} onaylandı',
      recite: 'Dinlet',
      skip: 'İptal',
      status: {'suggested': 'Önerildi', 'approved': 'Onaylandı', 'done': 'Tamamlandı ✓', 'pending': 'Yüklenmeyi bekliyor'},
      none: 'Henüz ezberlenmiş sayfası olan öğrenci yok',
      cycleStart: 'Yeni bir tur başlıyor',
      today: 'Bugünün tekrarı',
      reviewPages: 'Günlük tekrar sayfası (boş = otomatik)',
      outbox: '{name} için tekrarı onayla',
    ),
    serd: SSerd(
      overdueSuffix: '  ·  gecikmiş',
      inactiveSuffix: '  ·  pasif',
      passSuffix: '  ·  geçme %{n}',
      wholeJuz: 'Tam cüz',
      noCircle: 'Halka yok',
      linkStudent: 'Serdi bir öğrenciye bağla',
      approved: 'Onaylandı',
      rejectTitle: 'Serdi reddet',
      rejectReason: 'Reddetme nedeni (isteğe bağlı)',
      reject: 'Reddet',
      rejected: 'Reddedildi',
      deleteTitle: 'Serdi sil',
      deleteBody: 'Bu serd silinecek ve onaylanmışsa puanları düşülecek. Emin misiniz?',
      deleted: 'Silindi',
      approve: 'Onayla',
      reapprove: 'Yeniden onayla',
      certIssued: 'Sertifika düzenlendi — sertifikalar ekranında bulabilirsiniz',
      issueCert: 'Sertifika düzenle',
      schedule: 'Serd planla',
      report: 'Rapor',
      settings: 'Ayarlar',
      record: 'Serd kaydet',
      all: 'Tümü',
      pending: 'Onay bekliyor',
      scheduled: 'Planlandı',
      approvedChip: 'Onaylandı',
      rejectedChip: 'Reddedildi',
      empty: 'Serd yok',
      requestedN: 'İstenen serd ({n})',
      assigned: 'Size atandı',
      openAny: 'Açık — herhangi bir öğretmen kaydedebilir{v}',
      recordShort: 'Kaydet',
      mine: 'Serdlerim',
      mineEmpty: 'Henüz serd kaydetmediniz. “Serd kaydet” düğmesini kullanın.',
      saved: 'Kaydedildi',
      wholeAlways: 'Tam cüz (her zaman)',
      newErrorType: 'Yeni hata türü',
      editErrorType: 'Hata türünü düzenle',
      name: 'Ad',
      perErrors: 'Her (hata)',
      deductPct: '= % kesinti',
      active: 'Etkin',
      fillAll: 'Adı ve sayıları doldurun',
      stagePortions: 'Bu aşama için izin verilen miktarlar',
      stagePass: 'Kendi geçme notu % (genel için boş bırakın)',
      settingsTitle: 'Serd ayarları',
      settingsHint: 'Değişiklikler yalnızca gelecekteki serdlere uygulanır; önceki serdler puanını, ödülünü ve geçme notunu korur.',
      general: 'Tüm merkez',
      passPct: 'Geçme notu %',
      wholePoints: 'Tam cüz için puan',
      defaultPortions: 'Varsayılan izin verilen miktarlar',
      wholeNumbers: 'Tam sayılar girin',
      saveGeneral: 'Genel ayarları kaydet',
      errorTypes: 'Hata türleri ve ağırlıkları',
      perRule: 'Her {errorsPerUnit} = %{percentPerUnit}{v}',
      byStage: 'Aşamaya göre',
      byStageHint: 'Küçük bir aşama yarım veya çeyrek cüz okuyabilir ve kendi geçme notu olabilir.',
      usesGeneral: 'Genel ayar',
      pickOrType: 'Öğrenciyi seçin veya adını yazın',
      pickPart: 'En az bir cüz seçin',
      sentScore: 'Onaya gönderildi ✓  puan %{score}',
      saveFailedNet: 'Kaydedilemedi; internetinizi kontrol edip tekrar deneyin',
      newTitle: 'Yeni serd kaydet',
      scheduledTitle: 'Planlanmış serdi kaydet',
      pickStudent: 'Öğrenciyi seçin',
      typeName: 'Ya da öğrencinin adını yazın (halkalarınızın dışından)',
      clearPick: 'Seçimi temizle',
      dateLine: 'Serd tarihi: {day}.{month}.{year}',
      parts: 'Okunan cüzler',
      errors: 'Hata sayısı',
      perRule2: 'Her {errorsPerUnit} = %{percentPerUnit}',
      expected: 'Beklenen puan: %{v}  ·  geçme notu %{passPercent}',
      notesOpt: 'Notlar (isteğe bağlı)',
      submit: 'Onaya gönder',
      noResults: 'Sonuç yok',
      reportTitle: 'Serd raporu',
      totalSessions: 'Toplam oturum',
      waiting: 'Bekleyen',
      avgScore: 'Ortalama puan',
      pointsGiven: 'Verilen puan',
      approvedParts: 'Onaylanan cüzler',
      juzLine: '{juz}. cüz — {v}',
      topErrors: 'En sık hatalar (onaylanan)',
      examiners: 'Dinleyenler',
      partsLine: '{v}  ({v2} cüz)',
      examiner: 'Dinleyen: {examinerName}',
      circleTeacher: 'Halka öğretmeni: {circleTeacherName}',
      assignedTo: '{assignedTeacherName} kişisine atandı',
      openToAny: 'Her öğretmene açık',
      noStudent: 'Bir öğrenciye bağlı değil',
      scoreLabel: 'Puan: ',
      resultLine: '  ·  {v} (geçme notu {passApplied})  ·  +{pointsAwarded} puan',
      rejectReasonV: 'Reddetme nedeni: {rejectReason}',
      whole: 'Tam',
      pickJuz: 'Cüzü seçin',
      juzLine2: '{juz}. cüz — {v}',
      addJuz: 'Başka bir cüz ekle',
      passed: 'geçti',
      repeat: 'tekrar',
      pickBoth: 'Öğrenciyi ve en az bir cüz seçin',
      scheduledOk: 'Serd planlandı',
      scheduleHint: 'Öğretmenlere gösterilen bir görev; müsait olan kaydeder ya da tek bir öğretmene atanır.',
      student: 'Öğrenci',
      when: 'Tarih: {day}.{month}.{year}',
      partsWanted: 'İstenen cüzler',
      assign: 'Bir öğretmene ata',
      scheduleBtn: 'Serdi planla',
      outboxLabel: 'Serd {studentName} — {n} cüz',
      certDone: 'Sertifika verildi',
      issueAnother: 'Bir sertifika daha ver',
    ),
    set: SSet(
      loadSome: 'Bazı ayarlar yüklenemedi',
      saved: 'Ayarlar kaydedildi',
      fromGallery: 'Galeriden',
      takePhoto: 'Fotoğraf çek',
      tooBig1: 'Görsel çok büyük (en fazla 1 MB)',
      logoUploaded: 'Logo yüklendi — her yerde uygulamak için “Kimliği kaydet”e dokunun',
      logoAdminOnly: 'Logoyu yalnızca yönetici yükleyebilir',
      logoFailed: 'Logo yüklenemedi',
      logoHttps: 'Logo bağlantısı https ile başlamalıdır',
      backdateRange: 'Geriye tarih sınırı 0 ile 365 gün arasında olmalıdır',
      intro: 'Merkezinizle ilgili her şey burada özelleştirilebilir.',
      identity: 'Kimlik',
      name: 'Merkez adı',
      uploading: 'Yükleniyor...',
      uploadLogo: 'Cihazdan logo yükle',
      remove: 'Kaldır',
      logoLink: 'Ya da logo bağlantısı (https)',
      primary: 'Ana renk (hex)',
      secondary: 'İkincil renk (hex)',
      link: 'Merkez bağlantısı',
      timezone: 'Saat dilimi',
      saveIdentity: 'Kimliği kaydet',
      workdays: 'Çalışma günleri',
      workdaysHint: 'Devam oranları yalnızca çalışma günlerini sayar; serd günleri de işaretlenebilir.',
      working: 'Çalışma',
      serdDay: 'Serd',
      saveWorkdays: 'Çalışma günlerini kaydet',
      features: 'Dinletme ve özellik ayarları',
      backdate: 'Bir dinletmeye en fazla kaç gün geriye tarih verilebilir',
      countryCode: 'Telefon ülke kodu (ör. 90)',
      whatsapp: 'WhatsApp grup bağlantısı',
      locationLabel: 'Konum adı (namaz vakitleri ve takvim için)',
      lat: 'Enlem',
      lng: 'Boylam',
      method: 'Namaz vakti hesaplama yöntemi',
      madhab: 'Mezhep (şafii / hanefi)',
      reciters: 'Mushaftaki kârîler',
      recitersHint: 'Tüm kârîleri sunmak için boş bırakın.',
      defaultReciter: 'Varsayılan kârî',
      firstInList: 'Listedeki ilk',
      market: 'Puan marketini aç',
      tabs: {'identity': 'Kimlik', 'workdays': 'Çalışma günleri', 'features': 'Özellikler', 'contact': 'İletişim ve namaz', 'quran': 'Mushaf', 'notif': 'Bildirimler'},
      quranTitle: 'Mushaf ve kârîler',
      prayerMethods: {'umm_al_qura': 'Ümmü’l-Kurâ', 'muslim_world_league': 'Dünya Müslüman Birliği', 'egyptian': 'Mısır kurumu', 'karachi': 'Karaçi', 'dubai': 'Dubai', 'qatar': 'Katar', 'kuwait': 'Kuveyt', 'moon_sighting_committee': 'Hilal Gözlem Komitesi', 'singapore': 'Singapur', 'turkey': 'Türkiye', 'tehran': 'Tahran', 'north_america': 'Kuzey Amerika (ISNA)'},
      majority: 'Cumhur (Şâfiî / Mâlikî / Hanbelî)',
      hanafi: 'Hanefî',
      fees: 'Öğrenci ücretlerini aç (ücretli merkezler için)',
      leaderboard: 'Sıralama tablosunu aç',
      teacherStudents: 'Öğretmenlerin halkalarının öğrencilerini yönetmesine izin ver',
      saveSettings: 'Ayarları kaydet',
      adminOnly: 'Merkez ayarlarını yalnızca yönetici değiştirebilir.',
      loadOne: 'Ayar yüklenemedi',
      digestTitle: 'Haftalık aile özeti',
      digestHint: 'Her aileye haftalık bir bildirim: çocuğunun dinletmeleri, devamı ve puanları, merkezin saatine göre.',
      digestEnable: 'Haftalık özeti aç',
      day: 'Gün',
      hour: 'Saat',
      digestSaved: 'Haftalık özet ayarı kaydedildi',
      saveFailed: 'Kaydedilemedi',
      digestSub: 'Gün, saat ve açma/kapama',
      attTitle: 'Öğretmen yoklama hatırlatması',
      attHint: 'Çalışma günlerinde, belirlenen saatten sonra halkasının yoklaması alınmamışsa öğretmen bir hatırlatma alır.',
      attEnable: 'Hatırlatmayı aç',
      afterHour: 'Şundan sonra',
      attSaved: 'Hatırlatma ayarı kaydedildi',
      attTitle2: 'Öğretmene yoklama alma hatırlatması',
      attSub: 'Açma/kapama ve saat',
      language: 'Merkezin varsayılan dili',
      languageHint: 'Ekranlar, dil seçmemiş herkes için bu dilde görünür. Herkes menüden kendi dilini yine değiştirebilir.',
    ),
    stu: SStu(
      status: {'active': 'Aktif', 'paused': 'Durduruldu', 'graduated': 'Mezun', 'withdrawn': 'Ayrıldı'},
      noCircle: 'Halka yok',
      deleteTitle: 'Öğrenciyi sil',
      deleteBody: '“{fullName}” ve tüm dosyası (yoklama, serd, puanlar...) silinecek. Bu geri alınamaz.',
      title: 'Öğrenciler',
      add: 'Öğrenci ekle',
      searchPh: 'Ad veya öğrenci numarasıyla ara',
      empty: 'Henüz öğrenci yok',
      emptyHint: 'Aşağıdaki düğmeyle ilk öğrenciyi ekleyerek başlayın',
      noMatch: 'Eşleşen sonuç yok',
      editDetails: 'Bilgileri düzenle',
      deleteWithFile: 'Öğrenciyi ve dosyasını sil',
      circleRequired: 'Öğrenci için bir halka seçin',
      accountCreated: 'Öğrenci hesabı oluşturuldu',
      codeTaken: 'Bu öğrenci numarası bu merkezde zaten kullanılıyor',
      saveError: 'Kaydederken bir sorun oluştu',
      deleteBodyPlain: 'Öğrenci ve tüm dosyası (yoklama, serd, puanlar...) silinecek. Bu geri alınamaz.',
      editTitle: 'Öğrenciyi düzenle',
      details: 'Öğrenci bilgileri',
      fullName: 'Ad soyad',
      nameRequired: 'Öğrencinin adını girin',
      birthDate: 'Doğum tarihi (isteğe bağlı)',
      tapToPick: 'Seçmek için dokunun',
      stageCircle: 'Aşama ve halka',
      stage: 'Aşama',
      allStages: 'Tüm aşamalar',
      circleReq: 'Halka (zorunlu)',
      noCircles: 'Burada halka yok — önce halkalar bölümünde bir tane oluşturun',
      code: 'Öğrenci numarası',
      codeHint: 'Aşamayı seçtiğinizde otomatik önerilir; değiştirebilirsiniz',
      codeRequired: 'Öğrenci numarasını girin',
      contact: 'İletişim bilgileri',
      phone: 'Cep telefonu (isteğe bağlı)',
      whatsapp: 'WhatsApp numarası (isteğe bağlı)',
      address: 'Adres (isteğe bağlı)',
      login: 'Öğrenci giriş hesabı',
      password: 'Şifre',
      passwordHint: 'Giriş hesabı olmadan dosya oluşturmak için boş bırakın',
      min8: 'En az 8 karakter',
      email: 'Gerçek e-posta (isteğe bağlı)',
      emailHint: 'Olmadan, öğrenci numarası ve merkez koduyla giriş yapar',
      statusLabel: 'Durum',
      saveChanges: 'Değişiklikleri kaydet',
      addBtn: 'Öğrenciyi ekle',
      recEdited: 'Dinletme güncellendi',
      recDeleteTitle: 'Dinletmeyi sil',
      recDeleteBody: 'Bu dinletme silinecek ve puanları öğrencinin bakiyesinden düşülecek. Emin misiniz?',
      deleted: 'Silindi',
      nextPlan: 'Sonraki plan',
      planPh: 'ör. Mülk suresini ezberle, 1–15. ayetler',
      planSaved: 'Plan kaydedildi',
      linkUpdated: 'Bağlantı güncellendi',
      pickGuardian: 'Veliyi seçin',
      noGuardians: 'Henüz veli yok',
      newGuardian: 'Yeni veli hesabı',
      guardianName: 'Velinin adı',
      loginId: 'Giriş numarası veya e-posta',
      phoneOpt: 'Cep telefonu (isteğe bağlı)',
      password8: 'Şifre (en az 8 karakter)',
      create: 'Oluştur',
      guardianIncomplete: 'Adı, giriş numarasını ve en az 8 karakterlik bir şifreyi doldurun',
      guardianCreated: 'Veli hesabı oluşturuldu',
      allRecitations: 'Tüm dinletmeler',
      streak: 'Gün serisi',
      weeklyAttendance: 'Haftalık devam',
      lastRecitation: 'Son dinletme',
      surahV: '{v} suresi',
      recLine: '{type} • {ayahFrom}–{ayahTo}. ayetler',
      progress: 'İlerleme',
      partsOf30: '30 cüzden {totalParts}',
      weeklyAttendanceV: 'Haftalık devam: {v}',
      statsLine: '{totalRecitations} dinletme  ·  {currentStreak} günlük seri (en uzun {longestStreak})  ·  son dinletme {v}',
      noPlan: 'Henüz plan belirlenmedi',
      sheikh: 'Öğretmen',
      phone2: 'Cep telefonu',
      addressLabel: 'Adres',
      guardian: 'Veli',
      noGuardian: 'Bağlı veli yok',
      linkedTo: 'Bağlı: {v}',
      newAccount: 'Yeni hesap',
      linkExisting: 'Mevcut birine bağla',
      unlink: 'Bağlantıyı kaldır',
      log: 'Dinletme kaydı',
      noRecitations: 'Henüz dinletme yok',
    ),
    sync: SSync(
      title: 'Eşitleme',
      allUp: 'Her şey yüklendi',
      lastSync: 'Son başarılı yükleme: {time}',
      cached: 'Bağlantı olmadığı için kayıtlı veriler gösteriliyor',
      uploadNow: 'Şimdi yükle',
      nothing: 'Bekleyen bir şey yok',
      rejected: 'Sunucu tarafından reddedildi: {error}',
      discardTitle: 'Kuyruktan kaldırılsın mı?',
      discardBody: 'Bu kayıt asla yüklenmeyecek.',
      retry: 'Tekrar dene',
      stripFailed: 'Bazı kayıtlar reddedildi ({n}) — incelemek için dokunun',
      counts: 'Bekleyen: {waiting} · incelenecek: {failed}',
      nothingHint: 'Çevrimdışı kaydettikleriniz yüklenene kadar burada görünür.',
      queued: 'Kaydedildi {time} · deneme: {n}',
      stripWaiting: 'Yüklenmeyi bekleyen: {n} — bağlantı gelince otomatik yüklenir',
      stripOffline: 'Bağlantı yok — kayıtlı veriler gösteriliyor',
      offlineTitle: 'Çevrimdışı çalışma',
      offlineHint: 'İhtiyacınız olan her şey bu telefonda saklanır — halkalarınız, öğrencileriniz ve kayıtları, serd, takvim ve mesajlar — böylece uygulama internetsiz çalışır ve kaydettikleriniz bağlantı gelince kendiliğinden yüklenir.',
      offlineProgress: 'İndiriliyor… {total} içinden {done}',
      offlineNever: 'Bu telefona henüz bir şey indirilmedi',
      offlineLast: 'Son indirme: {time}',
      offlineNow: 'Şimdi indir',
      offlineNeedsNet: 'İnternet bağlantısı gerekir',
    ),
    teach: STeach(
      greeting: '{v}, {v2}',
      findStudent: 'Öğrenci bul',
      noCircle: 'Henüz bir halkaya atanmadınız',
      noCircleHint: 'Yöneticiden sizi bir halkaya eklemesini isteyin, sonra yenilemek için aşağı çekin.',
      yourCircles: 'Halkalarınız ({n})',
      checkedIn: 'Girişiniz kaydedildi ✓',
      checkInFailed: 'Giriş kaydedilemedi — bağlantınızı kontrol edin',
      circleScreen: 'Halka ekranı',
      assistant: 'Yardımcı öğretmen',
      stage: 'Aşama: {stageName}',
      doneOf: '{n} öğrenciden {done} dinletti',
      checkIn: 'Bugün girişimi yap',
      startLesson: 'Dersi başlat',
      savedPoints: 'Kaydedildi ✓  +{points} puan',
      attendanceFailed: 'Yoklama kaydedilemedi',
      noStudents: 'Bu halkada henüz öğrenci yok.\nYöneticiden eklemesini isteyin.',
      searchPh: 'Öğrenci adı veya numarasıyla ara',
      all: 'Tümü',
      notToday: 'Bugün dinletmedi',
      recitedToday: 'Bugün dinletti',
      sort: 'Listeyi sırala',
      alpha: 'Alfabetik',
      notFirst: 'Dinletmeyenler önce',
      topPoints: 'En çok puan',
      xOfY: '{n2} içinden {n}',
      noMatch: 'Seçiminize uyan kimse yok.',
      showAll: 'Tüm öğrencileri göster',
      pointsN: '{totalPoints} puan',
      recitedTodayN: 'Bugün dinletti ×{recitedToday}',
      dueReviews: 'Tekrar zamanı ({n})',
      takeAttendance: 'Yoklama al',
      attendanceIs: 'Yoklama: {value}',
      record: 'Dinletme kaydet',
      general: 'Genel',
    ),
    ui: SUi(
      credsText: 'Merkez kodu: {centerCode}\nNumara / e-posta: {loginId}\nŞifre: {password}',
      credsOnce: 'Şifre yalnızca bu kez gösterilir — şimdi kopyalayıp teslim edin.',
      copied: 'Kopyalandı',
      copy: 'Kopyala',
      done: 'Tamam',
      skeletonTitle: 'Öğrencinin tam adı burada',
      skeletonSub: 'Biraz ek bilgi',
      add: 'Ekle',
      search: 'Ara',
      noMatch: 'Eşleşen sonuç yok',
      channelName: 'Bustan Al-Quran bildirimleri',
      channelDesc: 'Mesajlar, hatırlatmalar ve onaylar',
      sessionEnded: 'Oturumunuz sona erdi; tekrar giriş yapın',
      requestFailed: 'İstek gerçekleşmedi',
      savedOffline: 'Cihazınıza kaydedildi; bağlantı gelince otomatik yüklenir',
      outboxCheckIn: 'Halkadaki girişim',
      outboxNote: 'Bir öğrenci hakkında not',
      outboxGathering: 'Etkinlik: {title}',
      outboxExternal: 'Dış dinletme: {name}',
      outboxEditRecitation: 'Dinletme düzenleme',
      outboxDeleteRecitation: 'Dinletme silme',
      outboxPlan: 'Bir öğrencinin sonraki planı',
      waitingUpload: 'Yüklenmeyi bekliyor',
    ),
    weekly: SWeekly(
      smartToggle: 'Akıllı haftalık rapor',
      smartHint: 'Ekler: ezber hedefi, önde mi geride mi, geçen haftayla karşılaştırma ve öğretmenin notu',
      title: 'Haftalık rapor',
      period: '{from} – {to}',
      thisWeek: 'Bu hafta',
      lastWeek: 'Geçen hafta',
      recitations: 'Dinletmeler',
      newPages: 'Yeni sayfalar',
      reviews: 'Tekrarlar',
      points: 'Puan',
      attendance: 'Devam',
      attV: '{days} günden {present}',
      teacherNote: 'Öğretmenin notu',
      noNote: 'Bu hafta öğretmenden not yok',
      nextPlan: 'Gelecek hafta için',
      open: 'Haftalık rapor',
    ),
    wird: SWird(
      title: 'Bugünün virdi',
      newPart: 'Yeni ezber',
      reviewPart: 'Tekrar',
      fromTeacher: 'Öğretmenin belirledi',
      suggested: 'Önerilen',
      done: 'Tamam',
      sent: 'Öğretmene gönderildi',
      todo: 'Henüz okunmadı',
      recite: 'Şimdi dinlet',
      open: 'Mushafta aç',
      complete: 'Bugünün virdi tamam, Allah bereketli kılsın',
      none: 'Henüz vird yok: kaydındaki ilk yeni ezberden sonra görünür.',
      dayOff: 'Bugün merkezde çalışma günü değil; vird isteğe bağlı.',
      pages: '{n} sayfa',
    ),
  );

  static const fr = S(
    lang: 'fr',
    common: SCommon(
      appName: 'Bustan Al-Quran',
      signOut: 'Se déconnecter',
      loadFailed: 'Impossible de charger les données',
      checkConnection: 'Vérifiez votre connexion internet et réessayez',
      retry: 'Réessayer',
      noPermission: 'Vous n’avez pas l’autorisation de faire cela',
      linkedData: 'Impossible car d’autres données en dépendent',
      offline: 'Pas de connexion internet, réessayez',
      cancel: 'Annuler',
      save: 'Enregistrer',
      delete: 'Supprimer',
      edit: 'Modifier',
      send: 'Envoyer',
      close: 'Fermer',
      confirm: 'Confirmer',
      language: 'Langue',
      goodMorning: 'Bonjour',
      goodEvening: 'Bonsoir',
      listSep: ', ',
    ),
    labels: SLabels(
      recitationType: {'new_memorization': 'Nouvelle mémorisation', 'recent_review': 'Révision récente', 'distant_review': 'Révision ancienne'},
      attendance: {'present': 'Présent', 'absent': 'Absent', 'late': 'En retard', 'excused': 'Excusé'},
      purchase: {'pending': 'En attente de remise', 'fulfilled': 'Remise', 'cancelled': 'Annulée'},
      metric: {'points': 'Moyenne de points par élève', 'recitations': 'Moyenne de récitations par élève', 'attendance': 'Moyenne de jours de présence par élève'},
      challengeStatus: {'upcoming': 'À venir', 'active': 'En cours', 'ended': 'Terminé'},
      serdStatus: {'scheduled': 'Programmé', 'submitted': 'En attente de validation', 'approved': 'Validé', 'rejected': 'Refusé'},
      months: ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
      rule: {'manual': 'Attribué par l’administrateur', 'points_threshold': '{n} points', 'recitations_count': '{n} récitations', 'grade_count': '{n} récitations avec la mention « {grade} »', 'streak_days': '{n} jours d’affilée', 'weekly_attendance': '{n} % de présence hebdomadaire', 'juz_complete': 'Achever le juz {n} en serd', 'serd_passed_count': '{n} séances de serd réussies'},
      juz: 'Juz {n}',
      portion: '{ord} {den}',
      portionDen: {'2': 'moitié', '4': 'quart', '8': 'huitième'},
      portionOrd: ['1er', '2e', '3e', '4e', '5e', '6e', '7e', '8e'],
      audience: {'all': 'Tout le monde', 'teachers': 'Enseignants', 'students': 'Élèves', 'guardians': 'Parents'},
      consent: {'not_required': '—', 'pending': 'Consentement attendu', 'approved': 'Accepté', 'declined': 'Refusé'},
      source: {'self': 'Inscrit par lui-même', 'guardian': 'Inscrit par le parent', 'teacher': 'Inscrit par l’enseignant', 'admin': 'Inscrit par l’administrateur'},
      registration: {'none': 'Pas d’inscription', 'ended': 'Terminé', 'closed': 'Inscriptions fermées', 'full': 'Complet', 'open': 'Inscriptions ouvertes'},
      weekdays: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
      certKind: {'serd': 'Serd du Coran', 'memorization': 'Mémorisation achevée', 'excellence': 'Excellence', 'attendance': 'Assiduité', 'custom': 'Personnalisé'},
      deletionStatus: {'pending': 'En cours d’examen', 'approved': 'Acceptée', 'rejected': 'Refusée', 'completed': 'Terminée'},
      roles: {'admin': 'Administrateur', 'teacher': 'Enseignant', 'student': 'Élève', 'guardian': 'Parent'},
    ),
    banners: SBanners(
      viewer: 'Ceci est un compte de consultation — les données sont en lecture seule',
      billingLock: '🍂 L’abonnement du centre a expiré — les données sont en lecture seule jusqu’au renouvellement',
    ),
    portal: SPortal(
      tabHome: 'Accueil',
      tabRecord: 'Mon dossier',
      tabAccount: 'Compte',
      noChildren: 'Aucun enfant n’est lié à votre compte',
      notLinked: 'Votre compte n’est pas lié à un profil d’élève',
      askAdmin: 'Contactez l’administration du centre pour lier votre compte',
      studentMissing: 'Profil de l’élève introuvable',
      noStudent: 'Aucun profil d’élève n’est lié',
      hello: 'Bonjour, {name}',
      sheikh: 'Cheikh {name}',
      noCircle: 'Pas encore affecté à un cercle',
      progressTitle: 'Progression de la mémorisation',
      partsOf30: '{n} juz sur 30',
      nextPlan: 'Votre prochain programme : {plan}',
      goalQuran: 'pour achever la mémorisation du Coran',
      goalPoints: 'pour atteindre {n} points',
      unitJuz: 'juz',
      unitPoints: 'points',
      remaining: 'Encore {n} {unit}',
      announcements: 'Annonces',
      upcoming: 'À venir',
      prayers: ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
      statsTitle: 'Vos statistiques',
      statAyahs: 'Versets cette semaine',
      statAttendance: 'Présence hebdomadaire',
      statTotal: 'Total des récitations',
      statLast: 'Dernière récitation',
      weekTitle: 'Votre semaine',
      weekCount: '{n} récitations cette semaine',
      weekBetter: 'Mieux que la semaine dernière (+{n})',
      weekWorse: 'Moins que la semaine dernière ({n})',
      weekSame: 'Comme la semaine dernière',
      streak: 'Série en cours : {n} jours  ·  Record : {best}',
      streakRecord: '🎉 Nouveau record personnel !',
      yourBadges: 'Vos badges',
      calendar: 'Calendrier et événements',
      calendarSub: 'Congés, sorties et concours — et inscriptions',
      chat: 'Messages',
      announcementsLink: 'Annonces',
      report: 'Rapport',
      reportSub: 'Récitation, présence et serd sur la période de votre choix',
      certificates: 'Certificats',
      quran: 'Coran',
      quranSub: 'Lire, écouter et marquer',
      privacy: 'Mon compte et mes données',
      privacySub: 'Demander la suppression du compte et des données',
      notifications: 'Notifications',
      badges: 'Badges',
      market: 'Boutique',
      serd: 'Serd du Coran',
      recent: 'Dernières récitations',
      noRecitations: 'Aucune récitation pour l’instant',
      studentCode: 'Numéro d’élève',
      circle: 'Cercle',
      stage: 'Niveau',
      teacher: 'Cheikh',
      phone: 'Téléphone',
      address: 'Adresse',
      languageHint: 'Langue de l’application',
    ),
    record: SRecord(
      tabRecitations: 'Récitation',
      tabAttendance: 'Présence',
      tabSerd: 'Serd',
      thisMonth: 'Ce mois-ci',
      recitations: 'Récitations',
      ayahs: 'Versets',
      attendance: 'Présence',
      points: 'Points',
      breakdown: 'Détail des points',
      noAttendance: 'Aucune présence enregistrée pour l’instant',
      search: 'Rechercher par sourate ou remarque',
      all: 'Tout',
      noResults: 'Aucun résultat',
      session: '{n} récitations en une séance',
    ),
    badges: SBadges(
      title: 'Badges et compétition',
      mine: 'Mes badges',
      none: 'Votre centre n’a pas encore de badges',
      earned: '✓ Obtenu le {date}',
      expires: '  ·  expire le {date}',
      manual: 'Attribué par l’administrateur',
      board: 'Tableau d’honneur — {circle}',
      points: '{n} points',
      challenge: 'Défi entre cercles : {title}',
    ),
    market: SMarket(
      title: 'Boutique de points',
      disabled: 'La boutique n’est pas activée dans votre centre pour le moment',
      balance: 'Solde',
      earned: 'Sur {n} points  ·  dépensé {spent}',
      pending: '  ·  {n} points en attente de compléter une unité de conversion',
      available: 'Disponible à l’achat',
      empty: 'Rien de disponible pour le moment',
      stock: 'Restant : {n}',
      bought: 'Commandé ✓ — le centre vous le remettra',
      soldOut: 'Épuisé',
      buy: 'Acheter',
      tooPoor: 'Solde insuffisant',
      orders: 'Mes commandes',
      noOrders: 'Aucune commande pour l’instant',
      cancelled: 'Commande annulée et solde restitué',
    ),
    serdCard: SSerdCard(
      none: 'Aucun serd validé pour l’instant',
      sessions: 'Séances validées',
      average: 'Moyenne',
      best: 'Meilleur',
      covered: 'Couvert',
      juzCount: '{n} juz',
      complete: 'Juz achevés : {list}',
      partial: 'Partiel : {list}',
      partialItem: 'Juz {juz} — {e}/8',
    ),
    ann: SAnn(
      title: 'Annonces',
      newTitle: 'Nouvelle annonce',
      none: 'Aucune annonce',
      draft: 'Brouillon',
      required: 'Le titre et le texte sont obligatoires',
      deleteTitle: 'Supprimer l’annonce',
      sure: 'Êtes-vous sûr ?',
      fieldTitle: 'Titre',
      fieldBody: 'Texte',
      audience: 'Public',
      circleOptional: 'Un cercle précis (facultatif)',
      allCircles: 'Tous les cercles',
      pin: 'Épingler en haut',
      publish: 'Publier maintenant',
      publishHint: 'Le public est notifié à la première publication',
      editTitle: 'Modifier l’annonce',
      yourCircle: 'Votre cercle',
    ),
    attn: SAttn(
      title: 'Élèves à suivre de près',
      hint: 'Les plus urgents d’abord : en retard sur leur objectif, sans récitation, souvent absents.',
      none: 'Personne n’a besoin d’une attention particulière pour l’instant 🌿',
      behind: 'En retard de {pages} pages sur son objectif',
      idle: 'N’a pas récité depuis {days} jours ouvrés',
      never: 'N’a jamais récité',
      absences: 'Absent {count} fois en deux semaines',
      all: 'Tous',
      filterBehind: 'Retard sur l’objectif',
      filterIdle: 'Sans récitation',
      filterAbsent: 'Absences',
      recite: 'Réciter',
      call: 'Appeler',
      lastRecited: 'Dernière récitation : {v}',
      count: '{n} élèves',
    ),
    auth: SAuth(
      thisCenter: 'ce centre',
      noCenter: 'Aucun centre trouvé avec ce code ; vérifiez-le et réessayez',
      badLogin: 'Le numéro de connexion / e-mail ou le mot de passe est incorrect',
      notMember: 'Ce compte n’est pas inscrit chez {v}',
      serverDown: 'Impossible de joindre le serveur ; vérifiez internet et réessayez',
      codeFirst: 'Saisissez d’abord le code du centre',
      openFailed: 'Impossible d’ouvrir la page ; essayez depuis le navigateur',
      signInTitle: 'Connectez-vous à votre centre',
      step1: '1. Le centre',
      centerCode: 'Code du centre',
      enterCode: 'Saisissez le code du centre',
      noCenterShort: 'Aucun centre avec ce code',
      codeHint: 'Le code du centre est la première partie du lien de votre centre, ex. eqraa pour eqraa.bustan-alquran.com',
      step2: '2. Votre compte',
      loginId: 'Identifiant / numéro d’élève ou e-mail',
      enterId: 'Saisissez votre numéro ou e-mail',
      password: 'Mot de passe',
      enterPassword: 'Saisissez le mot de passe',
      forgot: 'Mot de passe oublié ?',
      signInTo: 'Se connecter à {name}',
      signIn: 'Se connecter',
      whoHint: 'Connexion pour les enseignants, administrateurs, parents et élèves, chacun avec ses accès dans le centre.',
      confirmEmail: 'Vérifiez d’abord votre e-mail pour confirmer le compte, puis rouvrez le lien d’invitation pour terminer',
      joinFailed: 'Impossible de terminer l’adhésion ; vérifiez internet et réessayez',
      joinTitle: 'Rejoindre un centre',
      invalidInvite: 'Invitation invalide',
      invalidBody: 'Elle a expiré ou a déjà été utilisée. Demandez-en une nouvelle à l’administrateur du centre.',
      inviteFrom: 'Invitation de {organization_name}',
      asRole: 'Pour rejoindre en tant que {role}',
      signedInAs: 'Connecté en tant que {email}',
      confirmJoin: 'Confirmer l’adhésion',
      inviteEmail: 'E-mail (de l’invitation)',
      yourPassword: 'Mot de passe de votre compte',
      createPassword: 'Créez un mot de passe (au moins 8 caractères)',
      signInJoin: 'Se connecter et rejoindre',
      createJoin: 'Créer le compte et rejoindre',
      noAccount: 'Je n’ai pas de compte',
      haveAccount: 'J’ai déjà un compte',
      ob1: 'Enregistrez récitation et mémorisation',
      ob1Body: 'Chaque cercle, chaque élève, chaque page mémorisée ou révisée — en un geste pour l’enseignant, avec la mention et la date toujours conservées.',
      ob2: 'Restez en lien avec le centre',
      ob2Body: 'Messages, annonces et notifications instantanées entre administrateurs, enseignants, élèves et parents — chaque centre est privé.',
      ob3: 'Des points et des badges qui motivent',
      ob3Body: 'Chaque récitation rapporte des points et chaque étape un badge — une petite boutique et des défis entre cercles font de la mémorisation une habitude quotidienne qu’ils aiment.',
      openSignup: 'Ouvrez {_signupUrl} dans votre navigateur pour inscrire un nouveau centre',
      skip: 'Passer',
      signInBtn: 'Se connecter',
      next: 'Suivant',
      registerCenter: 'Inscrire un nouveau centre sur le site ↗',
      pickCenter: 'Choisissez le centre',
      noCenters: 'Votre compte n’est encore lié à aucun centre',
      noCentersHint: 'Demandez à l’administrateur du centre de vous inviter, ou connectez-vous avec un autre compte',
    ),
    badgesStaff: SBadgesStaff(
      rules: {'manual': 'Manuel (attribué par l’administrateur)', 'points_threshold': 'Atteindre un total de points', 'recitations_count': 'Nombre de récitations', 'grade_count': 'Récitations avec une mention donnée', 'streak_days': 'Jours d’affilée avec une récitation', 'weekly_attendance': 'Taux de présence hebdomadaire', 'juz_complete': 'Achever un juz entier en serd', 'serd_passed_count': 'Nombre de serd réussis'},
      manual: 'manuel',
      auto: 'automatique',
      expiresSuffix: '  ·  expire le {date}',
      nameRequired: 'Le nom du badge est obligatoire',
      pickStudent: 'Choisissez l’élève',
      awarded: 'Badge attribué',
      pickCircle: 'Choisissez le cercle',
      awardedN: 'Attribué à {n} élèves',
      deleteTitle: 'Supprimer le badge',
      deleteBody: 'Il est retiré à tous les élèves. Confirmer ?',
      newTitle: 'Nouveau badge',
      badge: 'Badge',
      icon: 'Icône',
      name: 'Nom',
      description: 'Description',
      rule: 'Règle',
      threshold: 'Valeur de la condition',
      juzNo: 'Numéro de juz (1–30)',
      percent: 'Pourcentage (1–100)',
      count: 'Nombre requis',
      grade: 'Mention',
      duration: 'Durée du badge en jours (vide = permanent)',
      active: 'Actif',
      giveManually: 'Attribuer le badge manuellement',
      toStudent: 'À un élève',
      toCircle: 'À tout un cercle',
      holdersN: 'Détenteurs ({n})',
      noHolders: 'Attribué à personne pour l’instant',
      revoked: 'Badge retiré',
      revoke: 'Retirer',
      reevaluate: 'Revérifier tout le monde',
      reevaluated: 'Badges revérifiés pour tous les élèves',
      intro: 'Les badges automatiques sont attribués dès que leur condition est remplie. Les manuels sont attribués par l’administrateur, ou par un enseignant aux élèves de son cercle.',
      empty: 'Aucun badge pour l’instant',
      expiresAfter: 'Expire après {durationDays} jours',
      inactive: 'Inactif',
    ),
    cal: SCal(
      settingLoadFailed: 'Impossible de charger le réglage',
      reminderTitle: 'Rappeler aux inscrits',
      reminderHours: 'Heures avant le début de l’événement — 0 = désactivé',
      reminderHelp: 'Envoyé aux élèves inscrits et à leurs parents',
      reminderSaved: 'Réglage du rappel enregistré',
      saveFailed: 'Enregistrement impossible',
      title: 'Calendrier et événements',
      reminderTip: 'Rappel avant l’événement',
      types: 'Types d’entrées',
      add: 'Ajouter',
      legend: 'Jours ouvrés : {working} sur {total}  ·  gris = jour férié  ·  « Serd » = jour de serd',
      thisMonth: 'Ce mois-ci',
      nothing: 'Rien ici',
      youRegistered: 'Vous êtes inscrit ✓',
      dayOff: 'Jour férié',
      serdScheduled: 'Serd programmé : {name}',
      serd: 'Serd',
      linkCopied: 'Lien de consentement copié',
      registeredDone: 'Inscrit',
      resultOf: 'Résultat de {name}',
      rank: 'Rang',
      note: 'Remarque',
      resultSaved: 'Résultat enregistré',
      details: 'Détails',
      registration: 'Inscription',
      participants: 'Inscrits ({n})',
      registerStudent: 'Inscrire un élève',
      noParticipants: 'Personne n’est encore inscrit',
      waitlistCount: 'Liste d’attente ({n})',
      circle: 'Cercle {name}',
      stage: 'Niveau {name}',
      workDay: 'Jour ouvré',
      taken: 'Inscrits : {n}',
      waiting: 'En attente : {n}',
      deadline: 'Date limite : {date}',
      needsConsent: 'Consentement du parent requis',
      unregister: 'Annuler l’inscription',
      unregistered: 'Inscription annulée',
      staffRegistered: 'Inscrit par l’enseignant ou l’administrateur — contactez-les pour annuler',
      register: 'S’inscrire',
      waitlisted: 'Ajouté à la liste d’attente',
      joinWaitlist: 'Rejoindre la liste d’attente',
      leftWaitlist: 'Retiré de la liste d’attente',
      leaveWaitlist: 'Quitter la liste d’attente',
      registeredChip: 'Inscrit ✓',
      waitingChip: 'En attente',
      consent: 'Consentement du parent : {status}',
      copyLink: 'Copier le lien',
      result: 'Résultat : rang {rank}',
      rankN: 'Rang {rank}',
      copyConsent: 'Copier le lien de consentement',
      consentRecorded: 'Consentement enregistré',
      phoneConsent: 'Consentement par téléphone',
      declineRecorded: 'Refus enregistré',
      decline: 'Refusé',
      resultBtn: 'Résultat',
      searchStudent: 'Rechercher par nom ou numéro d’élève',
      onDay: 'Entrées du jour {day}',
      takenShort: '{n} inscrits',
      offDay: 'Jour non ouvré (non compté dans le taux de présence)',
      unregisterQ: 'Annuler l’inscription de {name} ?',
      withReg: ' — avec inscription',
      notWorking: ' — jour non ouvré',
      workingDay: 'Jour ouvré',
      notWorkingDay: 'Jour non ouvré',
      pickTypeTitle: 'Choisissez le type et écrivez le titre',
      deleteBody: 'Cet élément et toutes ses inscriptions seront supprimés. Confirmer ?',
      addTitle: 'Ajouter au calendrier',
      type: 'Type',
      titleField: 'Titre',
      description: 'Description',
      fromV: 'Du : {v}',
      toV: 'Au : {v}',
      timeOpt: 'Heure (facultatif)',
      place: 'Lieu',
      whoSees: 'Qui le voit',
      audienceLabel: 'Public',
      oneCircle: 'Un cercle précis',
      allCircles: 'Tous les cercles',
      oneStage: 'Un niveau précis',
      allStages: 'Tous les niveaux',
      workingSection: 'Jour ouvré',
      overrideType: 'Remplacer le réglage du type',
      typeMakes: 'Selon le type : {v}',
      offDaysHint: 'Les jours non ouvrés ne comptent pas dans le taux de présence des élèves.',
      registrationSection: 'Inscription',
      seats: 'Places (vide = illimité)',
      closesAt: 'Clôture des inscriptions : {v}',
      removeDeadline: 'Supprimer la date limite',
      open: 'Inscriptions ouvertes',
      saved: 'Enregistré',
      newType: 'Nouveau type',
      editType: 'Modifier le type',
      name: 'Nom',
      hasRegistration: 'Accepte des inscriptions',
      needsGuardian: 'Consentement du parent requis',
      active: 'Actif',
      typeNameRequired: 'Le nom du type est obligatoire',
      typesTitle: 'Types d’éléments du calendrier',
      typesHint: 'Les éléments antérieurs gardent les réglages de leur type au moment de l’ajout ; modifier un type ne change donc pas les anciens taux de présence.',
      working: 'Ouvré',
      guardianConsent: 'Consentement du parent',
      inactive: 'Inactif',
    ),
    cert: SCert(
      failed: 'Impossible de terminer l’action',
      issueTitle: 'Émettre un certificat',
      student: 'Élève',
      kind: 'Type',
      fieldTitle: 'Titre du certificat',
      fieldText: 'Texte (facultatif)',
      issue: 'Émettre le certificat',
      serdHint: 'Les certificats de serd s’émettent depuis l’écran du serd après validation.',
      issued: 'Certificat émis',
      revokeTitle: 'Révoquer le certificat',
      reason: 'Motif (facultatif)',
      revoke: 'Révoquer',
      revoked: 'Certificat révoqué',
      customizeTitle: 'Personnaliser le certificat pour votre centre',
      signer: 'Nom du signataire',
      signerRole: 'Sa fonction',
      footer: 'Ligne de pied de page',
      serdTitle: 'Titre du certificat de serd',
      autoSerd: 'Émettre automatiquement le certificat de serd à la validation d’une séance réussie',
      futureOnly: 'Les changements ne s’appliquent qu’aux futurs certificats ; ceux déjà émis restent tels quels.',
      saved: 'Réglages enregistrés',
      title: 'Certificats',
      customize: 'Personnaliser le certificat',
      add: 'Certificat',
      none: 'Aucun certificat pour l’instant',
      revokedMark: ' · révoqué',
      one: 'Certificat',
      notFound: 'Certificat introuvable',
      linkCopied: 'Lien de vérification copié',
      copyLink: 'Copier le lien de vérification du certificat',
      pdfHint: 'Pour un PDF imprimable, ouvrez le certificat dans un navigateur et choisissez « Imprimer / enregistrer en PDF ».',
      titleHint: 'Certificat d’excellence',
      signerRoleHint: 'Directeur du centre',
    ),
    cfeat: SCfeat(
      names: {'students': 'Élèves', 'circles': 'Cercles', 'attendance': 'Présences et rassemblements', 'serd': 'Serd coranique', 'points': 'Points', 'badges': 'Badges', 'market': 'Boutique de points', 'circle-challenges': 'Défis des cercles', 'activities': 'Activités', 'calendar': 'Calendrier', 'announcements': 'Annonces', 'chat': 'Messages', 'notifications': 'Notifications', 'reports': 'Rapports', 'certificates': 'Certificats', 'fees': 'Frais des élèves', 'quran': 'Mushaf', 'recitations': 'Récitation enregistrée et en direct', 'wird': 'Portion du jour et son rappel', 'garden_tree': 'L’arbre qui pousse'},
      tab: 'Fonctionnalités du centre',
      title: 'Fonctionnalités utilisées par le centre',
      hint: 'Désactivez ce dont votre centre n’a pas besoin : cela disparaît des menus de tous. Réactivez quand vous voulez. Ce qui est disponible ici dépend de votre formule.',
      notInPlan: 'Pas dans votre formule',
      save: 'Enregistrer',
      saved: 'Fonctionnalités enregistrées',
      off: 'Cette fonctionnalité est désactivée dans votre centre.',
    ),
    chat: SChat(
      title: 'Messages',
      newChat: 'Nouvelle conversation',
      none: 'Aucune conversation pour l’instant',
      noneHint: 'Commencez-en une avec le bouton ci-dessous',
      deletedLast: '🚫 Un message a été supprimé',
      you: 'Vous : ',
      searchName: 'Rechercher par nom',
      noContacts: 'Personne à qui écrire',
      uploadFailed: 'Impossible d’envoyer l’image',
      sendFailed: 'Envoi impossible — vérifiez votre connexion et réessayez',
      stillFailing: 'Toujours impossible d’envoyer',
      gallery: 'Depuis la galerie',
      camera: 'Prendre une photo',
      imageSize: 'Taille maximale d’image : 5 Mo',
      editTitle: 'Modifier le message',
      deleteTitle: 'Supprimer le message',
      deleteBody: 'Il sera supprimé pour vous et pour l’autre personne, sans retour possible.',
      deleteFailed: 'Suppression impossible — vérifiez votre connexion',
      unmute: 'Réactiver le son',
      start: 'Commencez la conversation',
      deleted: 'Ce message a été supprimé',
      notSent: 'Non envoyé — appuyez pour réessayer',
      sending: 'Envoi...',
      edited: ' · modifié',
      attach: 'Joindre une image',
      caption: 'Ajouter une légende (facultatif)...',
      cantReply: 'Vous ne pouvez pas écrire à cet utilisateur pour le moment',
      mute: 'Mettre en sourdine',
      write: 'Écrivez votre message...',
    ),
    dash: SDash(
      takeAttendance: 'Faire l’appel',
      addStudent: 'Ajouter un élève',
      serdSession: 'Séance de serd',
      newAnnouncement: 'Nouvelle annonce',
      calendar: 'Calendrier',
      title: 'Tableau de bord',
      greeting: '{v} — as-salamu alaykum',
      yourCirclesToday: 'Vos cercles aujourd’hui',
      noCircle: 'Vous n’êtes encore affecté à aucun cercle — demandez à l’administrateur de vous ajouter.',
      notWorkingDay: 'Aujourd’hui n’est pas un jour ouvré dans votre centre',
      studentsN: '{students} élèves',
      recitedN: 'Ont récité {recited}',
      presentN: 'Présents {present}',
      absentN: 'Absents {absent}',
      students: 'Élèves',
      teachers: 'Enseignants',
      circles: 'Cercles',
      todayAttendance: 'Présence du jour',
      shortcuts: 'Raccourcis',
      centerAdmin: 'Administration du centre',
      waitSerd: 'Serd en attente de validation',
      waitMarket: 'Demandes de la boutique en attente',
      waitGatherings: 'Rassemblements avec des noms à rattacher',
      waitExternal: 'Récitations externes à rattacher',
      needsYou: 'Requiert votre attention',
      nothingWaiting: 'Rien ne vous attend ✓',
      inactiveN: 'Pas de récitation depuis deux semaines ({inactive_total})',
      thisWeek: 'Cette semaine',
      weekRecitations: '{recitations} récitations',
      weekReciting: '{reciting_students} élèves ont récité',
      weekPoints: '{points} points',
      weekAttendance: 'Présence {v}',
      upcomingEvents: 'Événements à venir',
      notYet: 'N’a pas encore récité',
      registered: 'inscrits',
      dropoutRisk: 'Risque d’abandon',
      noRisk: 'Aucun élève en risque d’abandon ✓',
      teacherPerf: 'Activité des enseignants (7 jours)',
      recitationsWord: 'récitations',
      riskTags: {'never': 'N’a jamais récité', 'regressed': 'A arrêté après avoir été régulier', 'slowing': 'Ralentit', 'attendance_gap': 'Vient mais ne récite pas'},
      idleDays: '{n} jours ouvrés',
      perfLine: '{circles} cercles · {students} élèves · présent {days} jours',
    ),
    fees: SFees(
      title: 'Frais',
      collectedMonth: 'Encaissé ce mois-ci',
      outstanding: 'Dû par les élèves',
      owingN: 'Redevables',
      filter: {'all': 'Tous', 'owing': 'Redevables', 'noPlan': 'Sans formule'},
      search: 'Rechercher par nom ou numéro d’élève',
      none: 'Aucun élève',
      exempt: 'Exonéré',
      discountV: '−{n} %',
      noPlan: 'Sans formule',
      owes: 'Doit',
      credit: 'Créditeur',
      settled: 'Rien à payer',
      dueSoFar: 'Dû à ce jour',
      paidTotal: 'Payé',
      upcoming: 'Frais à venir',
      plan: 'Formule : {name}',
      periods: {'monthly': 'Mensuelle', 'term': 'Par trimestre', 'once': 'Ponctuelle'},
      recordTitle: 'Enregistrer un paiement',
      amount: 'Montant',
      amountInvalid: 'Saisissez un montant valide',
      method: 'Moyen de paiement',
      methods: {'cash': 'Espèces', 'transfer': 'Virement', 'card': 'Carte', 'wallet': 'Portefeuille électronique', 'other': 'Autre'},
      paidOn: 'Date du paiement : {date}',
      note: 'Remarque (facultatif)',
      record: 'Enregistrer le paiement',
      recorded: 'Paiement enregistré ✓',
      outbox: 'Paiement {name} : {amount}',
      pendingUpload: 'En attente d’envoi',
      charges: 'Frais',
      payments: 'Paiements',
      status: {'open': 'Dû', 'waived': 'Remis', 'cancelled': 'Annulé'},
      notYetDue: 'Pas encore échu',
      waive: 'Remettre',
      cancelCharge: 'Annuler les frais',
      reopen: 'Rouvrir',
      cancelChargeConfirm: 'Annuler ces frais ? (pour une erreur de saisie ; pour les remettre, utilisez « Remettre »)',
      receiptNo: 'Reçu n° {n}',
      receiptTitle: 'Reçu de paiement',
      voidPayment: 'Annuler le paiement',
      voidReason: 'Motif (facultatif)',
      voidConfirm: 'Annuler ce paiement ? Le reçu reste enregistré avec la mention « Annulé ».',
      voided: 'Annulé',
      noCharges: 'Aucuns frais',
      noPayments: 'Aucun paiement',
      balanceAfter: 'Reste dû par l’élève',
      byLabel: 'Reçu par',
      share: 'Partager',
      receiptText: '{center}\n{title} — {no}\n{student}\n{amount} · {date} · {method}\n{left}',
      manageOnWeb: 'Les formules, leur attribution aux élèves, les réglages et le rapport sont sur le tableau de bord web.',
      adminOnly: 'Seul l’administrateur gère les frais',
      openAccount: 'Compte de frais',
    ),
    garden: SGarden(
      online: 'En ligne',
      offline: 'Hors ligne',
      noInternet: 'Réseau sans internet',
      syncCenter: 'Centre de synchronisation',
      offlineWaiting: 'Hors ligne · {n} en attente',
      syncing: 'Envoi en cours',
      waitingN: '{n} en attente',
      failedN: '{n} non envoyés',
      tabHome: 'Accueil',
      tabStudents: 'Élèves',
      tabSerd: 'Serd',
      tabChat: 'Messages',
      tabMore: 'Plus',
      seeAll: 'Tout voir',
      moreTitle: 'Toutes les sections',
      checkedInShort: 'Pointé',
      checkInShort: 'Pointer',
      studentsN: 'Élèves ({n})',
      statCircles: 'Cercles',
      statStudents: 'Élèves',
      statRecited: 'Ont récité',
      statPresent: 'Présents',
      quickTitle: 'Raccourcis',
      account: 'Compte',
      notificationPrefs: 'Préférences de notification',
      statJuz: 'Juz',
      statPoints: 'Points',
      statStreak: 'Jours d’affilée',
      explore: 'Explorer',
      statAttendance: 'Présence',
      itemsN: '{n} éléments',
    ),
    gather: SGather(
      noCircle: 'Aucun cercle',
      okLinked: 'Nom rattaché',
      skippedSuffix: ' · {n} ignorés',
      actionFailed: 'Cela n’a pas abouti — vérifiez votre connexion',
      extNew: 'Récitation externe',
      studentName: 'Nom de l’élève',
      type: 'Type',
      surah: 'Sourate',
      fromAyah: 'Du verset',
      toAyah: 'Au verset',
      grade: 'Mention',
      extUpload: 'Envoyer la récitation',
      extUploaded: 'Récitation envoyée ; en attente de rattachement par l’administrateur',
      extLinked: 'Récitation rattachée et enregistrée pour l’élève (+{v} points)',
      rejectTitle: 'Refuser la demande',
      reasonOpt: 'Motif (facultatif)',
      reject: 'Refuser',
      rejected: 'Demande refusée',
      extNewShort: 'Nouvelle récitation',
      noRequests: 'Aucune demande pour l’instant',
      linked: 'Rattachée',
      rejectedChip: 'Refusée',
      pending: 'En attente de rattachement',
      linkedTo: 'Rattachée à {matched_name}',
      reasonV: 'Motif : {reject_reason}',
      pickStudent: 'Choisissez un élève',
      deletedReq: 'Demande supprimée',
      linkedAttended: 'Nom rattaché et présence de l’élève enregistrée',
      addName: 'Ajouter un nom',
      name: 'Nom',
      add: 'Ajouter',
      nameAdded: 'Nom ajouté',
      activity: 'Activité',
      metaLine: '{session_date}{v}{v2} · envoyé par {v3}',
      namesN: 'Noms ({n})',
      nameDeleted: 'Nom retiré',
      linkedLine: 'Rattaché : {matched_name} ({matched_code}){v}',
      skipped: 'Ignoré',
      skip: 'Ignorer',
      nameSkipped: 'Nom ignoré',
      unlink: 'Détacher',
      uploadNew: 'Envoyer une nouvelle activité',
      activityName: 'Nom de l’activité',
      activityType: 'Type d’activité',
      none: '— Aucun —',
      placeOpt: 'Lieu (facultatif)',
      attendees: 'Participants — un nom par ligne',
      uploadBtn: 'Envoyer l’activité',
      uploadedN: 'Activité envoyée avec {n} noms',
      uploadFailed: 'Échec de l’envoi — vérifiez votre connexion',
      upload: 'Envoyer une activité',
      empty: 'Aucune activité envoyée pour l’instant',
      countsLine: '{total} noms · {matched} rattachés{v}',
      reviewed: 'Examinée',
      pendingN: 'En attente ({pending})',
      waitingAdmin: 'En attente de l’administrateur',
      pickStudentTitle: 'Choisissez l’élève',
      searchPh: 'Nom ou numéro de l’élève',
    ),
    ins: SIns(
      guardianVisibleSuffix: ' · visible par le parent',
      overdueSuffix: ' · {n} jours de retard',
      noCircle: 'Aucun cercle',
      auditActions: {'delete': 'Supprimé', 'update': 'Modifié', 'create': 'Ajouté'},
      auditTables: {'students_profile': 'élève', 'circles': 'cercle', 'stages': 'niveau', 'serd_sessions': 'séance de serd', 'organization_members': 'membre'},
      newNote: 'Nouvelle remarque',
      notePh: 'ex. se précipite à la fin des versets',
      guardianVisible: 'Visible par le parent',
      noteFailed: 'Impossible d’enregistrer la remarque',
      notesTitle: 'Remarques de l’enseignant',
      noNotes: 'Aucune remarque pour l’instant',
      searchFailed: 'La recherche a échoué. Vérifiez votre connexion.',
      searchPh: 'Rechercher : élève, numéro d’élève, enseignant, cercle',
      noResults: 'Aucun résultat',
      students: 'Élèves',
      staff: 'Enseignants et administrateurs',
      admin: 'Administrateur',
      teacher: 'Enseignant',
      circles: 'Cercles',
      reviewsTitle: 'Révision suggérée aujourd’hui',
      noReviews: 'Aucune révision due aujourd’hui ✓',
      reviewsHint: 'Chaque sourate revient après un intervalle qui s’allonge avec de bonnes mentions et retombe à un jour avec des mentions faibles.',
      challengeTitleRequired: 'Le titre du défi est obligatoire',
      newChallenge: 'Nouveau défi',
      editChallenge: 'Modifier le défi',
      title: 'Titre',
      description: 'Description',
      metric: 'Mesure',
      deleteChallenge: 'Supprimer le défi',
      sure: 'Êtes-vous sûr ?',
      challenge: 'Défi',
      noCircles: 'Aucun cercle avec des élèves pour l’instant',
      boardLine: '{students} élèves  ·  total {total}',
      noChallenges: 'Aucun défi',
      noAudit: 'Aucune action enregistrée pour l’instant',
      auditHint: 'Les suppressions et modifications sensibles apparaissent ici',
    ),
    live: SLive(
      title: 'Réciter',
      hint: 'Choisissez la sourate et le passage, puis commencez : les âyahs sont masquées et chaque mot apparaît quand vous le dites correctement. Si vous oubliez ou vous trompez, la récitation s’arrête et vous prévient.',
      student: 'Élève',
      surah: 'Sourate',
      type: 'Type',
      from: 'De l’âyah',
      to: 'À l’âyah',
      start: 'Commencer',
      unsupported: 'Ce navigateur ne peut pas suivre une récitation en direct. Utilisez Chrome ou Edge, ou l’application Bustan Al-Quran.',
      micDenied: 'L’accès au micro a été refusé. Autorisez-le dans les réglages et réessayez.',
      network: 'La reconnaissance vocale nécessite une connexion internet.',
      listening: 'À l’écoute… récitez de mémoire',
      paused: 'En pause',
      progress: '{n} mots sur {total}',
      mistakesN: 'Erreurs : {n}',
      stopMissing: 'Stop : un mot oublié',
      stopWrong: 'Stop : un mot erroné',
      correctIs: 'Correct :',
      heard: 'J’ai entendu : {w}',
      resume: 'Continuer',
      forgot: 'Je ne me souviens pas',
      finish: 'Terminer et envoyer',
      result: 'Résultat',
      score: '{n} % correct',
      mistakeList: 'Mots avec erreur :',
      resultNote: 'Le résultat vient de la reconnaissance vocale de votre appareil ; c’est votre enseignant qui valide.',
      note: 'Note pour l’enseignant (facultatif)',
      send: 'Envoyer à l’enseignant',
      sending: 'Envoi…',
      sent: 'Envoyé à votre enseignant. Vous serez averti de sa décision.',
      again: 'Réciter à nouveau',
      appAudio: 'Votre voix est enregistrée dès le début et envoyée avec le résultat pour que votre enseignant l’écoute.',
      recording: 'Enregistrement',
      withAudio: 'Enregistrement joint ({t})',
      retry: 'Renvoyer',
      notSent: 'La récitation n’a pas encore été envoyée. Vérifiez la connexion puis touchez « Renvoyer ».',
      nothingHeard: 'Rien de la récitation n’a été entendu, elle n’a donc pas été envoyée. Vérifiez le micro et récitez à nouveau.',
      mine: 'Mes récitations',
      error: 'Une erreur s’est produite. Réessayez.',
      fab: 'Réciter',
      liveBadge: 'Récitation en direct',
      loading: 'Chargement des âyahs…',
      appNoAudio: 'Dans l’application, la récitation est envoyée avec son résultat, sans enregistrement.',
      appUnsupported: 'La reconnaissance vocale n’est pas disponible sur cet appareil. Installez l’application Google ou activez la reconnaissance vocale dans les réglages.',
    ),
    mem: SMem(
      modules: {'students': 'Élèves', 'circles': 'Cercles', 'attendance': 'Présences', 'serd': 'Serd du Coran et demandes de récitation', 'points': 'Points', 'badges': 'Badges', 'market': 'Boutique de points', 'circle-challenges': 'Défis entre cercles', 'activities': 'Activités', 'calendar': 'Calendrier', 'announcements': 'Annonces', 'chat': 'Messages', 'notifications': 'Notifications', 'reports': 'Rapports', 'certificates': 'Certificats'},
      status: {'active': 'Actif', 'invited': 'Invité', 'suspended': 'Suspendu'},
      password8: 'Le mot de passe doit contenir au moins 8 caractères',
      passwordChanged: 'Mot de passe changé',
      accountSaved: 'Statut du compte enregistré',
      removeTitle: 'Retirer du centre',
      removeBody: 'Retirer « {fullName} » du centre ? Cette personne perd immédiatement tout accès ici.',
      editTitle: 'Modifier le membre',
      selfNote: 'Vous ne pouvez pas modifier ou retirer votre propre accès ici — demandez à un autre administrateur, s’il y en a un.',
      role: 'Rôle',
      statusLabel: 'Statut',
      modulesTitle: 'Sections accessibles',
      viewOnly: 'Compte en lecture seule',
      viewOnlyHint: 'Voit mais ne peut pas modifier : son rôle reste le même, mais aucune de ses modifications n’est enregistrée dans ce centre.',
      changePassword: 'Changer le mot de passe',
      newPassword: 'Nouveau mot de passe (au moins 8 caractères)',
      teacherCreated: 'Compte enseignant créé',
      newTeacher: 'Nouvel enseignant',
      teacherHint: 'L’enseignant se connecte avec le code du centre + son numéro (ou e-mail) + le mot de passe.',
      required: 'Obligatoire',
      loginId: 'Numéro de connexion ou e-mail',
      min8: 'Au moins 8 caractères',
      createAccount: 'Créer le compte',
      inviteCreated: 'Invitation créée',
      inviteError: 'Un problème est survenu avec l’invitation',
      inviteTitle: 'Inviter un nouveau membre',
      email: 'E-mail',
      inviteBtn: 'Créer l’invitation',
      pendingInvites: 'Invitations pas encore acceptées',
      contactTitle: 'Contact',
      contactHint: 'De préférence avec l’indicatif du pays, ex. +962791234567',
    ),
    mistakes: SMistakes(
      title: 'Erreurs récurrentes',
      hint: 'D’après les tests de l’enseignant et les vérifications automatiques des {days} derniers jours. Concentrez-vous dessus en révisant.',
      summary: '{sessions} récitations · {mistakes} erreurs',
      bySurah: 'Par sourate',
      byAyah: 'Âyahs les plus difficiles',
      byWord: 'Mots les plus difficiles',
      times: '×{n}',
      none: 'Aucune erreur enregistrée sur cette période.',
      ayah: '{surah} : {ayah}',
    ),
    mkt: SMkt(
      rateTitle: 'Taux de conversion des points',
      perPoints: 'Tous les (points)',
      equals: '= (valeur)',
      currency: 'Symbole monétaire',
      rateHint: 'Le changement ne s’applique qu’aux points convertis désormais ; les conversions antérieures gardent leur valeur.',
      rateInvalid: 'Saisissez des nombres entiers et un symbole monétaire',
      rateSaved: 'Taux enregistré',
      cancelOrder: 'Annuler la commande',
      cancelOrderBody: 'Le solde et le stock seront restitués. Confirmer ?',
      no: 'Non',
      yes: 'Oui',
      orderCancelled: 'Commande annulée',
      newItem: 'Nouvel article',
      adminOnly: 'Seul l’administrateur gère la boutique',
      items: 'Articles',
      ordersN: 'Commandes ({pending})',
      orders: 'Commandes',
      balances: 'Soldes',
      noOrders: 'Aucune commande',
      delivered: 'Livrée',
      walletLine: '{earnedPoints} points  ·  dépensé {v}',
      disabled: 'La boutique est désactivée pour le moment (activez-la dans les réglages du centre)',
      rateLine: 'Tous les {pointsPerUnit} points = {v}',
      rateSub: 'Taux de conversion points-monnaie',
      noItems: 'Aucun article pour l’instant',
      unlimited: 'Stock illimité',
      stockN: 'Stock : {n}',
      inactiveSuffix: '  ·  inactif',
      nameRequired: 'Le nom et le prix sont obligatoires',
      noUpload: 'Vous ne pouvez pas envoyer d’images',
      uploadFailed: 'Impossible d’envoyer l’image',
      tooBig3: 'L’image est trop grande (3 Mo max)',
      deleteItem: 'Supprimer l’article',
      deleteItemBody: 'Les commandes passées gardent son nom et son prix. Confirmer ?',
      editItem: 'Modifier l’article',
      name: 'Nom',
      description: 'Description',
      uploadDevice: 'Envoyer depuis l’appareil',
      removeImage: 'Retirer l’image',
      imageLink: 'Ou collez le lien de l’image (https)',
      priceIn: 'Prix ({symbol})',
      stock: 'Stock (vide = illimité)',
      active: 'Actif (visible par les élèves)',
    ),
    nav: SNav(
      items: {'/dashboard': 'Tableau de bord', '/attention': 'Élèves à suivre de près', '/review-plan': 'Portions de révision quotidiennes', '/sync': 'Synchronisation', '/students': 'Élèves', '/circles': 'Cercles', '/attendance': 'Présences', '/gatherings': 'Rassemblements et activités', '/external-recitations': 'Récitations externes', '/recitations': 'Récitations enregistrées', '/reviews': 'Révision suggérée', '/search': 'Recherche', '/quran': 'Coran', '/serd': 'Serd du Coran', '/stages': 'Niveaux', '/points': 'Points', '/badges': 'Badges', '/market': 'Boutique de points', '/circle-challenges': 'Défis entre cercles', '/activities': 'Activités', '/announcements': 'Annonces', '/calendar': 'Calendrier', '/chat': 'Messages', '/notifications': 'Notifications', '/reports': 'Rapports', '/certificates': 'Certificats', '/members': 'Membres et rôles', '/deletion-requests': 'Demandes de suppression de données', '/audit': 'Journal d’activité', '/site': 'Page publique', '/settings': 'Réglages du centre', '/fees': 'Frais'},
      sections: {'teaching': 'Enseignement', 'motivation': 'Motivation', 'comms': 'Communication', 'admin': 'Gestion du centre'},
      switchCenter: 'Changer de centre',
      menu: 'Menu',
    ),
    notif: SNotif(
      now: 'Maintenant',
      minutesAgo: 'Il y a {n} min',
      hoursAgo: 'Il y a {n} h',
      today: 'Aujourd’hui',
      yesterday: 'Hier',
      title: 'Notifications',
      markAll: 'Tout marquer comme lu',
      prefs: 'Ce que je reçois',
      none: 'Aucune notification',
      notSaved: 'Le changement n’a pas été enregistré. Vérifiez votre connexion et réessayez.',
      noPush: 'Les notifications push ne sont pas activées dans cette version de l’application — vous les verrez seulement dans l’application.',
      noPermission: 'L’application n’a pas été autorisée à envoyer des notifications. Ouvrez Réglages du téléphone → Applications → Bustan Al-Quran → Notifications et activez-les.',
      paused: 'Le centre a suspendu les notifications pour le moment — la liste dans l’application fonctionne toujours.',
      quiet: 'Les notifications téléphone sont retenues entre {from} et {to} — elles arrivent le matin.',
      events: {'announcement': 'Nouvelle annonce', 'calendar_entry': 'Nouvel événement au calendrier', 'center_closed': 'Congé ou fermeture', 'event_reminder': 'Rappels d’événements', 'waitlist_promoted': 'Inscription depuis la liste d’attente', 'serd_assigned': 'Un serd qui m’est assigné', 'serd_approved': 'Serd validé', 'serd_rejected': 'Serd non validé', 'market_fulfilled': 'Commande de la boutique remise', 'market_cancelled': 'Commande de la boutique annulée', 'badge_awarded': 'Badges', 'weekly_digest': 'Résumé hebdomadaire', 'attendance_reminder': 'Rappel d’appel', 'teacher_checkin_reminder': 'Rappel de pointage de l’enseignant', 'student_idle_teacher': 'Alerte enseignant : élève en retard de récitation', 'student_idle': 'Rappel à l’élève en retard de récitation', 'student_absences': 'Alerte administrateur : absences répétées', 'deletion_request': 'Demandes de suppression de données', 'deletion_reviewed': 'Résultat de ma demande de suppression', 'gathering_submitted': 'Nouveau rassemblement soumis', 'external_submitted': 'Nouvelle récitation externe', 'external_reviewed': 'Résultat de la récitation externe', 'assistant_assigned': 'Nomination d’enseignant assistant', 'billing_reminder': 'Rappel d’abonnement', 'billing_reviewed': 'Résultat de la vérification du paiement', 'capacity_warning': 'Capacité de la formule', 'billing_downgraded': 'Passage à la formule gratuite', 'fee_payment': 'Reçu de paiement des frais', 'fee_overdue': 'Rappel de frais dus', 'recitation_submitted': 'Nouvelle récitation enregistrée à examiner', 'recitation_reviewed': 'Récitation enregistrée examinée', 'wird_reminder': 'Rappel de la portion du jour'},
      types: 'Types de notifications',
      instantTitle: 'Recevoir les notifications instantanément',
      instantBody: 'Le téléphone économise la batterie en retardant les notifications de cette application. Laissez-la fonctionner sans restriction pour que les messages arrivent dès leur envoi.',
      instantBattery: 'Désactiver l’économie de batterie',
      instantBatteryHint: 'Choisissez « Toutes les applications » → Bustan Al-Quran → « Ne pas optimiser » ou « Sans restriction ».',
      instantAutostart: 'Autoriser le démarrage automatique',
      instantAutostartHint: 'Sur les téléphones {maker}, activez le « Démarrage automatique » pour Bustan Al-Quran, sinon les notifications s’arrêtent quand l’application est fermée.',
      instantOk: 'Les notifications arrivent instantanément sur ce téléphone',
    ),
    org: SOrg(
      circleStatus: {'active': 'Actif', 'archived': 'Archivé'},
      attStatus: {'present': 'Présent', 'absent': 'Absent', 'excused': 'Excusé', 'late': 'En retard'},
      outboxAttendance: 'Feuille de présence {sessionDate} ({n} élèves)',
      saveErrorRetry: 'Un problème est survenu à l’enregistrement — réessayez',
      deleteCircle: 'Supprimer le cercle',
      deleteCircleBody: 'Supprimer ce cercle ? Action irréversible.',
      editCircle: 'Modifier le cercle',
      addCircle: 'Ajouter un cercle',
      circleName: 'Nom du cercle',
      stage: 'Niveau',
      noStage: 'Aucun niveau',
      teacher: 'Enseignant',
      noTeacher: 'Aucun enseignant',
      capacity: 'Capacité (élèves)',
      assistants: 'Enseignants assistants',
      assistantsHint: 'Ils obtiennent l’accès enseignant pour ce cercle uniquement et apparaissent avec l’étiquette « Enseignant assistant ».',
      noOtherTeachers: 'Aucun autre enseignant dans le centre',
      status: 'Statut',
      addCircleBtn: 'Ajouter le cercle',
      noCircles: 'Aucun cercle pour l’instant',
      noCirclesHint: 'Créez le premier cercle, puis ajoutez-y des élèves',
      capacityN: 'Capacité {capacity}',
      gradesLoadFailed: 'Impossible de charger les mentions',
      keyRule: 'La clé n’accepte que des lettres anglaises minuscules/chiffres/_, et le nom est obligatoire',
      gradesSaved: 'Mentions enregistrées',
      gradesTitle: 'Mentions et points de récitation',
      gradesHint: 'Les noms des mentions et les points de chacune. Les points sont enregistrés sur chaque récitation au moment de la saisie ; les changements ne s’appliquent donc qu’aux récitations futures.',
      name: 'Nom',
      points: 'Points',
      addGrade: 'Ajouter une mention',
      keyField: 'Clé (ex. outstanding)',
      nameField: 'Nom (ex. Excellent)',
      saveGrades: 'Enregistrer les mentions',
      gradesAdminOnly: 'Seul l’administrateur peut modifier les mentions et les points.',
      stageTaken: 'Ce nom ou ce code est déjà utilisé dans ce centre',
      deleteStage: 'Supprimer le niveau',
      deleteStageBody: 'Supprimer ce niveau ?',
      editStage: 'Modifier le niveau',
      addStage: 'Ajouter un niveau',
      stageName: 'Nom du niveau',
      stageNamePh: 'Préparatoire',
      stageCode: 'Numéro du niveau dans le numéro d’élève (1 ou 2 chiffres, ex. 2). Vide : l’ordre du niveau est utilisé',
      stageOrder: 'Ordre du niveau',
      addStageBtn: 'Ajouter le niveau',
      noStages: 'Aucun niveau pour l’instant',
      noStagesHint: 'Les niveaux organisent les cercles et servent à numéroter les élèves',
      orderN: 'Ordre {sortOrder}',
      circlesLoadFailed: 'Impossible de charger les cercles',
      studentsLoadFailed: 'Impossible de charger les élèves du cercle',
      attSaved: 'Présence enregistrée',
      saveAtt: 'Enregistrer la présence',
      circle: 'Cercle',
      dateV: 'Date :  {v}',
      pickCircle: 'Choisissez le cercle pour faire l’appel',
      pickCircleHint: 'Puis indiquez le statut de chaque élève et enregistrez',
      noStudents: 'Aucun élève dans ce cercle',
      allPresent: 'Marquer tout le monde présent',
      deleteActivity: 'Supprimer l’activité',
      deleteActivityBody: 'Supprimer cette activité ?',
      editActivity: 'Modifier l’activité',
      newActivity: 'Nouvelle activité',
      title: 'Titre',
      description: 'Description',
      whenOpt: 'Heure (facultatif)',
      addActivity: 'Ajouter une activité',
      noActivities: 'Aucune activité pour l’instant',
      noActivitiesHint: 'Ajoutez les activités du centre pour que tout le monde les voie',
      noTime: 'Pas d’heure fixée',
      siteIntro: 'Une page publique sur votre centre, affichée aux visiteurs non connectés.',
      siteEnable: 'Activer la page publique',
      heroTitle: 'Titre principal',
      heroBody: 'Présentation',
      contactEmail: 'E-mail de contact',
      siteAdminOnly: 'Seul l’administrateur peut modifier les réglages de la page publique.',
    ),
    plan: SPlan(
      graceTrial: '🍂 L’essai est terminé — votre jardin attend d’être arrosé : renouvelez depuis le tableau de bord web',
      gracePaid: '🍂 L’abonnement du centre est terminé — votre jardin attend d’être arrosé : renouvelez depuis le tableau de bord web',
      soonTrial: '🌿 L’essai se termine dans {days}',
      soonPaid: '🌿 L’abonnement du centre se termine dans {days}',
      days: {'one': '1 jour', 'two': '2 jours', 'many': '{n} jours'},
      students: {'one': '1 élève', 'two': '2 élèves', 'many': '{n} élèves'},
      studentsFull: '🌳 Le jardin est plein : le centre a atteint sa limite d’élèves ({max})',
      studentsLeft: '🌿 Encore {n} possibles dans la formule',
      teachersFull: '🌳 Le centre a atteint sa limite d’enseignants ({max})',
      oneTeacherLeft: '🌿 Un seul enseignant peut encore être ajouté dans la formule',
    ),
    priv: SPriv(
      updated: 'Demande mise à jour',
      updateFailed: 'Mise à jour impossible',
      requestsTitle: 'Demandes de suppression de données',
      noRequests: 'Aucune demande',
      reviewHint: '« Accepter » signifie que vous supprimerez vous-même le compte et les données, puis appuierez sur « Supprimé » pour que le demandeur soit informé.',
      student: 'Élève : {name}',
      approve: 'Accepter',
      reject: 'Refuser',
      done: 'Supprimé',
      confirmTitle: 'Demander la suppression du compte et des données',
      confirmBody: 'Votre demande est transmise à l’administration du centre pour examen. Confirmer ?',
      sendRequest: 'Envoyer la demande',
      sendFailed: 'Impossible d’envoyer la demande',
      title: 'Mon compte et mes données',
      intro: 'Vous pouvez demander à {org} de supprimer votre compte et vos données. L’administration examine la demande et vous êtes informé du résultat. Cela ne concerne que ce centre.',
      last: 'Dernière demande : {status}',
      reason: 'Motif (facultatif)',
      submit: 'Demander la suppression de mon compte et de mes données',
    ),
    prof: SProf(
      thisMonth: 'Ce mois-ci',
      lastMonth: 'Le mois dernier',
      last90: 'Les 3 derniers mois',
      vsPrev: 'Par rapport à la période précédente',
      same: 'Pas de changement',
      newV: 'Nouveau',
      recitations: 'Récitations',
      reciting: 'Élèves ayant récité',
      points: 'Points',
      attendance: 'Présence',
      serdHeard: 'Serd entendus',
      serdApproved: 'Serd validés',
      daysPresent: 'Jours de présence',
      teacherDays: 'Jours de présence de l’enseignant',
      students: 'Élèves',
      circles: 'Cercles',
      assistant: 'Assistant',
      teacher: 'Enseignant',
      assistants: 'Assistants',
      recent: 'Dernières récitations',
      teacherAtt: 'Présence de l’enseignant',
      nothing: 'Rien sur cette période',
      lastRec: 'Dernière : {v}',
      never: 'Pas encore',
      today: 'Aujourd’hui',
      daysAgo: 'Il y a {n} jours',
      profile: 'Profil',
      myProfile: 'Mon profil et mes résultats',
      message: 'Message',
      call: 'Appeler',
      notAllowed: 'Vous n’avez pas accès à ce profil',
      goalTitle: 'Objectif de mémorisation et khatma',
      memorized: '{n} pages sur {total}',
      percentQuran: '{p} % du Coran',
      pace: 'Rythme réel',
      paceV: '{n} pages/jour ouvré',
      goalPace: 'Objectif',
      goalPaceV: '{n} pages par jour',
      sinceStart: 'Depuis le début de l’objectif : {actual} pages sur {expected}',
      forecast: 'Fin prévue',
      forecastGoal: 'Au rythme de l’objectif',
      noPace: 'Pas de nouvelle mémorisation récemment',
      noGoal: 'Aucun objectif défini',
      goalStatus: {'ahead': 'En avance', 'on_track': 'Dans les temps', 'behind': 'En retard', 'done': 'Atteint'},
      setGoal: 'Définir l’objectif',
      editGoal: 'Modifier l’objectif',
      pagesPerDay: 'Pages par jour ouvré',
      targetPages: 'Objectif en pages (604 = tout le Coran)',
      note: 'Remarque (facultatif)',
      save: 'Enregistrer',
      clearGoal: 'Supprimer l’objectif',
      goalSaved: 'Objectif enregistré',
      invalidPages: 'Saisissez un nombre entre 0,25 et 20',
      outboxGoal: 'Objectif de mémorisation de {name}',
      whatsapp: 'WhatsApp',
    ),
    quran: SQuran(
      title: 'Coran',
      surahs: 'Sourates',
      search: 'Rechercher par nom ou numéro de sourate',
      continueReading: 'Reprendre la lecture',
      position: '{surah} — verset {ayah}',
      ayahs: '{n} versets',
      noBookmarks: 'Aucun marque-page',
      noBookmarksHint: 'Appuyez sur un verset du Coran pour le marquer',
      playFailed: 'Impossible de lire la récitation — vérifiez votre connexion',
      ayahOf: '{surah} — verset {ayah}',
      playFromHere: 'Lire à partir d’ici',
      unmark: 'Retirer le marque-page',
      copyAyah: 'Copier le verset',
      copied: 'Copié',
      smaller: 'Texte plus petit',
      bigger: 'Texte plus grand',
      loadFailed: 'Impossible de charger la sourate — vérifiez votre connexion',
      repeat: 'Répéter le verset',
      noRepeat: 'Pas de répétition',
      prevAyah: 'Verset précédent',
      nextAyah: 'Verset suivant',
      credit: 'Texte : écriture othmanie, lecture de Hafs · Récitations : everyayah.com et quran.com · Texte de secours : tanzil.net',
      bookmarks: 'Marque-pages',
      mark: 'Ajouter un marque-page',
      repeatN: 'Répéter le verset {n} fois',
      play: 'Lire',
      pause: 'Pause',
      sync: 'Écoute',
      syncNone: 'Sourate entière (sans suivi)',
      syncAyah: 'Suivre le verset',
      syncWord: 'Suivre le mot',
      reciter: 'Récitateur',
      noTimings: 'Pas encore de minutage des mots pour ce récitateur dans cette sourate — suivi verset par verset.',
      noSurahAudio: 'Pas de récitation complète pour cette sourate — choisissez « Suivre le verset »',
      fontSize: 'Taille du texte',
      testMode: 'Auto-test',
      testHint: 'Auto-test : les versets sont masqués — touchez un verset pour le révéler, ou lancez la récitation pour les révéler avec elle.',
      revealPage: 'Révéler la page',
      hidePage: 'Masquer la page',
      prevPage: 'Page précédente',
      nextPage: 'Page suivante',
      readingSettings: 'Paramètres de lecture',
    ),
    rec: SRec(
      pickGrade: 'Choisissez la mention de la récitation',
      pickSurah: 'Choisissez la sourate',
      enterRange: 'Saisissez la plage de versets',
      rangeOrder: 'Le dernier verset doit être le même que le premier ou après',
      tooFar: 'La sourate {v} n’a que {v2} versets',
      partial: '{saved} enregistrées ; les autres non : {message}',
      newTitle: 'Enregistrer la progression du jour',
      editTitle: 'Modifier la récitation',
      prefilled: 'Rempli à partir du programme de révision suggéré — modifiez si besoin',
      dateToday: 'Date de la récitation : aujourd’hui',
      dateV: 'Date de la récitation : {day}/{month}/{year}',
      type: 'Type de progression',
      addSurah: 'Ajouter une autre sourate à cette séance',
      grade: 'Mention de la récitation',
      notes: 'Remarques de l’enseignant (facultatif)',
      saveBtn: 'Enregistrer la récitation',
      saveEdit: 'Enregistrer les modifications',
      fromAyah: 'Du verset',
      toAyah: 'Au verset',
      maxV: 'Max {max}',
      searchSurah: 'Rechercher par nom ou numéro de sourate',
      ayahsN: '{v} versets',
      absenceFailed: 'Impossible d’enregistrer l’absence',
      lessonTitle: 'Mode leçon',
      studentXofY: 'Élève {v} sur {n}',
      plan: 'Son programme',
      recordBtn: 'Enregistrer la récitation',
      absent: 'Absent',
      later: 'Plus tard',
      nobody: 'Personne dans ce cercle n’attend de réciter pour le moment',
      done: 'La leçon est terminée',
      summary: 'Ont récité {_recited}  •  absents {_absent}  •  reportés {n}',
      anotherRound: 'Un autre tour pour ceux qui restent',
      finish: 'Terminer et revenir',
      circle: 'Cercle',
      doneToday: '{done} sur {total} ont récité aujourd’hui',
      outboxAttendance: 'Présence {studentName} : {status}',
      outboxRecitation: 'Récitation {studentName} — sourate {surah} ({ayahFrom}–{ayahTo})',
      today: 'Aujourd’hui',
      dayMonth: '{day}/{month}',
      addNote: 'Ajouter une remarque',
      saveWithPoints: 'Enregistrer la récitation  •  +{n} pts',
      change: 'Changer',
      wholeSurah: 'Sourate entière',
    ),
    recite: SRecite(
      rangeTitle: 'Répéter un passage',
      from: 'De l’âyah',
      to: 'À l’âyah',
      times: 'Nombre de fois',
      rangeHint: 'Le passage de l’âyah {from} à {to} est lu {times} fois. La répétition de chaque âyah reste celle choisie.',
      loop: 'Passage {n} sur {total}',
      rangeOff: 'Arrêter la répétition',
      recite: 'Réciter',
      reciteTitle: 'Réciter au système',
      reciteHint: 'Choisissez le passage, appuyez sur « Commencer l’enregistrement » et récitez de mémoire. Les âyahs sont masquées pendant l’enregistrement.',
      student: 'Élève',
      type: 'Type',
      start: 'Commencer l’enregistrement',
      stop: 'Arrêter l’enregistrement',
      recording: 'Enregistrement… récitez de mémoire',
      micDenied: 'L’accès au micro a été refusé. Autorisez-le dans les réglages du navigateur et réessayez.',
      micMissing: 'Ce navigateur ne peut pas enregistrer.',
      tooLong: 'L’enregistrement est limité à {n} minutes ; divisez le passage.',
      uploading: 'Envoi de l’enregistrement…',
      checking: 'Vérification de la récitation…',
      uploadFailed: 'L’enregistrement n’a pas pu être envoyé. Réessayez.',
      result: 'Résultat',
      score: '{n} % de concordance',
      correct: 'correct',
      missing: 'manquant',
      wrong: 'différent',
      extra: 'en trop',
      legend: 'Les mots manquants sont en rouge, les mots différents en orange.',
      unavailable: 'La vérification automatique n’est pas disponible. Vous pouvez quand même envoyer l’enregistrement à votre enseignant.',
      autoNote: 'La vérification automatique est approximative : elle repère les mots manquants ou différents, pas le tajwid ni les voyelles. C’est l’avis de l’enseignant qui compte.',
      note: 'Note pour l’enseignant (facultatif)',
      send: 'Envoyer à l’enseignant',
      sent: 'Envoyé à votre enseignant. Vous serez averti de sa décision.',
      again: 'Enregistrer à nouveau',
      cancel: 'Annuler',
      testStudent: 'Tester un élève',
      testTitle: 'Test d’un élève dans le mushaf',
      testHint: 'Les âyahs sont masquées : touchez une âyah pour la dévoiler, puis le mot où l’élève s’est trompé pour le marquer (touchez à nouveau pour retirer).',
      mistakes: 'Erreurs : {n}',
      grade: 'Appréciation',
      save: 'Enregistrer dans le dossier de l’élève',
      saved: 'Enregistré dans le dossier de {name} (+{points} points).',
      chooseStudent: 'Choisissez l’élève',
      noStudents: 'Aucun élève à tester.',
      badRange: 'Passage invalide.',
      error: 'Une erreur s’est produite. Réessayez.',
      myTitle: 'Mes récitations enregistrées',
      inboxTitle: 'Récitations enregistrées',
      inboxHint: 'Les récitations envoyées par vos élèves depuis le mushaf. Écoutez, puis validez pour l’ajouter au dossier de l’élève, ou renvoyez-la avec une note.',
      pending: 'En attente',
      reviewed: 'Examinées',
      none: 'Aucune récitation.',
      approve: 'Valider',
      reject: 'Renvoyer',
      rejectNote: 'Motif ou note pour l’élève',
      teacherNote: 'Note de l’enseignant : {note}',
      studentNote: 'Note de l’élève : {note}',
      autoScore: 'Vérification automatique {n} %',
      noAuto: 'Sans vérification automatique',
      heardAs: 'Mots différents :',
      missingWords: 'Mots manquants :',
      openMushaf: 'Ouvrir dans le mushaf',
      teacherTest: 'Test de l’enseignant',
      markedMistakes: 'Erreurs marquées : {list}',
      statusDraft: 'Non envoyée',
      statusSubmitted: 'En attente de l’enseignant',
      statusApproved: 'Validée',
      statusRejected: 'Renvoyée',
      reviewedBy: 'Examinée par {name}',
      ayahRange: 'Sourate {surah} {from}–{to}',
      waitingN: '{n} récitations enregistrées attendent votre examen',
      recheck: 'Relancer la vérification automatique',
      testNote: 'Note (facultatif)',
      micDeniedApp: 'L’accès au micro a été refusé. Autorisez-le dans les réglages de l’appareil et réessayez.',
      play: 'Écouter',
      apply: 'Appliquer',
    ),
    rep: SRep(
      from: 'Du {date}',
      to: 'Au {date}',
      title: 'Rapports',
      loadFailed: 'Impossible de charger le rapport',
      activeStudents: 'Élèves actifs',
      newStudents: 'Nouveaux élèves',
      recitations: 'Récitations',
      recitingStudents: 'Élèves ayant récité',
      points: 'Points',
      attendanceRate: 'Taux de présence',
      serdApproved: 'Serd validés',
      certsIssued: 'Certificats émis',
      copied: 'Résumé du rapport copié',
      copySummary: 'Copier le résumé',
      types: 'Types de récitation',
      attendance: 'Présence',
      circles: 'Cercles',
      teachers: 'Enseignants',
      top: 'Meilleurs scores',
      studentTitle: 'Rapport de l’élève',
      student: 'Élève',
      noStudent: 'Aucun élève n’est lié à votre compte',
      teacher: ' · Enseignant : {name}',
      periodRecitations: 'Récitations de la période',
      periodPoints: 'Points de la période',
      totalPoints: 'Total des points',
      progress: 'Progression',
      savedParts: 'Juz mémorisés',
      serd: 'Serd du Coran',
      badges: 'Badges',
      certificates: 'Certificats',
      log: 'Journal des récitations',
      none: 'Aucune récitation sur cette période',
      circleLine: '{teacher} · {students} élèves\\n{recitations} récitations · {points} points · {attendance} de présence',
      teacherLine: '{recitations} récitations · {points} points',
      sumTitle: 'Rapport de {center}',
      sumActive: 'Élèves actifs : {students_active}',
      sumPoints: 'Points : {points}',
      sumAttendance: 'Taux de présence : {v}',
      sumSerd: 'Serd validés : {serd_approved}',
      sumRecitations: 'Récitations : {recitations} ({reciting_students} élèves)',
      sumCircle: '• {name} : {recitations} récitations, présence {v}',
    ),
    rplan: SRplan(
      title: 'Portions de révision quotidiennes',
      hint: 'Pour chaque élève, le système suggère les pages suivantes de ce qu’il a mémorisé, dans l’ordre. Validez d’un geste ; l’élève et sa famille la voient alors.',
      range: 'De {from} à {to}',
      ayahRef: '{surah} {ayah}',
      pagesN: '{n} pages (p. {a}–{b})',
      approve: 'Valider',
      approveAll: 'Tout valider',
      approvedN: '{n} validées',
      recite: 'Réciter',
      skip: 'Annuler',
      status: {'suggested': 'Suggérée', 'approved': 'Validée', 'done': 'Faite ✓', 'pending': 'En attente d’envoi'},
      none: 'Aucun élève n’a encore de pages mémorisées',
      cycleStart: 'Un nouveau tour commence',
      today: 'Révision du jour',
      reviewPages: 'Pages de révision par jour (vide = automatique)',
      outbox: 'Valider la révision de {name}',
    ),
    serd: SSerd(
      overdueSuffix: '  ·  en retard',
      inactiveSuffix: '  ·  inactif',
      passSuffix: '  ·  seuil {n} %',
      wholeJuz: 'Juz entier',
      noCircle: 'Aucun cercle',
      linkStudent: 'Lier le serd à un élève',
      approved: 'Validé',
      rejectTitle: 'Refuser le serd',
      rejectReason: 'Motif du refus (facultatif)',
      reject: 'Refuser',
      rejected: 'Refusé',
      deleteTitle: 'Supprimer le serd',
      deleteBody: 'Ce serd sera supprimé et ses points retirés s’il avait été validé. Confirmer ?',
      deleted: 'Supprimé',
      approve: 'Valider',
      reapprove: 'Valider à nouveau',
      certIssued: 'Certificat émis — retrouvez-le dans l’écran des certificats',
      issueCert: 'Émettre un certificat',
      schedule: 'Programmer un serd',
      report: 'Rapport',
      settings: 'Réglages',
      record: 'Enregistrer un serd',
      all: 'Tous',
      pending: 'En attente de validation',
      scheduled: 'Programmé',
      approvedChip: 'Validé',
      rejectedChip: 'Refusé',
      empty: 'Aucun serd',
      requestedN: 'Serd demandés ({n})',
      assigned: 'Assigné à vous',
      openAny: 'Ouvert — n’importe quel enseignant peut l’enregistrer{v}',
      recordShort: 'Enregistrer',
      mine: 'Mes serd',
      mineEmpty: 'Vous n’avez encore enregistré aucun serd. Utilisez le bouton « Enregistrer un serd ».',
      saved: 'Enregistré',
      wholeAlways: 'Juz entier (toujours)',
      newErrorType: 'Nouveau type d’erreur',
      editErrorType: 'Modifier le type d’erreur',
      name: 'Nom',
      perErrors: 'Toutes les (erreurs)',
      deductPct: '= % retiré',
      active: 'Actif',
      fillAll: 'Remplissez le nom et les nombres',
      stagePortions: 'Quantités autorisées pour ce niveau',
      stagePass: 'Seuil propre % (vide pour le général)',
      settingsTitle: 'Réglages du serd',
      settingsHint: 'Les changements ne s’appliquent qu’aux serd futurs ; les serd antérieurs gardent leur score, leurs points et leur seuil.',
      general: 'Tout le centre',
      passPct: 'Seuil de réussite %',
      wholePoints: 'Points pour un juz entier',
      defaultPortions: 'Quantités autorisées par défaut',
      wholeNumbers: 'Saisissez des nombres entiers',
      saveGeneral: 'Enregistrer les réglages généraux',
      errorTypes: 'Types d’erreurs et leurs poids',
      perRule: 'Tous les {errorsPerUnit} = {percentPerUnit} %{v}',
      byStage: 'Par niveau',
      byStageHint: 'Un niveau débutant peut réciter un demi ou un quart de juz et avoir son propre seuil.',
      usesGeneral: 'Réglage général',
      pickOrType: 'Choisissez l’élève ou tapez son nom',
      pickPart: 'Choisissez au moins un juz',
      sentScore: 'Envoyé pour validation ✓  score {score} %',
      saveFailedNet: 'Enregistrement impossible ; vérifiez internet et réessayez',
      newTitle: 'Enregistrer un nouveau serd',
      scheduledTitle: 'Enregistrer un serd programmé',
      pickStudent: 'Choisissez l’élève',
      typeName: 'Ou tapez le nom de l’élève (hors de vos cercles)',
      clearPick: 'Effacer le choix',
      dateLine: 'Date du serd : {day}/{month}/{year}',
      parts: 'Juz récités',
      errors: 'Nombre d’erreurs',
      perRule2: 'Tous les {errorsPerUnit} = {percentPerUnit} %',
      expected: 'Score attendu : {v} %  ·  seuil {passPercent} %',
      notesOpt: 'Remarques (facultatif)',
      submit: 'Envoyer pour validation',
      noResults: 'Aucun résultat',
      reportTitle: 'Rapport de serd',
      totalSessions: 'Total des séances',
      waiting: 'En attente',
      avgScore: 'Score moyen',
      pointsGiven: 'Points attribués',
      approvedParts: 'Juz validés',
      juzLine: 'Juz {juz} — {v}',
      topErrors: 'Erreurs les plus fréquentes (validés)',
      examiners: 'Examinateurs',
      partsLine: '{v}  ({v2} juz)',
      examiner: 'Examinateur : {examinerName}',
      circleTeacher: 'Enseignant du cercle : {circleTeacherName}',
      assignedTo: 'Assigné à {assignedTeacherName}',
      openToAny: 'Ouvert à tout enseignant',
      noStudent: 'Non lié à un élève',
      scoreLabel: 'Score : ',
      resultLine: '  ·  {v} (seuil {passApplied})  ·  +{pointsAwarded} points',
      rejectReasonV: 'Motif du refus : {rejectReason}',
      whole: 'Entier',
      pickJuz: 'Choisissez le juz',
      juzLine2: 'Juz {juz} — {v}',
      addJuz: 'Ajouter un autre juz',
      passed: 'réussi',
      repeat: 'à repasser',
      pickBoth: 'Choisissez l’élève et au moins un juz',
      scheduledOk: 'Serd programmé',
      scheduleHint: 'Une tâche visible par les enseignants pour que celui qui est disponible l’enregistre, ou assignée à un enseignant.',
      student: 'Élève',
      when: 'Date : {day}/{month}/{year}',
      partsWanted: 'Juz demandés',
      assign: 'Assigner à un enseignant',
      scheduleBtn: 'Programmer le serd',
      outboxLabel: 'Serd {studentName} — {n} juz',
      certDone: 'Certificat délivré',
      issueAnother: 'Délivrer un autre certificat',
    ),
    set: SSet(
      loadSome: 'Certains réglages n’ont pas pu être chargés',
      saved: 'Réglages enregistrés',
      fromGallery: 'Depuis la galerie',
      takePhoto: 'Prendre une photo',
      tooBig1: 'L’image est trop grande (1 Mo max)',
      logoUploaded: 'Logo envoyé — appuyez sur « Enregistrer l’identité » pour l’appliquer partout',
      logoAdminOnly: 'Seul l’administrateur peut envoyer le logo',
      logoFailed: 'Impossible d’envoyer le logo',
      logoHttps: 'Le lien du logo doit commencer par https',
      backdateRange: 'La limite d’antidatage doit être comprise entre 0 et 365 jours',
      intro: 'Tout ce qui concerne votre centre se personnalise ici.',
      identity: 'Identité',
      name: 'Nom du centre',
      uploading: 'Envoi...',
      uploadLogo: 'Envoyer un logo depuis l’appareil',
      remove: 'Retirer',
      logoLink: 'Ou le lien du logo (https)',
      primary: 'Couleur principale (hex)',
      secondary: 'Couleur secondaire (hex)',
      link: 'Lien du centre',
      timezone: 'Fuseau horaire',
      saveIdentity: 'Enregistrer l’identité',
      workdays: 'Jours ouvrés',
      workdaysHint: 'Les taux de présence ne comptent que les jours ouvrés ; les jours de serd peuvent aussi être marqués.',
      working: 'Ouvré',
      serdDay: 'Serd',
      saveWorkdays: 'Enregistrer les jours ouvrés',
      features: 'Réglages de récitation et fonctionnalités',
      backdate: 'Jusqu’à combien de jours en arrière une récitation peut être datée',
      countryCode: 'Indicatif téléphonique du pays (ex. 33)',
      whatsapp: 'Lien du groupe WhatsApp',
      locationLabel: 'Nom du lieu (pour les horaires de prière et le calendrier)',
      lat: 'Latitude',
      lng: 'Longitude',
      method: 'Méthode de calcul des prières',
      madhab: 'Madhab (chaféite / hanafite)',
      reciters: 'Récitateurs du mushaf',
      recitersHint: 'Laissez vide pour proposer tous les récitateurs.',
      defaultReciter: 'Récitateur par défaut',
      firstInList: 'Le premier de la liste',
      market: 'Activer la boutique de points',
      tabs: {'identity': 'Identité', 'workdays': 'Jours ouvrés', 'features': 'Fonctionnalités', 'contact': 'Contact et prière', 'quran': 'Mushaf', 'notif': 'Notifications'},
      quranTitle: 'Mushaf et récitateurs',
      prayerMethods: {'umm_al_qura': 'Umm al-Qura', 'muslim_world_league': 'Ligue islamique mondiale', 'egyptian': 'Autorité égyptienne', 'karachi': 'Karachi', 'dubai': 'Dubaï', 'qatar': 'Qatar', 'kuwait': 'Koweït', 'moon_sighting_committee': 'Moonsighting Committee', 'singapore': 'Singapour', 'turkey': 'Turquie', 'tehran': 'Téhéran', 'north_america': 'Amérique du Nord (ISNA)'},
      majority: 'Majorité (chaféite / malékite / hanbalite)',
      hanafi: 'Hanafite',
      fees: 'Activer les frais des élèves (pour les centres payants)',
      leaderboard: 'Activer le classement',
      teacherStudents: 'Permettre aux enseignants de gérer les élèves de leur cercle',
      saveSettings: 'Enregistrer les réglages',
      adminOnly: 'Seul l’administrateur peut modifier les réglages du centre.',
      loadOne: 'Impossible de charger le réglage',
      digestTitle: 'Résumé hebdomadaire aux familles',
      digestHint: 'Une notification hebdomadaire à chaque famille : les récitations, la présence et les points de leur enfant, à l’heure du centre.',
      digestEnable: 'Activer le résumé hebdomadaire',
      day: 'Jour',
      hour: 'Heure',
      digestSaved: 'Réglage du résumé hebdomadaire enregistré',
      saveFailed: 'Enregistrement impossible',
      digestSub: 'Jour, heure et activation',
      attTitle: 'Rappel d’appel pour l’enseignant',
      attHint: 'Les jours ouvrés, après l’heure fixée, l’enseignant reçoit un rappel si l’appel de son cercle n’a pas été fait.',
      attEnable: 'Activer le rappel',
      afterHour: 'Après',
      attSaved: 'Réglage du rappel enregistré',
      attTitle2: 'Rappel à l’enseignant de faire l’appel',
      attSub: 'Activation et heure',
      language: 'Langue par défaut du centre',
      languageHint: 'Les écrans s’affichent dans cette langue pour qui n’en a pas choisi. Chacun peut toujours changer pour soi depuis le menu.',
    ),
    stu: SStu(
      status: {'active': 'Actif', 'paused': 'En pause', 'graduated': 'Diplômé', 'withdrawn': 'Parti'},
      noCircle: 'Aucun cercle',
      deleteTitle: 'Supprimer l’élève',
      deleteBody: '« {fullName} » et tout son dossier (présences, serd, points...) seront supprimés. Action irréversible.',
      title: 'Élèves',
      add: 'Ajouter un élève',
      searchPh: 'Rechercher par nom ou numéro d’élève',
      empty: 'Aucun élève pour l’instant',
      emptyHint: 'Commencez par ajouter le premier élève avec le bouton ci-dessous',
      noMatch: 'Aucun résultat correspondant',
      editDetails: 'Modifier les informations',
      deleteWithFile: 'Supprimer l’élève et son dossier',
      circleRequired: 'Choisissez un cercle pour l’élève',
      accountCreated: 'Compte élève créé',
      codeTaken: 'Ce numéro d’élève est déjà utilisé dans ce centre',
      saveError: 'Un problème est survenu à l’enregistrement',
      deleteBodyPlain: 'L’élève et tout son dossier (présences, serd, points...) seront supprimés. Action irréversible.',
      editTitle: 'Modifier l’élève',
      details: 'Informations de l’élève',
      fullName: 'Nom complet',
      nameRequired: 'Saisissez le nom de l’élève',
      birthDate: 'Date de naissance (facultatif)',
      tapToPick: 'Appuyez pour choisir',
      stageCircle: 'Niveau et cercle',
      stage: 'Niveau',
      allStages: 'Tous les niveaux',
      circleReq: 'Cercle (obligatoire)',
      noCircles: 'Aucun cercle ici — créez-en d’abord un dans la section des cercles',
      code: 'Numéro d’élève',
      codeHint: 'Suggéré automatiquement au choix du niveau ; vous pouvez le changer',
      codeRequired: 'Saisissez le numéro d’élève',
      contact: 'Coordonnées',
      phone: 'Numéro de mobile (facultatif)',
      whatsapp: 'Numéro WhatsApp (facultatif)',
      address: 'Adresse (facultatif)',
      login: 'Compte de connexion de l’élève',
      password: 'Mot de passe',
      passwordHint: 'Laissez vide pour créer le dossier sans compte de connexion',
      min8: 'Au moins 8 caractères',
      email: 'Vrai e-mail (facultatif)',
      emailHint: 'Sans lui, l’élève se connecte avec son numéro et le code du centre',
      statusLabel: 'Statut',
      saveChanges: 'Enregistrer les modifications',
      addBtn: 'Ajouter l’élève',
      recEdited: 'Récitation mise à jour',
      recDeleteTitle: 'Supprimer la récitation',
      recDeleteBody: 'Cette récitation sera supprimée et ses points retirés du solde de l’élève. Confirmer ?',
      deleted: 'Supprimé',
      nextPlan: 'Prochain programme',
      planPh: 'ex. mémoriser la sourate Al-Mulk, versets 1 à 15',
      planSaved: 'Programme enregistré',
      linkUpdated: 'Lien mis à jour',
      pickGuardian: 'Choisissez le parent',
      noGuardians: 'Aucun parent pour l’instant',
      newGuardian: 'Nouveau compte parent',
      guardianName: 'Nom du parent',
      loginId: 'Numéro de connexion ou e-mail',
      phoneOpt: 'Mobile (facultatif)',
      password8: 'Mot de passe (au moins 8 caractères)',
      create: 'Créer',
      guardianIncomplete: 'Remplissez le nom, le numéro de connexion et un mot de passe d’au moins 8 caractères',
      guardianCreated: 'Compte parent créé',
      allRecitations: 'Toutes les récitations',
      streak: 'Jours d’affilée',
      weeklyAttendance: 'Présence hebdomadaire',
      lastRecitation: 'Dernière récitation',
      surahV: 'Sourate {v}',
      recLine: '{type} • versets {ayahFrom} à {ayahTo}',
      progress: 'Progression',
      partsOf30: '{totalParts} juz sur 30',
      weeklyAttendanceV: 'Présence hebdomadaire : {v}',
      statsLine: '{totalRecitations} récitations  ·  série de {currentStreak} jours (record {longestStreak})  ·  dernière récitation {v}',
      noPlan: 'Aucun programme défini',
      sheikh: 'Enseignant',
      phone2: 'Mobile',
      addressLabel: 'Adresse',
      guardian: 'Parent',
      noGuardian: 'Aucun parent lié',
      linkedTo: 'Lié : {v}',
      newAccount: 'Nouveau compte',
      linkExisting: 'Lier un compte existant',
      unlink: 'Délier',
      log: 'Journal des récitations',
      noRecitations: 'Aucune récitation pour l’instant',
    ),
    sync: SSync(
      title: 'Synchronisation',
      allUp: 'Tout est envoyé',
      lastSync: 'Dernier envoi réussi : {time}',
      cached: 'Données enregistrées affichées faute de connexion',
      uploadNow: 'Envoyer maintenant',
      nothing: 'Rien en attente',
      rejected: 'Refusé par le serveur : {error}',
      discardTitle: 'Retirer de la file ?',
      discardBody: 'Cet enregistrement ne sera jamais envoyé.',
      retry: 'Réessayer',
      stripFailed: 'Certains enregistrements ont été refusés ({n}) — appuyez pour vérifier',
      counts: 'En attente : {waiting} · à vérifier : {failed}',
      nothingHint: 'Ce que vous enregistrez hors ligne s’affiche ici jusqu’à l’envoi.',
      queued: 'Enregistré {time} · tentatives : {n}',
      stripWaiting: 'En attente d’envoi : {n} — part automatiquement au retour en ligne',
      stripOffline: 'Pas de connexion — données enregistrées affichées',
      offlineTitle: 'Travailler hors ligne',
      offlineHint: 'Tout ce dont vous avez besoin est gardé sur ce téléphone — vos cercles, vos élèves et leurs dossiers, le serd, le calendrier et les messages — pour que l’application fonctionne sans internet ; ce que vous enregistrez part tout seul au retour en ligne.',
      offlineProgress: 'Téléchargement… {done} sur {total}',
      offlineNever: 'Rien n’a encore été téléchargé sur ce téléphone',
      offlineLast: 'Dernier téléchargement : {time}',
      offlineNow: 'Télécharger maintenant',
      offlineNeedsNet: 'Nécessite une connexion internet',
    ),
    teach: STeach(
      greeting: '{v}, {v2}',
      findStudent: 'Trouver un élève',
      noCircle: 'Vous n’êtes encore affecté à aucun cercle',
      noCircleHint: 'Demandez à l’administrateur de vous ajouter à un cercle, puis tirez vers le bas pour actualiser.',
      yourCircles: 'Vos cercles ({n})',
      checkedIn: 'Votre présence est enregistrée ✓',
      checkInFailed: 'Impossible d’enregistrer la présence — vérifiez votre connexion',
      circleScreen: 'Écran du cercle',
      assistant: 'Enseignant assistant',
      stage: 'Niveau : {stageName}',
      doneOf: '{done} sur {n} ont récité',
      checkIn: 'Pointer aujourd’hui',
      startLesson: 'Commencer la leçon',
      savedPoints: 'Enregistré ✓  +{points} points',
      attendanceFailed: 'Impossible d’enregistrer la présence',
      noStudents: 'Aucun élève dans ce cercle pour l’instant.\nDemandez à l’administrateur de les ajouter.',
      searchPh: 'Rechercher par nom ou numéro d’élève',
      all: 'Tous',
      notToday: 'N’a pas récité aujourd’hui',
      recitedToday: 'A récité aujourd’hui',
      sort: 'Trier la liste',
      alpha: 'Alphabétique',
      notFirst: 'Sans récitation d’abord',
      topPoints: 'Plus de points',
      xOfY: '{n} sur {n2}',
      noMatch: 'Personne ne correspond à votre choix.',
      showAll: 'Afficher tous les élèves',
      pointsN: '{totalPoints} points',
      recitedTodayN: 'A récité aujourd’hui ×{recitedToday}',
      dueReviews: 'Révision due ({n})',
      takeAttendance: 'Faire l’appel',
      attendanceIs: 'Présence : {value}',
      record: 'Enregistrer une récitation',
      general: 'Général',
    ),
    ui: SUi(
      credsText: 'Code du centre : {centerCode}\nNuméro / e-mail : {loginId}\nMot de passe : {password}',
      credsOnce: 'Le mot de passe n’est affiché qu’une seule fois — copiez-le maintenant et transmettez-le.',
      copied: 'Copié',
      copy: 'Copier',
      done: 'Terminé',
      skeletonTitle: 'Nom complet de l’élève ici',
      skeletonSub: 'Quelques informations en plus',
      add: 'Ajouter',
      search: 'Rechercher',
      noMatch: 'Aucun résultat correspondant',
      channelName: 'Notifications Bustan Al-Quran',
      channelDesc: 'Messages, rappels et validations',
      sessionEnded: 'Votre session a expiré ; reconnectez-vous',
      requestFailed: 'La requête n’a pas abouti',
      savedOffline: 'Enregistré sur votre appareil ; envoi automatique au retour en ligne',
      outboxCheckIn: 'Mon pointage au cercle',
      outboxNote: 'Une remarque sur un élève',
      outboxGathering: 'Activité : {title}',
      outboxExternal: 'Récitation externe : {name}',
      outboxEditRecitation: 'Modification de récitation',
      outboxDeleteRecitation: 'Suppression de récitation',
      outboxPlan: 'Le prochain programme d’un élève',
      waitingUpload: 'En attente d’envoi',
    ),
    weekly: SWeekly(
      smartToggle: 'Rapport hebdomadaire intelligent',
      smartHint: 'Ajoute : l’objectif de mémorisation, en avance ou en retard, la comparaison avec la semaine précédente et la remarque de l’enseignant',
      title: 'Rapport hebdomadaire',
      period: 'Du {from} au {to}',
      thisWeek: 'Cette semaine',
      lastWeek: 'Semaine précédente',
      recitations: 'Récitations',
      newPages: 'Nouvelles pages',
      reviews: 'Révisions',
      points: 'Points',
      attendance: 'Présence',
      attV: '{present} sur {days}',
      teacherNote: 'Remarque de l’enseignant',
      noNote: 'Pas de remarque de l’enseignant cette semaine',
      nextPlan: 'Pour la semaine prochaine',
      open: 'Rapport hebdomadaire',
    ),
    wird: SWird(
      title: 'La portion du jour',
      newPart: 'Nouvelle mémorisation',
      reviewPart: 'Révision',
      fromTeacher: 'Fixée par l’enseignant',
      suggested: 'Suggérée',
      done: 'Fait',
      sent: 'Envoyé à l’enseignant',
      todo: 'Pas encore récité',
      recite: 'Réciter maintenant',
      open: 'Ouvrir dans le mushaf',
      complete: 'La portion du jour est terminée, qu’Allah vous bénisse',
      none: 'Pas encore de portion : elle apparaît après la première mémorisation dans votre dossier.',
      dayOff: 'Aujourd’hui n’est pas un jour de cours ; la portion est facultative.',
      pages: '{n} pages',
    ),
  );

}

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

/// Members, teachers and permissions (admin).
class SMem {
  const SMem({required this.modules, required this.status, required this.password8, required this.passwordChanged, required this.accountSaved, required this.removeTitle, required this.removeBody, required this.editTitle, required this.selfNote, required this.role, required this.statusLabel, required this.modulesTitle, required this.viewOnly, required this.viewOnlyHint, required this.changePassword, required this.newPassword, required this.teacherCreated, required this.newTeacher, required this.teacherHint, required this.required, required this.loginId, required this.min8, required this.createAccount, required this.inviteCreated, required this.inviteError, required this.inviteTitle, required this.email, required this.inviteBtn, required this.pendingInvites});
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
  const SNotif({required this.now, required this.minutesAgo, required this.hoursAgo, required this.today, required this.yesterday, required this.title, required this.markAll, required this.prefs, required this.none, required this.notSaved, required this.noPush, required this.noPermission, required this.paused, required this.quiet, required this.types, required this.instantTitle, required this.instantBody, required this.instantBattery, required this.instantBatteryHint, required this.instantAutostart, required this.instantAutostartHint, required this.instantOk});
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
  const SProf({required this.thisMonth, required this.lastMonth, required this.last90, required this.vsPrev, required this.same, required this.newV, required this.recitations, required this.reciting, required this.points, required this.attendance, required this.serdHeard, required this.serdApproved, required this.daysPresent, required this.teacherDays, required this.students, required this.circles, required this.assistant, required this.teacher, required this.assistants, required this.recent, required this.teacherAtt, required this.nothing, required this.lastRec, required this.never, required this.today, required this.daysAgo, required this.profile, required this.myProfile, required this.message, required this.call, required this.notAllowed, required this.goalTitle, required this.memorized, required this.percentQuran, required this.pace, required this.paceV, required this.goalPace, required this.goalPaceV, required this.sinceStart, required this.forecast, required this.forecastGoal, required this.noPace, required this.noGoal, required this.goalStatus, required this.setGoal, required this.editGoal, required this.pagesPerDay, required this.targetPages, required this.note, required this.save, required this.clearGoal, required this.goalSaved, required this.invalidPages, required this.outboxGoal});
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

/// Quran serd (staff): list, entry, schedule, settings, report.
class SSerd {
  const SSerd({required this.overdueSuffix, required this.inactiveSuffix, required this.passSuffix, required this.wholeJuz, required this.noCircle, required this.linkStudent, required this.approved, required this.rejectTitle, required this.rejectReason, required this.reject, required this.rejected, required this.deleteTitle, required this.deleteBody, required this.deleted, required this.approve, required this.reapprove, required this.certIssued, required this.issueCert, required this.schedule, required this.report, required this.settings, required this.record, required this.all, required this.pending, required this.scheduled, required this.approvedChip, required this.rejectedChip, required this.empty, required this.requestedN, required this.assigned, required this.openAny, required this.recordShort, required this.mine, required this.mineEmpty, required this.saved, required this.wholeAlways, required this.newErrorType, required this.editErrorType, required this.name, required this.perErrors, required this.deductPct, required this.active, required this.fillAll, required this.stagePortions, required this.stagePass, required this.settingsTitle, required this.settingsHint, required this.general, required this.passPct, required this.wholePoints, required this.defaultPortions, required this.wholeNumbers, required this.saveGeneral, required this.errorTypes, required this.perRule, required this.byStage, required this.byStageHint, required this.usesGeneral, required this.pickOrType, required this.pickPart, required this.sentScore, required this.saveFailedNet, required this.newTitle, required this.scheduledTitle, required this.pickStudent, required this.typeName, required this.clearPick, required this.dateLine, required this.parts, required this.errors, required this.perRule2, required this.expected, required this.notesOpt, required this.submit, required this.noResults, required this.reportTitle, required this.totalSessions, required this.waiting, required this.avgScore, required this.pointsGiven, required this.approvedParts, required this.juzLine, required this.topErrors, required this.examiners, required this.partsLine, required this.examiner, required this.circleTeacher, required this.assignedTo, required this.openToAny, required this.noStudent, required this.scoreLabel, required this.resultLine, required this.rejectReasonV, required this.whole, required this.pickJuz, required this.juzLine2, required this.addJuz, required this.passed, required this.repeat, required this.pickBoth, required this.scheduledOk, required this.scheduleHint, required this.student, required this.when, required this.partsWanted, required this.assign, required this.scheduleBtn, required this.outboxLabel});
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
}

/// Center settings (admin).
class SSet {
  const SSet({required this.loadSome, required this.saved, required this.fromGallery, required this.takePhoto, required this.tooBig1, required this.logoUploaded, required this.logoAdminOnly, required this.logoFailed, required this.logoHttps, required this.backdateRange, required this.intro, required this.identity, required this.name, required this.uploading, required this.uploadLogo, required this.remove, required this.logoLink, required this.primary, required this.secondary, required this.link, required this.timezone, required this.saveIdentity, required this.workdays, required this.workdaysHint, required this.working, required this.serdDay, required this.saveWorkdays, required this.features, required this.backdate, required this.countryCode, required this.whatsapp, required this.locationLabel, required this.lat, required this.lng, required this.method, required this.madhab, required this.reciters, required this.recitersHint, required this.defaultReciter, required this.firstInList, required this.market, required this.leaderboard, required this.teacherStudents, required this.saveSettings, required this.adminOnly, required this.loadOne, required this.digestTitle, required this.digestHint, required this.digestEnable, required this.day, required this.hour, required this.digestSaved, required this.saveFailed, required this.digestSub, required this.attTitle, required this.attHint, required this.attEnable, required this.afterHour, required this.attSaved, required this.attTitle2, required this.attSub, required this.language, required this.languageHint});
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

class S {
  const S({required this.lang, required this.common, required this.labels, required this.banners, required this.portal, required this.record, required this.badges, required this.market, required this.serdCard, required this.ann, required this.auth, required this.badgesStaff, required this.cal, required this.cert, required this.chat, required this.dash, required this.garden, required this.gather, required this.ins, required this.mem, required this.mkt, required this.nav, required this.notif, required this.org, required this.plan, required this.priv, required this.prof, required this.quran, required this.rec, required this.rep, required this.serd, required this.set, required this.stu, required this.sync, required this.teach, required this.ui});
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
  final SAuth auth;
  final SBadgesStaff badgesStaff;
  final SCal cal;
  final SCert cert;
  final SChat chat;
  final SDash dash;
  final SGarden garden;
  final SGather gather;
  final SIns ins;
  final SMem mem;
  final SMkt mkt;
  final SNav nav;
  final SNotif notif;
  final SOrg org;
  final SPlan plan;
  final SPriv priv;
  final SProf prof;
  final SQuran quran;
  final SRec rec;
  final SRep rep;
  final SSerd serd;
  final SSet set;
  final SStu stu;
  final SSync sync;
  final STeach teach;
  final SUi ui;

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
      items: {'/dashboard': 'لوحة التحكم', '/sync': 'المزامنة', '/students': 'الطلاب', '/circles': 'الحلقات', '/attendance': 'الحضور', '/gatherings': 'المجالس والأنشطة', '/external-recitations': 'التسميع الخارجي', '/reviews': 'المراجعة المقترحة', '/search': 'بحث شامل', '/quran': 'المصحف', '/serd': 'السرد القرآني', '/stages': 'المراحل', '/points': 'النقاط', '/badges': 'الشارات', '/market': 'سوق النقاط', '/circle-challenges': 'منافسات الحلقات', '/activities': 'الأنشطة', '/announcements': 'الإعلانات', '/calendar': 'التقويم', '/chat': 'المحادثات', '/notifications': 'الإشعارات', '/reports': 'التقارير', '/certificates': 'الشهادات', '/members': 'الأعضاء والأدوار', '/deletion-requests': 'طلبات حذف البيانات', '/audit': 'سجل العمليات', '/site': 'الموقع العام', '/settings': 'إعدادات المركز'},
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
      stageCode: 'كود المرحلة (يستخدم برقم الطالب المقترح)',
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
      items: {'/dashboard': 'Dashboard', '/sync': 'Sync', '/students': 'Students', '/circles': 'Circles', '/attendance': 'Attendance', '/gatherings': 'Gatherings & activities', '/external-recitations': 'External recitations', '/reviews': 'Suggested review', '/search': 'Search', '/quran': 'Quran', '/serd': 'Quran serd', '/stages': 'Stages', '/points': 'Points', '/badges': 'Badges', '/market': 'Points market', '/circle-challenges': 'Circle challenges', '/activities': 'Activities', '/announcements': 'Announcements', '/calendar': 'Calendar', '/chat': 'Messages', '/notifications': 'Notifications', '/reports': 'Reports', '/certificates': 'Certificates', '/members': 'Members & roles', '/deletion-requests': 'Data deletion requests', '/audit': 'Activity log', '/site': 'Public page', '/settings': 'Center settings'},
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
      stageCode: 'Stage code (used in the suggested student number)',
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
  );

}

import type { Dictionary } from './ar';

// English. Terms of art keep one fixed rendering everywhere (see docs/I18N.md
// glossary): حلقة = circle, تسميع = recitation, سرد = serd (full review),
// ولي الأمر = guardian, المركز = center.
export const en: Dictionary = {
  meta: {
    title: 'Bustan Al-Quran',
    description: 'Bustan Al-Quran - the platform for running Quran memorization centers',
  },

  client: {
    language: 'Language',
    working: 'Working...',
    errorTitle: 'Something went wrong',
    errorBody: 'Sorry, there was a temporary problem. Please try again.',
    retry: 'Try again',
    home: 'Home',
  },

  common: {
    brand: 'Bustan Al-Quran',
    login: 'Sign in',
    registerCenter: 'Register your center',
    registerCenterNow: 'Register your center now',
    email: 'Email',
    password: 'Password',
    centerLink: 'Center link',
    identifier: 'ID / student number or email',
    backToLogin: 'Back to sign in',
    privacy: 'Privacy',
    support: 'Support',
    deleteAccount: 'Delete account',
  },

  marketing: {
    heroTitle: 'Bustan Al-Quran',
    heroBody:
      'The platform for running Quran memorization centers — register your center and take full control of your teachers, students and circles from one dashboard, with no technical hassle.',
    steps: [
      { title: '1. Register your center', body: 'Your center’s name and its own link - one minute, and your account is ready as its admin.' },
      { title: '2. Set it up', body: 'Add teachers, stages and circles, and tune points and badges to suit your center.' },
      { title: '3. Run everything', body: 'Attendance, recitation, keeping guardians in the loop - all from one dashboard you fully control.' },
    ],
  },

  lookup: {
    subtitle: 'Enter your center’s link to go to its sign-in page',
    noCenter: 'No center yet?',
    searching: 'Searching...',
    submit: 'Continue to sign in',
    platformOwner: 'Platform owner?',
    platformOwnerLink: 'Sign in here',
    errorEmpty: 'Enter your center’s link',
    errorNotFound: 'No center has this link - check the spelling',
  },

  signup: {
    subtitle: 'One minute, and you can start right away with a full admin dashboard for your center',
    haveCenter: 'Already registered a center?',
    signIn: 'Sign in',
    benefits: [
      'Your own center dashboard on its own link',
      'Add teachers, students and circles, and control what each can do',
      'Record attendance, recitation, points and badges in one place',
    ],
    orgName: 'Center name',
    orgNamePlaceholder: 'Al-Noor Quran Center',
    creating: 'Creating your center...',
    submit: 'Create center',
    errorRequired: 'All fields are required',
    errorSlug: 'Invalid link - lowercase English letters, numbers and dashes only, no reserved words',
    errorConfirmEmail: 'Check your email to confirm your account first - then come back to finish creating the center',
    errorSlugTaken: 'This link is already taken, try another one',
    errorEmailTaken: 'This email is already registered - sign in instead',
    errorWeakPassword: 'Password too weak - use at least 8 characters',
  },

  tenantHome: {
    preview: 'Preview — this is what a signed-out visitor sees.',
    backToSettings: 'Back to settings',
    contact: 'Contact:',
    siteDisabled: 'The public page is switched off — turn it on from this screen first',
  },

  login: {
    subtitle: 'For teachers, staff, students and guardians',
    forgotCenter: 'Forgot your center’s link?',
    findIt: 'Find it here',
    noCenter: 'No center?',
    signingIn: 'Signing in...',
    submit: 'Sign in',
    forgotPassword: 'Forgot your password?',
    errorNoCenter: 'Center not found',
    errorCredentials: 'Incorrect email or password',
    errorNotMember: 'Your account is not linked to this center',
  },

  forgot: {
    title: 'Forgot password',
    subtitle: 'If your account has an email address, we’ll send a reset link to it',
    sent: 'If this account is registered with a real email address, a password reset link is on its way. Check your inbox (and spam folder).',
    sending: 'Sending...',
    submit: 'Send reset link',
    errorEmpty: 'Enter your ID or email',
    errorNoEmail: 'This account has no email address to recover the password - ask the center’s admin to reset it from the members page',
  },

  reset: {
    title: 'New password',
    subtitle: 'Enter the new password for your account',
    checking: 'Checking the link...',
    invalid: 'This link is invalid or has expired, request a new one',
    requestNew: 'Request a new link',
    done: 'Password updated, taking you to sign in...',
    newPassword: 'New password',
    confirm: 'Confirm password',
    saving: 'Saving...',
    submit: 'Save password',
    errorShort: 'Password must be at least 8 characters',
    errorMismatch: 'The passwords do not match',
    errorFailed: 'Could not update the password, try requesting a new link',
  },

  join: {
    incompleteTitle: 'Incomplete invitation link',
    incompleteBody: 'Make sure you used the full link from the person who invited you.',
    invalidTitle: 'Invalid invitation',
    invalidBody: 'This invitation has expired or was already used. Ask the center’s admin to send you a new one.',
    inviteFrom: 'Invitation from {org}',
    asRole: 'as {role}',
    asRoleCreate: 'as {role} - create a password for your account',
    signedInAs: 'Signed in as {email}. Press confirm to join.',
    joining: 'Joining...',
    confirm: 'Confirm and join',
    creating: 'Creating and joining...',
    create: 'Create account and join',
    errorConfirmEmail: 'Check your email to confirm your account first, then open the invitation link again to finish joining',
    roles: { admin: 'admin', teacher: 'teacher', guardian: 'guardian', student: 'student' },
  },

  consent: {
    invalidTitle: 'Invalid link',
    invalidBody: 'Check the link you received, or contact the center.',
    title: 'Guardian consent',
    asks: 'The center asks for your consent for {student} to take part in:',
    place: 'Place: {place}',
    approved: 'Your consent has been recorded. Thank you.',
    declined: 'Your refusal has been recorded.',
    approve: 'I agree',
    decline: 'I do not agree',
  },

  legal: {
    privacyTitle: 'Privacy policy',
    privacy1: '{name} collects only the information needed to manage student enrolment and follow their progress: name, contact details, and this center’s recitation, serd and attendance records.',
    privacy2: 'This data belongs to your center only; no other center on the platform can reach it - every center is fully isolated. A student or guardian sees only their own child’s data.',
    privacy3Before: 'Your data is never shared with anyone for marketing. A guardian or student can ask to see or delete their data through the',
    privacy3Link: 'deletion request page',
    privacy3After: 'or by contacting the center’s administration.',
    supportTitle: 'Help & support',
    support1: 'If you have trouble signing in or using the app, contact the administration of {name}',
    viaEmail: 'at',
    directly: 'directly',
    support2: 'To sign in you need: the center code + your login number or email + the password the administration gave you. If you forget your password, the administration can change it for you.',
    deleteTitle: 'Request account and data deletion',
    delete1: 'To request deletion of your account or your child’s data held by {name} (name, attendance, recitation and serd records, messages), contact the administration',
    viaChannels: 'through the center’s published contact channels',
    delete2: 'Data is deleted once the request is verified, except what must be kept for legal or financial reasons.',
    delete3: 'If you have an account you can also send the request from the app or website: “My account & data” → “Request deletion of my account and data”; you will be notified of the outcome.',
  },

  notFound: {
    title: 'This page does not exist',
    body: 'Check the link, or go back to the home page.',
    code: '404',
  },
};

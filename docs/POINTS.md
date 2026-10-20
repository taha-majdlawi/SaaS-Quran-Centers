# Points

A student's `total_points` is the sum of three frozen sources, kept by triggers:

- recitations (`daily_achievements.points_awarded`);
- approved serd (`serd_sessions.points_awarded`);
- the ledger `point_adjustments`, which holds attendance, teacher bonus and penalty, and the opening balance.

Database: `supabase/migrations/0096_points_system.sql`.

## How a recitation scores (per center)

The setting `points_mode`, changed with `set_points_mode` from the web Points page or the app's Points screen, has two values:

- **`per_recitation`** (the default; existing centers stay on it): every recitation is worth its grade's points.
- **`per_page`**: `points = max(1, round(pages × grade points × factor))`.
  - The factor is 1 for new memorization and 0.5 for review.
  - A grade worth 0 gives 0.
  - The grade's points are then "points per page".

Pages are counted with `recitation_pages()`: every mushaf page the ayah range touches counts by the share of its ayahs inside the range. Examples:

| Range | Pages |
|---|---|
| Al-Fatiha | 1.0 |
| Al-Ikhlas | ≈ 0.27 |
| Nuh | ≈ 1.67 |
| The whole mushaf | 604 |

The app has the same table in `apps/mobile/lib/core/data/quran_pages.dart`, generated from 0075's `quran_pages`, for the estimate it shows in the recitation sheet. The server computes the final value.

When a recitation is saved, its points are frozen. Editing that recitation re-prices it only when one of these changes:

- the grade;
- in per-page mode, also the type or the ayahs.

Changing the mode or the values never touches history.

## The ledger (`point_adjustments`)

| source | written by | rule |
|---|---|---|
| `attendance` | trigger on `attendance` | Value per status (`attendance_point_values`, default present +1 / absent −1), from the date in setting `attendance_points_from` (empty = off). A correction replaces the day's points; deleting the day deletes them. `set_attendance_points` sets the values and the date: days before the new date lose their points, and uncounted days from it are counted. |
| `bonus` / `penalty` | `teacher_award_points` | The teacher (of the student, with the students module) or the admin picks a **reason** from `point_reasons`. Value and sign come from the reason, and its name is copied into `reason_label`. `client_ref` makes the app's offline replay safe. `delete_point_adjustment`: a teacher can undo their own entry within 2 days; the admin can undo any entry. |
| `opening` | `set_opening_balance` (admin) | One per student. Setting it again replaces it; 0 removes it. |

The tables are RPC-only: there are no direct writes, and viewing or locked accounts are blocked by `a_deny_readonly_write`.

## How did I earn my points

`get_student_points_breakdown(org, student)` is readable by the admin, the student's teacher, the student and their guardian. It returns:

- the total;
- `rows_sum`;
- a summary;
- rows grouped as recitations by type × grade, serd, attendance, bonus and penalty by reason, and opening;
- the latest entries, with whether the caller may undo each one.

If `rows_sum` differs from the total, the staff view warns. The admin's **Add the totals up again** (`recompute_all_points`) re-adds every total from the frozen values without re-pricing anything.

It is shown on:

- **web:** the staff student profile (with the add / deduct form and the opening balance), and `/my/points` in the portal;
- **app:** the student file (staff), the portal home, and a star button on every student of the roster and in lesson mode.

## Tests

- `supabase/tests/invariants.sql` (block 0096) covers:
  - per-page review of Al-Fatiha;
  - no direct writes to the ledger;
  - penalty idempotency;
  - an attendance correction;
  - the breakdown adding up;
  - the student refused.
- `apps/mobile/test/quran_pages_test.dart` checks the spec's page and point examples.

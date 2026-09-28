'use client';

import { useState } from 'react';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

interface Stage {
  id: string;
  name: string;
}

interface Circle {
  id: string;
  name: string;
  stage_id: string | null;
}

/**
 * Client-side piece of the add-student form: picking a stage filters the
 * circle options down to that stage's circles and swaps in the suggested
 * student code for it (see next_student_code in
 * 0012_stage_codes_and_student_numbering.sql). A circle is required -
 * every student must belong to one on registration.
 */
export function StudentFormFields({
  stages,
  circles,
  suggestedCodes,
  labels,
}: {
  stages: Stage[];
  circles: Circle[];
  suggestedCodes: Record<string, string>;
  /** t.staff.studentForm */
  labels: Dictionary['staff']['studentForm'];
}) {
  const L = { studentForm: labels };
  const [stageId, setStageId] = useState('');
  const [circleId, setCircleId] = useState('');
  const [code, setCode] = useState('');

  const filteredCircles = circles.filter((c) => c.stage_id === stageId);

  return (
    <>
      <label className="text-sm font-medium text-gray-700">
        {L.studentForm.stage}
        <select
          required
          value={stageId}
          onChange={(e) => {
            const newStageId = e.target.value;
            setStageId(newStageId);
            setCircleId('');
            setCode(suggestedCodes[newStageId] ?? '');
          }}
          className="mt-1 w-full rounded border px-3 py-2 text-sm"
        >
          <option value="" disabled>
            {L.studentForm.pickStage}
          </option>
          {stages.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name}
            </option>
          ))}
        </select>
        {!stages.length && (
          <p className="mt-1 text-xs text-gray-400">
            {L.studentForm.noStages}{' '}
            <a href="/stages/new" className="text-brand hover:underline">
              {L.studentForm.addStage}
            </a>
          </p>
        )}
      </label>

      <label className="text-sm font-medium text-gray-700">
        {L.studentForm.circle}
        <select
          name="circleId"
          required
          disabled={!stageId}
          value={circleId}
          onChange={(e) => setCircleId(e.target.value)}
          className="mt-1 w-full rounded border px-3 py-2 text-sm disabled:bg-gray-50"
        >
          <option value="" disabled>
            {stageId ? L.studentForm.pickCircle : L.studentForm.stageFirst}
          </option>
          {filteredCircles.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        {stageId && !filteredCircles.length && (
          <p className="mt-1 text-xs text-gray-400">
            {L.studentForm.noCircles}{' '}
            <a href="/circles/new" className="text-brand hover:underline">
              {L.studentForm.addCircle}
            </a>
          </p>
        )}
      </label>

      <label className="text-sm font-medium text-gray-700">
        {L.studentForm.code}
        <input
          name="studentCode"
          required
          value={code}
          onChange={(e) => setCode(e.target.value)}
          placeholder={L.studentForm.stageFirst}
          className="mt-1 w-full rounded border px-3 py-2 text-sm"
        />
      </label>
    </>
  );
}

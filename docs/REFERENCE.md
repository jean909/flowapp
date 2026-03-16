# Referințe

Scurt rezumat pentru feature-uri și baze de date. Detalii în fișierele listate.

---

## Diets & Programs

Sistem de planuri nutriție (Diets) și fitness (Programs) care influențează recomandările și tracking-ul.

- **Diets:** macro targets, filtrare rețete, compliance tracking.
- **Programs:** workout plans, progresie, completion tracking.
- **Tabele:** `diets`, `fitness_programs`, `user_active_diets`, `user_active_programs`, `diet_compliance_logs`, `program_progress_logs`.
- **Regulă:** max 1 dietă activă + 1 program activ per user.

Detalii: [DIETS_AND_PROGRAMS_DEFINITION.md](./DIETS_AND_PROGRAMS_DEFINITION.md) (structuri JSON, UI flow, seed data).

---

## Exercises DB

Tabelul `exercises`: 100+ exerciții (name_en/name_de, muscle_group, equipment, difficulty, instructions, video_url, calories_per_rep).

- **Creare:** `supabase_exercises_schema.sql` + `supabase_exercises_comprehensive.sql`.
- **În app:** `searchExercises()`, `getExercisesByMuscleGroup()`, `getExercisesByEquipment()`, `getExercisesByDifficulty()`, `getExercisesFiltered()`.

Detalii: [EXERCISES_DATABASE_README.md](./EXERCISES_DATABASE_README.md) (categorii, usage, maintenance).

---

## Journal processing (fix istoric)

- **Problema:** `exercise_logs.exercise_id` NOT NULL dar custom exercises foloseau doar `custom_exercise_id`. Fix: `ALTER TABLE exercise_logs ALTER COLUMN exercise_id DROP NOT NULL` (în `supabase_exercise_logs_fix_nullable.sql`).
- **Duration/calories din text:** AI prompt îmbunătățit; fallback în cod: extragere distanță din notes, calcul duration_minutes și calories_burned pe tip exercițiu (Running, Walking, etc.).

Detalii: [JOURNAL_PROCESSING_FIX_REPORT.md](./JOURNAL_PROCESSING_FIX_REPORT.md) (pași, logging, testare).

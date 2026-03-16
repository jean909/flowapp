# Setup Flow

Ghid rapid pentru Supabase, Realtime, Recipes și Exercise images.

---

## Supabase (schema + marketplace)

1. **Supabase Dashboard** → SQL Editor → New Query
2. Rulează SQL-ul din `supabase_marketplace_schema.sql` (din root).
3. Verifică în Table Editor: `available_addons`, `user_addons`, `menstruation_logs`, `menstruation_setup`, `menstruation_symptoms`.
4. În app: Side Menu → Premium Add-ons; activează Menstruation Tracker și verifică datele.

**RLS:** Toate tabelele au RLS; utilizatorii văd doar propriile date.

---

## Supabase Realtime (Social Feed)

1. **Dashboard** → Database → Replication (sau Realtime)
2. Activează pentru: `social_posts`, `social_likes`, `social_comments` (toggle ON → Save).
3. Sau rulează `supabase_realtime_setup.sql` în SQL Editor.

**Verificare:** Deschide app pe 2 device-uri; postează pe unul → apare pe celălalt fără refresh.

**Troubleshooting:** RLS trebuie activat pe tabele; Realtime respectă policy-urile. Verifică WebSockets / firewall.

---

## Recipes (generare cu AI)

- **DB:** Rulează `supabase_recipes_schema.sql` în SQL Editor.
- **Storage:** Creează bucket `recipe_images` (public).
- **Script:** `pip install -r requirements_recipes.txt` apoi:
  - `python generate_recipes.py --recipe "Nume Reteta"`
  - `python generate_recipes.py --count 10` sau `--meal-type BREAKFAST --count 5`

---

## Exercise images (Replicate)

- **Storage:** Supabase → Storage → New bucket `exercise_images` (public).
- **Script:** `pip install -r requirements_exercise_images.txt` apoi:
  - `python generate_exercise_images.py` (toate) sau `--limit 5` / `--start-from 10`

Config: URL/Key Supabase și token Replicate în script.

---

## Website (Next.js)

- `cd website` → `npm install` → `npm run dev` → http://localhost:3000
- **Auth fără confirmare email:** Supabase → Authentication → Providers → Email → dezactivează "Confirm email".

Vezi `website/README.md` pentru env vars și deployment.

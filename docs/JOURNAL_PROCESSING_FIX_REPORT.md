# Raport: Probleme și soluții pentru procesarea Journal Entries

## Probleme identificate

### 1. Eroare 400 la inserarea în `exercise_logs`
**Eroare:** `PostgREST; error=23502` (NOT NULL violation)

**Cauză:**
- Schema originală `exercise_logs` are `exercise_id UUID NOT NULL`
- Când salvăm custom exercises, setăm doar `custom_exercise_id` și nu setăm `exercise_id`
- Constraint-ul `check_exercise_reference` permite fie `exercise_id` fie `custom_exercise_id`, dar `exercise_id` este încă NOT NULL

**Soluție:**
- Creat `supabase_exercise_logs_fix_nullable.sql` care face `exercise_id` nullable
- Trebuie rulat în Supabase SQL Editor

### 2. AI nu returnează `duration_minutes` și `calories_burned`
**Problema:**
- Când user spune "am fugit 10km" sau "Ran 4 km", AI returnează:
  - `duration_minutes: 0`
  - Nu returnează `calories_burned`
  - Informațiile sunt în `notes` dar nu sunt procesate

**Soluție implementată:**

#### A. Îmbunătățit prompt-ul AI
- Adăugat instrucțiuni explicite pentru AI să calculeze `duration_minutes` din distanță
- Adăugat instrucțiuni pentru AI să returneze `calories_burned` calculat
- Exemple: Running ~6-8 min/km, ~60-80 kcal/km

#### B. Logică de fallback în cod
- Extrage distanță din `notes` folosind regex: `(\d+(?:\.\d+)?)\s*(?:km|kilometer|mi|mile)`
- Calculează `duration_minutes` bazat pe tipul de exercițiu:
  - Running/Jogging: ~7 min/km
  - Walking: ~11 min/km
  - Other cardio: ~8 min/km
- Calculează `calories_burned` bazat pe tipul de exercițiu:
  - Running: ~11 kcal/min
  - Walking: ~4.5 kcal/min
  - Cycling: ~9 kcal/min
  - Other cardio: ~9 kcal/min
- Folosește valoarea de la AI dacă este furnizată, altfel calculează

### 3. Custom exercises nu se salvează corect
**Problema:**
- Custom exercises create din journal nu apar pe homepage

**Soluție:**
- Adăugat logging detaliat pentru a identifica unde se pierde informația
- Verificat că `searchExercises` caută corect în ambele tabele
- Verificat că `getDailyExerciseLogs` fetch-uiește corect custom exercises

## Modificări făcute

### 1. `lib/services/replicate_service.dart`
- ✅ Îmbunătățit prompt-ul pentru `processJournalEntry` să returneze `duration_minutes` și `calories_burned`
- ✅ Adăugat instrucțiuni explicite pentru calcularea acestora din distanță

### 2. `lib/services/supabase_service.dart`
- ✅ Adăugat logică pentru extragerea distanței din `notes`
- ✅ Adăugat calculare automată a `duration_minutes` din distanță
- ✅ Adăugat calculare automată a `calories_burned` bazat pe tipul de exercițiu
- ✅ Adăugat logging detaliat pentru debugging
- ✅ Folosește valoarea de la AI dacă este furnizată, altfel calculează

### 3. `supabase_exercise_logs_fix_nullable.sql` (NOU)
- ✅ Script SQL pentru a face `exercise_id` nullable
- ✅ Trebuie rulat în Supabase SQL Editor

## Pași pentru rezolvare completă

### Pas 1: Rulare SQL în Supabase
```sql
-- Rulare în Supabase SQL Editor
-- Fișier: supabase_exercise_logs_fix_nullable.sql
ALTER TABLE public.exercise_logs
ALTER COLUMN exercise_id DROP NOT NULL;
```

### Pas 2: Testare
1. Creează un journal entry: "am fugit 10km"
2. Verifică logs pentru:
   - `[Journal] Searching for exercise: Running`
   - `[Journal] Extracted duration from notes: X km = Y minutes`
   - `[Journal] Exercise log saved successfully`
3. Verifică pe homepage că apare workout-ul

## Logging adăugat

Toate logurile încep cu prefixe pentru ușurința debugging-ului:
- `[Journal]` - procesarea journal entries
- `[getDailyExerciseLogs]` - fetch și enrich logs
- `[Dashboard]` - afișare pe homepage

## Note importante

1. **Calories burned:** AI ar trebui să returneze valoarea, dar dacă nu o face, codul calculează automat
2. **Duration:** Dacă AI nu returnează `duration_minutes`, codul extrage din `notes` și calculează
3. **Minimum calories:** Dacă totul eșuează, se folosește un minimum de 5 kcal/min pentru orice exercițiu cu durată

## Testare recomandată

1. ✅ "am fugit 10km" - ar trebui să calculeze ~70 min și ~770 kcal
2. ✅ "Ran 4 km" - ar trebui să calculeze ~28 min și ~308 kcal
3. ✅ "am mers 5km" - ar trebui să calculeze ~55 min și ~247 kcal
4. ✅ "am făcut 3 seturi de bench press cu 80kg" - ar trebui să folosească reps/sets


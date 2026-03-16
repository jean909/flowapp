# Diets and Programs - Definition & Implementation

## Overview
"Diets and Programs" este un sistem care permite utilizatorilor să activeze planuri structurate de nutriție (Diets) și fitness (Programs) care influențează automat recomandările și tracking-ul din aplicație.

---

## 1. DIETS (Planuri Alimentare)

### Ce înseamnă o Dietă în Flow:
O dietă este un plan alimentar structurat care:
- **Setează macro targets automat** (ratii de protein/carbs/fat)
- **Sugerează mese** bazate pe principiile dietei
- **Track compliance** - verifică dacă utilizatorul respectă dieta
- **Ajustează recomandările** de nutriție în funcție de dietă
- **Filtrează rețete** pentru a sugera doar cele compatibile

### Structura unei Diets:
```dart
{
  id: UUID,
  name_en: "Keto Diet",
  name_de: "Keto-Diät",
  description_en: "Low carb, high fat diet...",
  description_de: "Kohlenhydratarme, fettreiche Diät...",
  macro_ratios: {
    protein_percentage: 25,
    carbs_percentage: 5,
    fat_percentage: 70
  },
  allowed_foods: ["meat", "fish", "eggs", "vegetables"],
  restricted_foods: ["grains", "sugar", "fruits"],
  daily_calorie_adjustment: -500, // Optional deficit/surplus
  difficulty: "INTERMEDIATE",
  duration_weeks: 8,
  image_url: "..."
}
```

### Funcționalități când o Dietă este activă:
1. **Auto-adjust macro targets** în profil
2. **Filter recipes** - doar rețete compatibile
3. **Food suggestions** - prioritizează alimente permise
4. **Compliance tracking** - % respectare zilnică
5. **Notifications** - mementouri pentru respectarea dietei

---

## 2. PROGRAMS (Programe de Fitness)

### Ce înseamnă un Program în Flow:
Un program este un plan de fitness structurat care:
- **Include workout plans** cu exerciții planificate pe săptămâni
- **Setează progresie** (progressive overload)
- **Track completion** - progres zilnic/săptămânal
- **Sugerează exerciții** bazate pe program
- **Planifică automat** workout-urile

### Structura unui Program:
```dart
{
  id: UUID,
  name_en: "Push Pull Legs",
  name_de: "Push Pull Beine",
  description_en: "6-day split program...",
  description_de: "6-Tage-Split-Programm...",
  difficulty: "INTERMEDIATE",
  duration_weeks: 12,
  days_per_week: 6,
  workout_schedule: [
    {
      week: 1,
      day: 1,
      workout_type: "PUSH",
      exercises: [
        {exercise_id: "...", sets: 4, reps: 8, weight_progression: "linear"}
      ]
    }
  ],
  image_url: "..."
}
```

### Funcționalități când un Program este activ:
1. **Auto-schedule workouts** în calendar
2. **Exercise suggestions** - prioritizează exercițiile din program
3. **Progression tracking** - urmărește creșterea în greutate/reps
4. **Completion badges** - recompense pentru finalizare
5. **Rest day reminders** - notificări pentru zilele de odihnă

---

## 3. User Active Diets/Programs

### Structura:
```dart
{
  user_id: UUID,
  diet_id: UUID (nullable),
  program_id: UUID (nullable),
  started_at: TIMESTAMP,
  target_end_date: TIMESTAMP,
  current_week: INTEGER,
  compliance_score: DECIMAL, // 0-100%
  status: "ACTIVE" | "PAUSED" | "COMPLETED"
}
```

### Reguli:
- Utilizatorul poate avea **maxim 1 dietă activă** și **1 program activ** simultan
- Poate pausa/rezuma oricând
- Poate schimba (înlocuiește vechiul)

---

## 4. Integrare în Dashboard

### Card "Diets and Programs":
- Afișează dieta activă (dacă există)
- Afișează programul activ (dacă există)
- Buton "Browse" pentru a vedea toate opțiunile
- Progress indicator pentru dieta/programul activ

### Impact pe Dashboard:
- **Macro targets** ajustate automat dacă dietă activă
- **Workout suggestions** bazate pe programul activ
- **Compliance score** vizibil
- **Next workout** din program planificat

---

## 5. Implementare Tehnică

### Tabele Supabase:
1. `diets` - toate dietele disponibile
2. `fitness_programs` - toate programele disponibile
3. `user_active_diets` - dietele active ale utilizatorilor
4. `user_active_programs` - programele active ale utilizatorilor
5. `diet_compliance_logs` - tracking zilnic compliance
6. `program_progress_logs` - tracking progres program

### Servicii:
- `getAvailableDiets()` - toate dietele
- `getAvailablePrograms()` - toate programele
- `activateDiet(dietId)` - activează o dietă
- `activateProgram(programId)` - activează un program
- `getActiveDiet()` - dieta activă
- `getActiveProgram()` - programul activ
- `updateCompliance()` - actualizează compliance
- `updateProgramProgress()` - actualizează progres

---

## 6. UI/UX Flow

1. **Dashboard Card** → Tap → "Diets and Programs Page"
2. **Diets and Programs Page**:
   - Tabs: "Diets" | "Programs"
   - Listă cu toate opțiunile
   - Card pentru fiecare cu: imagine, nume, descriere, difficulty, duration
   - Buton "Activate" pe fiecare
   - Secțiune "Active" la început (dacă există)
3. **Activate Dialog**:
   - Confirmare
   - Setare start date
   - Preview impact (macro changes, etc.)
4. **Back to Dashboard** → Card actualizat cu progress

---

## 7. Seed Data

### Diets inițiale:
- Keto Diet
- Mediterranean Diet
- Vegan Diet
- Low Carb Diet
- Intermittent Fasting (16/8)
- High Protein Diet

### Programs inițiale:
- Push Pull Legs (6 days)
- Full Body (3 days)
- Upper Lower (4 days)
- Cardio Focus (5 days)
- Strength Building (4 days)



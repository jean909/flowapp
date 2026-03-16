# Audit funcționalități – Flow (Flutter)

Lista de îmbunătățiri prioritizate pe zone: bug-uri, fluxuri incomplete, consistență, features lipsă.

---

## P0 – Bug-uri / risc crash

### 1. `setState` după `dispose` (async)
- **Unde:** `lib/features/analytics/pages/progress_page.dart` – `_loadData()` face `setState` la final fără `if (mounted)`.
- **Problema:** Dacă userul părăsește pagina înainte ca datele să se încarce → crash „setState() called after dispose”.
- **Fix:** Înainte de orice `setState` după `await`, adaugă `if (!mounted) return;` apoi `setState(...)`.

### 2. `setState` înainte de `mounted` (Dashboard)
- **Unde:** `lib/features/dashboard/pages/dashboard_page.dart` – în `catch` la `_loadData()`: se apelează `setState` apoi `if (mounted) SnackBar`.
- **Problema:** `setState` se execută chiar dacă widget-ul e deja disposed.
- **Fix:** Verificare `if (mounted) { setState(...); ScaffoldMessenger... }`.

### 3. `setState` fără `mounted` (Diets)
- **Unde:** `lib/features/diets_programs/pages/diets_and_programs_page.dart` – în `catch` din `_loadData()`: `setState` fără `if (mounted)`.
- **Fix:** Înveli în `if (mounted) setState(...)`.

---

## P1 – Fluxuri / UX funcțional

### 4. Settings – ecran placeholder
- **Unde:** Drawer → Settings deschide `PlaceholderPage(title: 'Settings')`.
- **Îmbunătățire:** Fie ecran real (tema, notificări, limbă, unități), fie mesaj clar „Settings coming soon” cu scurtă descriere.

### 5. „Coming soon” fără acțiune
- **L10n:** Creator Studio, Publish tool, Saved posts, Archive, Tagged posts, Recipe creation – mesaje „coming soon”.
- **Îmbunătățire:** Unde e doar text, fie dezactivezi acțiunea și afișezi tooltip „Coming soon”, fie înlocuiești cu un ecran scurt care explică ce va veni.

### 6. Challenge progress – logică incompletă
- **Unde:** `supabase_service.dart` – pentru `PERFECT_DAY` / `PERFECT_WEEK` e comentariu „placeholder that needs manual implementation”, progress rămâne 0.
- **Îmbunătățire:** Implementare logică (ex. toate macro-urile în target în ziua respectivă) sau excludere acestor tipuri până la implementare.

### 7. Social – după Skip rămâne tab-ul Social selectat
- **Status:** Rezolvat – la Skip din setup se apelează `onSwitchToDashboard` și se revine la Dashboard. Verificat în audit anterior.

---

## P2 – Consistență și robustețe

### 8. Verificare `mounted` după async
- **Problema:** Multe pagini fac `setState` sau `ScaffoldMessenger` după `await` fără `if (mounted)`.
- **Pagini de verificat în primul rând:** Progress, Diets, Dashboard, Profile, orice pagină cu `_loadData()` async.
- **Regulă:** După fiecare `await` în metode care apelează `setState` sau folosesc `context`, verifica `if (!mounted) return;`.

### 9. Feedback la erori din servicii
- **Unde:** `SupabaseService` – multe metode prind eroarea, fac `debugPrint` și returnează `null` / listă goală sau `rethrow`.
- **Îmbunătățire:** Unde e `rethrow`, UI-ul trebuie să prindă și să afișeze SnackBar/dialog (nu doar crash). Verifică: favorite foods, custom food, upload avatar, activate diet/program, journal save/delete.

### 10. ReplicateService – `print` în loc de `debugPrint`
- **Unde:** `lib/services/replicate_service.dart` – mai multe `print('Error...')`.
- **Fix:** Înlocuire cu `debugPrint` pentru consistență și pentru a nu polua log-uri în release.

### 11. L10n – mesaj lipsă (DE)
- **Build:** Avertisment „de: 1 untranslated message(s)”.
- **Fix:** Identifică cheia lipsă în `app_de.arb` (sau din raportul l10n) și adaugă traducerea.

---

## P3 – Funcționalități lipsă / calitate

### 12. Offline / conectivitate
- **Status:** Nu există verificare de tip `Connectivity` / `hasInternet`.
- **Îmbunătățire:** La acțiuni care necesită rețea (login, sync, feed, etc.), fie verifici conectivitatea și afișezi mesaj clar („No connection”), fie lași request-ul să dea eroare și tratezi mesajul („Check your connection”).

### 13. Pull-to-refresh inconsistent
- **Are:** Feed social, Recipes, Journal history, Saved/Archived posts, Profile (achievements).
- **Lipsă:** Dashboard, Progress (Insights), Diets & Programs, Marketplace.
- **Îmbunătățire:** Acolo unde lista/datele se pot schimba (Dashboard, Progress), adaugă `RefreshIndicator` + metodă de reîncărcare.

### 14. Retry la erori de încărcare
- **Are:** Diets & Programs are buton „Retry” în starea de eroare.
- **Lipsă:** Multe alte pagini la eroare arată doar SnackBar, fără buton Retry.
- **Îmbunătățire:** Unde e logic (listă/date), la eroare afișează mesaj + buton „Retry” care reapelează `_loadData()`.

### 15. Validări input
- **Bine:** Auth (email, parolă), Setup social (username).
- **De verificat:** Câmpuri numerice (greutate, calorii țintă, macro), lungimi max (bio, nume), format dată – să nu se trimită valori invalide la backend.

---

## Rezumat priorități

| Prioritate | Acțiune |
|-----------|--------|
| **P0** | Fix setState/mounted în Progress, Dashboard, Diets |
| **P1** | Settings ecran sau mesaj clar; finalizare/placeholder challenge PERFECT_DAY/WEEK |
| **P2** | mounted peste tot după async; debugPrint în ReplicateService; l10n DE |
| **P3** | Offline message; RefreshIndicator pe Dashboard/Progress; Retry + validări |

Document creat pe baza analizei codului din `lib/` și `lib/services/`. Poți marca în BACKLOG ce e de făcut și în ce ordine.

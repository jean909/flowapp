# Audit Flutter – spațiere, flow-uri, recomandări

## Rezumat

- **Spațiere**: lipsea un sistem centralizat; existau zeci de valori ad-hoc (4, 8, 10, 12, 16, 20, 24, 32…). A fost adăugat `AppSpacing` și corectate câteva puncte critice în drawer.
- **Flow-uri**: Splash → Onboarding sau MainNav; Onboarding → Analyzing → Auth → ConfirmEmail/Dashboard; drawer + bottom nav sunt consistente.
- **Probleme remediate**: text lipsă la Logout în drawer, padding vertical prea mic la item-urile din drawer (touch target).

---

## 1. Spațiere

### 1.1 Înainte

- **Fără constantă centrală**: padding/margin setate cu numere directe în peste 50 de fișiere.
- **Valori folosite**: 2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 50, 64 etc.
- **Riscuri**: inconsistență vizuală, zone de atingeri prea mici (ex. `vertical: 4` pe ListTile).

### 1.2 Ce s-a făcut

- **`lib/core/theme/app_spacing.dart`** – scală unitară:
  - `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=20`, `xxl=24`, `xxxl=32`, `page=24`
  - `touchTarget=48` (Material)
  - Helpers: `paddingXs` … `paddingPage`, `horizontal()`, `vertical()`, `symmetric()`

### 1.3 Recomandări spațiere

| Prioritate | Acțiune |
|-----------|---------|
| P1 | La cod nou: folosește `AppSpacing` (ex. `EdgeInsets.all(AppSpacing.lg)`). |
| P2 | Refactor progresiv: pagini cu mult layout (Dashboard, Profile, Onboarding, Food detail) – înlocuire valori magice cu `AppSpacing`. |
| P2 | Liste (ListView/GridView): padding lateral uniform (ex. `AppSpacing.page` sau `AppSpacing.lg`). |
| P3 | Butoane/ListTile: înălțime minimă ~48 dp pentru touch; deja corectat în drawer. |

---

## 2. Flow-uri principale

### 2.1 Auth / onboarding

1. **Splash** (`main.dart`) – 3s delay → dacă session: `MainNavigationContainer`, altfel `OnboardingPage`.
2. **Onboarding** → pași (welcome, nickname, goal, gender, age, metrics, activity) → **AnalyzingInfoPage** → **AuthPage** (email/parolă) cu `OnboardingData`.
3. **AuthPage** – signUp cu metadata; după signUp: dacă session → Dashboard (MainNav), altfel **ConfirmEmailPage**.
4. **ConfirmEmailPage** – mesaj „Check email”, resend, back to sign in.

Flow-ul e aliniat cu website-ul (onboarding → sign up cu metadata).

### 2.2 Post-login

- **MainNavigationContainer**: 4 tab-uri (Home, Insights, ADD, Social, Recipes) + drawer.
- **Drawer**: Streaks, My Profile, Planned Workouts, Journal History, Settings (TODO), Help, Export Data, About Flow, **Logout** (acum cu text și padding corect).

### 2.3 Recomandări flow

| Prioritate | Acțiune |
|-----------|---------|
| P1 | Drawer „Settings”: fie implementează ecranul, fie ascunde/desactivează până există. |
| P2 | Exit app (back pe Android): deja există `PopScope` + dialog de confirmare – OK. |
| P2 | Deep link / notificări: stabilit rute clare (ex. `/profile`, `/notifications`) pentru viitor. |

---

## 3. Probleme rezolvate în acest audit

1. **Drawer – Logout fără text**  
   - **Înainte**: `ListTile` cu `title: SizedBox.shrink()` → doar icon roșu.  
   - **Acum**: folosire `_buildDrawerItem(Icons.logout, AppLocalizations.of(context)!.logout, …, color: Colors.redAccent)` – text „Logout”/„Deconectare” etc. + același padding ca la celelalte item-uri.

2. **Drawer – touch target**  
   - **Înainte**: `contentPadding: vertical: 4` pe toate item-urile.  
   - **Acum**: `contentPadding: vertical: 12`, `minVerticalPadding: 12` – zone de atingere mai mari și consistente.

---

## 4. Alte observații (fără modificări în acest pas)

- **SafeArea**: deja folosit la body și la bottom nav – OK.
- **Teme**: `AppColors` + `ThemeData` (Material 3, Google Fonts Outfit) – consistente.
- **L10n**: EN, RO, DE – logout și alte string-uri folosite corect acolo unde s-a atins codul.
- **Dashboard**: foarte multe `EdgeInsets` hardcodate – candidat principal la refactor cu `AppSpacing` pe viitor.

---

## 5. Fișiere modificate

### Audit inițial
| Fișier | Modificare |
|--------|------------|
| `lib/core/theme/app_spacing.dart` | **Nou** – scală spațiere + helpers. |
| `lib/core/widgets/main_navigation.dart` | Drawer: Logout cu text l10n; `contentPadding` și `minVerticalPadding` mărite pentru toate item-urile. |
| `docs/FLUTTER_AUDIT.md` | **Nou** – acest document. |

### Continuare refactor (AppSpacing)
| Fișier | Modificare |
|--------|------------|
| `lib/features/onboarding/pages/onboarding_page.dart` | Padding/SizedBox → AppSpacing (page, lg, xxxl, md, touchTarget). |
| `lib/features/onboarding/pages/auth_page.dart` | paddingPage, symmetric(page/sm), SizedBox(xxxl, lg, xxl). |
| `lib/features/onboarding/pages/confirm_email_page.dart` | Padding și SizedBox → AppSpacing. |
| `lib/features/onboarding/pages/forgot_password_page.dart` | paddingPage, padding xxxl. |
| `lib/features/profile/pages/profile_page.dart` | paddingPage, paddingXs/Lg, SizedBox (xxl, xxxl, lg, md, xl), width md. |
| `lib/core/widgets/flow_widgets.dart` | FlowButton: height touchTarget+8, borderRadius lg; SelectionCard: paddingXl/Md, borderRadius xl/md, SizedBox xl/xs. |
| `lib/core/widgets/main_navigation.dart` | contentPadding/minVerticalPadding cu AppSpacing; Settings → PlaceholderPage('Settings'). |
| `lib/features/dashboard/pages/dashboard_page.dart` | Water sheet: paddingPage, SizedBox xxl/sm, paddingLg, borderRadius md. |
| `lib/features/dashboard/pages/add_options_modal.dart` | Padding-uri → AppSpacing (page, lg, sm, xxxl), SizedBox sm. |

---

## 6. Pași următori sugerați

1. În cod nou: import `app_spacing.dart` și folosește `AppSpacing.*`.
2. La refactor: înlocuie valorile magice pe Dashboard, Profile, Onboarding, Food detail, Recipes.
3. Drawer Settings: implementare ecran sau eliminare/disable din meniu până e gata.
4. (Opțional) Extindere temă: expune `AppSpacing` prin `ThemeData` (ex. `ThemeExtension`) pentru acces din orice widget.

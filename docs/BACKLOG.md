# Backlog

Priorități consolidate: UX rămas, optimizări, îmbunătățiri.

**Audit funcționalități (Flutter):** [docs/FLUTTER_FUNCTIONALITY_AUDIT.md](FLUTTER_FUNCTIONALITY_AUDIT.md) – bug-uri setState/mounted, Settings placeholder, challenge PERFECT_DAY/WEEK, consistență erori/retry/offline, l10n.

**Făcut recent:** Email confirm → dezactivare cont după X zile (SQL + Flutter AccountDeactivatedPage); validare email/parolă la register; Social setup: Back + Skip + l10n; print → debugPrint în SupabaseService; AccountDeactivatedPage l10n + AppSpacing. **Curățare:** Dashboard: print → debugPrint; Diets: șters _buildNutrientChip nefolosit; Marketplace: errorBuilder pe panda asset.

---

## UX (rămas din audit)

- **P1:** Layout comun dashboard – `app/dashboard/layout.tsx` cu Sidebar + auth; LoadingSpinner comun.
- **P2:** `loading.tsx` / `error.tsx` pe rute; validare profil + mesaje eroare; aria-labels/landmarks/aria-live; Escape pentru meniuri.

*(P0 făcut: Navbar pe search/product, Navbar session-aware, toast-uri, feedback profil.)*

---

## Optimizări (top)

**Înalt:** Debounce search (300ms); cache profil/date frecvente; skeleton loaders; error handling mai clar; batch queries pe dashboard.

**Mediu:** Pagination liste mari; optimizare imagini (lazy load, WebP); state management; offline support.

---

## Îmbunătățiri produs (top 5)

1. Meal planning & weekly prep (plan zilnic, listă cumpărături).
2. Recipe database & meal builder (rețete user, sharing).
3. Advanced nutrition analytics (tendințe, alerte deficiențe).
4. Smart notifications (remeinderi meal/hydration, milestone-uri).
5. Dark mode & personalizare temă.

---

*Liste complete au fost consolidate aici; detaliile erau în OPTIMIZATIONS_LIST.md și app_improvements_list.md (șterse).

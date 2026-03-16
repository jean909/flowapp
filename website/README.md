# Flow Website

Modern landing page for the Flow wellness app, built with Next.js and Tailwind CSS.

## Features

- 🎨 **Consistent Branding** - Uses the same colors, logo, and design language as the mobile app
- 🗄️ **Shared Database** - Connected to the same Supabase instance as the mobile app
- 📱 **Responsive Design** - Works perfectly on all devices
- ⚡ **Fast Performance** - Built with Next.js 16 for optimal speed
- 🎯 **SEO Optimized** - Proper metadata and structure

## Tech Stack

- **Next.js 16** - React framework
- **TypeScript** - Type safety
- **Tailwind CSS 4** - Styling
- **Supabase** - Backend (shared with mobile app)

## Getting Started

1. Install dependencies:
```bash
npm install
```

2. Run the development server:
```bash
npm run dev
```

3. Open [http://localhost:3000](http://localhost:3000) in your browser

## E2E Tests (Playwright)

```bash
npm run test:e2e
```

Pornește serverul automat (sau set `PLAYWRIGHT_BASE_URL=http://localhost:3001` dacă rulezi deja `npm run dev`). Teste: home nav, search + rezultate, pagină produs, login tabs, redirect dashboard → login fără auth.

## Build for Production

```bash
npm run build
npm start
```

## Auth: fără confirmare email (opțional)

Ca utilizatorii noi să intre direct în app după „Create account”, dezactivează confirmarea email în Supabase:

1. Supabase Dashboard → **Authentication** → **Providers** → **Email**
2. Dezactivează **„Confirm email”**
3. Salvează

După asta, la sign up utilizatorul primește sesiune direct și e redirecționat la dashboard. Dacă lași confirmarea activă, după sign up vedem ecranul „Check your email” cu opțiune de resend și „Back to sign in”.

## Environment Variables

The Supabase configuration is already set up, but you can override it with environment variables:

- `NEXT_PUBLIC_SUPABASE_URL` - Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Your Supabase anon key

## Lansare site – pași (deploy)

Site-ul este **în interiorul proiectului** (`flow_app/website`) și folosește **același backend Supabase** ca aplicația mobilă. Iată cum îl lansezi pe Vercel.

### Variantă recomandată: Vercel (gratuit, optim pentru Next.js)

1. **Cont Vercel**  
   - Mergi pe [vercel.com](https://vercel.com) și fă sign up (cu GitHub e cel mai simplu).

2. **Repo pe GitHub**  
   - Încarcă **tot proiectul** (inclusiv `flow_app/` cu Flutter + `website/`). Nu e nevoie să separi site-ul într-un repo separat.  
   - Exemplu structură: repo `Flow` → în el există `flow_app/` → în `flow_app/` există `website/` (Next.js) + restul app-ului Flutter.

3. **Import proiect în Vercel**  
   - Vercel Dashboard → **Add New** → **Project**.  
   - Conectează GitHub și alege repo-ul (ex. `Flow`) + branch-ul (ex. `main`).  
   - **Important – Root Directory**: site-ul nu e în rădăcina repo-ului, ci într-un subfolder.  
     - Click pe **Edit** lângă "Root Directory".  
     - Setează **`flow_app/website`** (dacă în repo rădăcina e proiectul care conține folderul `flow_app`).  
     - Sau doar **`website`** dacă în GitHub ai pushat doar conținutul din `flow_app` (deci rădăcina repo-ului e de fapt `flow_app`).  
   - Framework: **Next.js** (detectat automat).  
   - Build Command: lasă **`npm run build`** (rulează în Root Directory).  
   - Output Directory: lasă implicit (Next.js știe să folosească `.next`).

4. **Backend comun (Supabase)**  
   - Site-ul folosește același Supabase ca aplicația. În proiectul Vercel: **Settings** → **Environment Variables**.  
   - Adaugă aceleași valori ca în app:
     - `NEXT_PUBLIC_SUPABASE_URL` = URL-ul proiectului Supabase (ex. `https://xxx.supabase.co`)  
     - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = cheia anon/public din Supabase Dashboard  
   - Salvează. La primul deploy sau după ce adaugi variabile: **Deployments** → **Redeploy** ca să se aplice.

5. **Deploy**  
   - Click **Deploy**. Build-ul rulează din `flow_app/website` (sau `website`), deci `npm install` și `npm run build` sunt rulate acolo.  
   - După succes, primești un URL de tip `https://nume-proiect.vercel.app`.  
   - Domeniu propriu: **Settings** → **Domains**.

6. **Deploy-uri ulterioare**  
   - La fiecare push pe branch-ul conectat, Vercel face deploy automat (doar pentru acel repo; build-ul rulează doar din Root Directory setat).  
   - Sau: **Deployments** → **Redeploy** pentru ultima versiune.

**Rezumat:** Repo = tot proiectul; în Vercel setezi **Root Directory** la folderul unde e site-ul (`flow_app/website` sau `website`); backend-ul comun = aceleași variabile Supabase ca în app.

### Alte variante

- **Netlify**: drag & drop folderul din `npm run build` (output-ul e în `.next`) sau conectare la Git; pentru Next.js folosește plugin-ul Netlify pentru Next.  
- **VPS / Node**: rulezi `npm run build` și apoi `npm start`; expui portul 3000 cu nginx sau reverse proxy și (opțional) PM2.

## Brand Colors

- Primary: `#2ECC71` (Emerald Green)
- Secondary: `#27AE60` (Nephrite Green)
- Accent: `#F1C40F` (Sun Flower Yellow)
- Background: `#FAFAFA`
- Text Primary: `#2C3E50`
- Text Secondary: `#7F8C8D`

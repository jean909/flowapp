'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { motion, AnimatePresence } from 'framer-motion';
import { ONBOARDING_STORAGE_KEY, type OnboardingData } from '@/lib/onboarding';

const TOTAL_STEPS = 9;
const GOALS = [
  { id: 'LOSE', label: 'Lose weight', desc: 'Calorie deficit for fat loss' },
  { id: 'MAINTAIN', label: 'Maintain health', desc: 'Balance your nutrition' },
  { id: 'GAIN', label: 'Gain muscle', desc: 'Calorie surplus for building' },
];
const GENDERS = [
  { id: 'MALE', label: 'Male' },
  { id: 'FEMALE', label: 'Female' },
];
const ACTIVITIES = [
  { id: 'SEDENTARY', label: 'Sedentary', desc: 'Little or no exercise' },
  { id: 'LIGHTLY ACTIVE', label: 'Lightly active', desc: 'Light exercise 1–3 days/week' },
  { id: 'MODERATELY ACTIVE', label: 'Moderately active', desc: 'Moderate exercise 3–5 days/week' },
  { id: 'VERY ACTIVE', label: 'Very active', desc: 'Hard exercise 6–7 days/week' },
];

export default function OnboardingPage() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [analyzing, setAnalyzing] = useState(false);
  const [data, setData] = useState<OnboardingData>({});

  const canNext = () => {
    if (step === 1) return (data.full_name ?? '').trim().length > 0;
    if (step === 2) return !!data.goal;
    if (step === 3) return !!data.gender;
    if (step === 4) return data.age != null && data.age >= 10 && data.age <= 120;
    if (step === 5) return data.height != null && data.height > 0 && data.current_weight != null && data.current_weight > 0;
    if (step === 6) return true;
    if (step === 7) return !!data.activity_level;
    return true;
  };

  const next = () => {
    if (step < TOTAL_STEPS - 1) setStep((s) => s + 1);
    else finish();
  };

  const finish = () => {
    setAnalyzing(true);
    setTimeout(() => {
      if (typeof window !== 'undefined') {
        sessionStorage.setItem(ONBOARDING_STORAGE_KEY, JSON.stringify(data));
      }
      router.push('/login?from=onboarding');
    }, 2500);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/10 via-background to-accent/10 flex flex-col items-center px-5 py-8 sm:py-12">
      <Link href="/" className="flex items-center gap-2 mb-6 self-start">
        <Image src="/logo.png" alt="Flow" width={36} height={36} className="rounded-lg" />
        <span className="font-bold text-primary">FLOW</span>
      </Link>

      {analyzing ? (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="flex-1 flex flex-col items-center justify-center max-w-md w-full"
        >
          <div className="w-24 h-24 rounded-full border-4 border-primary border-t-transparent animate-spin mb-8" />
          <h2 className="text-xl font-bold text-text-primary mb-2">Analyzing your info</h2>
          <p className="text-text-secondary text-sm text-center">Setting up your profile...</p>
        </motion.div>
      ) : (
        <>
          <div className="w-full max-w-md mb-6">
            <div className="flex gap-1">
              {Array.from({ length: TOTAL_STEPS }).map((_, i) => (
                <div
                  key={i}
                  className="h-1 flex-1 rounded-full bg-gray-200"
                  style={{ backgroundColor: i <= step ? 'var(--primary)' : undefined }}
                />
              ))}
            </div>
          </div>

          <div className="w-full max-w-md flex-1 flex flex-col">
            <AnimatePresence mode="wait">
              {step === 0 && (
                <motion.div
                  key="welcome"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  className="text-center py-8"
                >
                  <h1 className="text-2xl sm:text-3xl font-bold text-text-primary mb-3">Welcome to Flow</h1>
                  <p className="text-text-secondary mb-8">A few quick questions so we can personalize your experience, just like in the app.</p>
                </motion.div>
              )}

              {step === 1 && (
                <Step key="nickname" title="What should we call you?" subtitle="A nickname or first name is fine.">
                  <input
                    type="text"
                    value={data.full_name ?? ''}
                    onChange={(e) => setData((d) => ({ ...d, full_name: e.target.value }))}
                    placeholder="Your name"
                    className="w-full min-h-[52px] px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-center text-xl font-semibold text-text-primary"
                  />
                </Step>
              )}

              {step === 2 && (
                <Step key="goal" title="What's your goal?" subtitle="We'll adjust your targets accordingly.">
                  <div className="space-y-3">
                    {GOALS.map((g) => (
                      <button
                        key={g.id}
                        type="button"
                        onClick={() => setData((d) => ({ ...d, goal: g.id }))}
                        className={`w-full p-4 rounded-xl border-2 text-left transition-all ${
                          data.goal === g.id ? 'border-primary bg-primary/10' : 'border-gray-200 hover:border-primary/50'
                        }`}
                      >
                        <span className="font-semibold text-text-primary block">{g.label}</span>
                        <span className="text-sm text-text-secondary">{g.desc}</span>
                      </button>
                    ))}
                  </div>
                </Step>
              )}

              {step === 3 && (
                <Step key="gender" title="Gender" subtitle="Used for calorie and water calculations.">
                  <div className="grid grid-cols-2 gap-4">
                    {GENDERS.map((g) => (
                      <button
                        key={g.id}
                        type="button"
                        onClick={() => setData((d) => ({ ...d, gender: g.id }))}
                        className={`p-6 rounded-xl border-2 font-semibold transition-all ${
                          data.gender === g.id ? 'border-primary bg-primary/10 text-primary' : 'border-gray-200 text-text-primary'
                        }`}
                      >
                        {g.label}
                      </button>
                    ))}
                  </div>
                </Step>
              )}

              {step === 4 && (
                <Step key="age" title="Your age" subtitle="Years.">
                  <input
                    type="number"
                    min={10}
                    max={120}
                    value={data.age ?? ''}
                    onChange={(e) => setData((d) => ({ ...d, age: parseInt(e.target.value, 10) || undefined }))}
                    placeholder="25"
                    className="w-full min-h-[52px] px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-center text-2xl font-bold text-text-primary"
                  />
                </Step>
              )}

              {step === 5 && (
                <Step key="metrics" title="Height & current weight" subtitle="In cm and kg.">
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm text-text-secondary mb-1">Height (cm)</label>
                      <input
                        type="number"
                        min={100}
                        max={250}
                        value={data.height ?? ''}
                        onChange={(e) => setData((d) => ({ ...d, height: parseFloat(e.target.value) || undefined }))}
                        placeholder="170"
                        className="w-full min-h-[48px] px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-primary outline-none text-text-primary"
                      />
                    </div>
                    <div>
                      <label className="block text-sm text-text-secondary mb-1">Current weight (kg)</label>
                      <input
                        type="number"
                        min={30}
                        max={300}
                        step={0.1}
                        value={data.current_weight ?? ''}
                        onChange={(e) => setData((d) => ({ ...d, current_weight: parseFloat(e.target.value) || undefined }))}
                        placeholder="70"
                        className="w-full min-h-[48px] px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-primary outline-none text-text-primary"
                      />
                    </div>
                  </div>
                </Step>
              )}

              {step === 6 && (
                <Step key="target" title="Target weight (optional)" subtitle="Leave empty to skip.">
                  <input
                    type="number"
                    min={30}
                    max={300}
                    step={0.1}
                    value={data.target_weight ?? ''}
                    onChange={(e) => setData((d) => ({ ...d, target_weight: parseFloat(e.target.value) || undefined }))}
                    placeholder="e.g. 65"
                    className="w-full min-h-[52px] px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-center text-text-primary"
                  />
                </Step>
              )}

              {step === 7 && (
                <Step key="activity" title="Activity level" subtitle="How active are you?">
                  <div className="space-y-3">
                    {ACTIVITIES.map((a) => (
                      <button
                        key={a.id}
                        type="button"
                        onClick={() => setData((d) => ({ ...d, activity_level: a.id }))}
                        className={`w-full p-4 rounded-xl border-2 text-left transition-all ${
                          data.activity_level === a.id ? 'border-primary bg-primary/10' : 'border-gray-200 hover:border-primary/50'
                        }`}
                      >
                        <span className="font-semibold text-text-primary block">{a.label}</span>
                        <span className="text-sm text-text-secondary">{a.desc}</span>
                      </button>
                    ))}
                  </div>
                </Step>
              )}

              {step === 8 && (
                <motion.div
                  key="review"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  className="py-4"
                >
                  <h2 className="text-xl font-bold text-text-primary mb-2">You&apos;re all set</h2>
                  <p className="text-text-secondary text-sm mb-6">Next you&apos;ll create your account with email and password. Your profile will be set up automatically.</p>
                </motion.div>
              )}
            </AnimatePresence>

            <div className="mt-8 flex gap-3">
              {step > 0 && !analyzing && (
                <button
                  type="button"
                  onClick={() => setStep((s) => s - 1)}
                  className="px-5 py-3 rounded-xl border-2 border-gray-200 text-text-primary font-semibold"
                >
                  Back
                </button>
              )}
              <button
                type="button"
                onClick={next}
                disabled={!canNext()}
                className="flex-1 min-h-[48px] px-5 py-3 rounded-xl gradient-primary text-white font-semibold disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {step === 0 ? 'Get started' : step === TOTAL_STEPS - 1 ? 'Continue to account' : 'Continue'}
              </button>
            </div>
          </div>
        </>
      )}

      <p className="mt-8 text-center text-sm text-text-secondary">
        Already have an account? <Link href="/login" className="text-primary font-medium">Sign in</Link>
      </p>
    </div>
  );
}

function Step({
  key: _k,
  title,
  subtitle,
  children,
}: {
  key: string;
  title: string;
  subtitle: string;
  children: React.ReactNode;
}) {
  return (
    <motion.div
      key={_k}
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="py-4"
    >
      <h2 className="text-xl font-bold text-text-primary mb-1">{title}</h2>
      <p className="text-text-secondary text-sm mb-6">{subtitle}</p>
      {children}
    </motion.div>
  );
}


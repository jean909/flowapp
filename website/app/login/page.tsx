'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';
import { motion } from 'framer-motion';
import Image from 'next/image';
import Link from 'next/link';
import { useToast } from '@/components/Toast';
import { getOnboardingFromStorage, clearOnboardingStorage, onboardingToUserMetadata, type OnboardingData } from '@/lib/onboarding';

export default function LoginPage() {
  const toast = useToast();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isResending, setIsResending] = useState(false);
  const [error, setError] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [signUpEmailSent, setSignUpEmailSent] = useState<string | null>(null);
  const [onboardingData, setOnboardingData] = useState<OnboardingData | null>(null);

  useEffect(() => {
    const from = searchParams.get('from');
    const stored = getOnboardingFromStorage();
    if (from === 'onboarding' && stored) {
      setOnboardingData(stored);
      setIsSignUp(true);
    }
  }, [searchParams]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');
    setSignUpEmailSent(null);

    try {
      if (isSignUp) {
        const metadata = onboardingData ? onboardingToUserMetadata(onboardingData) : undefined;
        const { data, error: signUpError } = await supabase.auth.signUp({
          email,
          password,
          options: {
            emailRedirectTo: typeof window !== 'undefined' ? `${window.location.origin}/dashboard` : undefined,
            data: metadata,
          },
        });
        if (signUpError) throw signUpError;
        if (onboardingData) clearOnboardingStorage();
        if (data.session) {
          toast.success('Account created. Welcome!');
          router.push('/dashboard');
          return;
        }
        setSignUpEmailSent(email);
        toast.success('Check your email for the confirmation link.');
      } else {
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        if (signInError) throw signInError;
        router.push('/dashboard');
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'An error occurred';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleResendConfirmation = async () => {
    if (!signUpEmailSent) return;
    setIsResending(true);
    setError('');
    try {
      const { error: resendError } = await supabase.auth.resend({
        type: 'signup',
        email: signUpEmailSent,
      });
      if (resendError) throw resendError;
      toast.success('Confirmation email sent again. Check your inbox.');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to resend.');
    } finally {
      setIsResending(false);
    }
  };

  const switchToSignIn = () => {
    setIsSignUp(false);
    setSignUpEmailSent(null);
    setError('');
  };

  if (signUpEmailSent) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary/10 via-background to-accent/10 flex items-center justify-center px-5 py-16 sm:py-20">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-[400px] w-full bg-surface rounded-2xl shadow-2xl p-8 sm:p-10 border border-gray-100 text-center"
        >
          <div className="mb-8">
            <div className="w-14 h-14 rounded-full bg-primary/15 flex items-center justify-center mx-auto mb-5">
              <svg className="w-7 h-7 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden>
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
            <h1 className="text-xl font-bold text-text-primary mb-2">Check your email</h1>
            <p className="text-text-secondary text-sm leading-relaxed">
              We sent a confirmation link to <strong className="text-text-primary">{signUpEmailSent}</strong>. Click it to activate your account.
            </p>
            <p className="text-text-secondary text-sm mt-3">Check spam if you don&apos;t see it.</p>
          </div>
          {error && (
            <p className="text-error text-sm mb-5">{error}</p>
          )}
          <div className="flex flex-col gap-3">
            <button
              type="button"
              onClick={handleResendConfirmation}
              disabled={isResending}
              className="min-h-[48px] w-full px-5 py-3 border-2 border-primary/30 text-primary rounded-xl font-semibold hover:bg-primary/5 disabled:opacity-50 text-sm transition-colors"
            >
              {isResending ? 'Sending...' : 'Resend confirmation email'}
            </button>
            <button
              type="button"
              onClick={switchToSignIn}
              className="min-h-[48px] w-full px-5 py-3 text-text-secondary hover:text-primary font-medium text-sm transition-colors rounded-xl"
            >
              Back to sign in
            </button>
          </div>
          <Link href="/" className="inline-block mt-8 text-text-secondary hover:text-primary text-sm transition-colors">
            ← Back to home
          </Link>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/10 via-background to-accent/10 flex items-center justify-center px-5 py-16 sm:py-20">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="max-w-[400px] w-full bg-surface rounded-2xl shadow-2xl p-6 sm:p-8 border border-gray-100"
      >
        <div className="text-center mb-8">
          <Link href="/" className="inline-block mb-5 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:ring-offset-2 rounded-xl">
            <Image
              src="/logo.png"
              alt="Flow Logo"
              width={56}
              height={56}
              className="rounded-xl mx-auto"
            />
          </Link>
          <div className="flex rounded-xl bg-gray-100 p-1.5 mb-6">
            <button
              type="button"
              onClick={() => { setIsSignUp(false); setError(''); }}
              className={`flex-1 min-h-[44px] py-2.5 rounded-lg text-sm font-semibold transition-all ${!isSignUp ? 'bg-surface text-primary shadow-sm' : 'text-text-secondary hover:text-text-primary'}`}
            >
              Sign in
            </button>
            <button
              type="button"
              onClick={() => { setIsSignUp(true); setError(''); }}
              className={`flex-1 min-h-[44px] py-2.5 rounded-lg text-sm font-semibold transition-all ${isSignUp ? 'bg-surface text-primary shadow-sm' : 'text-text-secondary hover:text-text-primary'}`}
            >
              Create account
            </button>
          </div>
          <h1 className="text-2xl font-bold text-text-primary mb-2">
            {isSignUp ? 'Create account' : 'Welcome back'}
          </h1>
          <p className="text-text-secondary text-sm leading-relaxed">
            {isSignUp
              ? (onboardingData
                  ? 'Complete with your email and password. Your profile is ready from onboarding.'
                  : 'Enter your email and a password (min 6 characters)')
              : 'Sign in to access your dashboard'}
          </p>
          {isSignUp && !onboardingData && (
            <p className="mt-2 text-sm">
              <Link href="/onboarding" className="text-primary font-medium hover:underline">
                Complete onboarding first (like the app) →
              </Link>
            </p>
          )}
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="bg-error/10 border border-error/20 text-error rounded-xl px-4 py-3 text-sm"
            >
              {error}
            </motion.div>
          )}

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-text-primary mb-2">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              className="w-full min-h-[48px] px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all text-text-primary placeholder:text-text-secondary/70"
              placeholder="you@example.com"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-text-primary mb-2">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={6}
              autoComplete={isSignUp ? 'new-password' : 'current-password'}
              className="w-full min-h-[48px] px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all text-text-primary placeholder:text-text-secondary/70"
              placeholder="••••••••"
            />
            {isSignUp && (
              <p className="mt-1.5 text-xs text-text-secondary">At least 6 characters</p>
            )}
          </div>

          <motion.button
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
            type="submit"
            disabled={isLoading}
            className="w-full min-h-[48px] px-6 py-3.5 gradient-primary text-white rounded-xl font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed shadow-lg"
          >
            {isLoading ? 'Please wait...' : isSignUp ? 'Create account' : 'Sign in'}
          </motion.button>
        </form>

        <div className="mt-8 text-center">
          <button
            type="button"
            onClick={() => { setIsSignUp(!isSignUp); setError(''); }}
            className="min-h-[44px] px-3 py-2 text-primary hover:underline text-sm font-medium rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/20"
          >
            {isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Create one"}
          </button>
        </div>

        <div className="mt-4 text-center">
          <Link href="/" className="inline-block py-2 text-text-secondary hover:text-primary text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-primary/20 focus:ring-offset-2 rounded-lg">
            ← Back to home
          </Link>
        </div>
      </motion.div>
    </div>
  );
}


'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';
import { motion } from 'framer-motion';
import Sidebar from '@/components/Sidebar';
import { useToast } from '@/components/Toast';

interface SubscriptionPlan {
  id: string;
  name: string;
  description: string;
  monthly_coin_cost: number;
  perks: string[];
  color_hex: string;
}

interface Profile {
  full_name?: string;
  avatar_url?: string;
  coins?: number;
  plan_type?: string;
}

export default function PlansPage() {
  const router = useRouter();
  const toast = useToast();
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      router.push('/login');
      return;
    }
    loadData();
  };

  const loadData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Load profile
      const { data: profileData } = await supabase
        .from('profiles')
        .select('full_name, avatar_url, coins, plan_type')
        .eq('id', user.id)
        .single();

      if (profileData) {
        setProfile(profileData);
      }

      // Load subscription plans
      const { data: plansData, error } = await supabase
        .from('subscription_plans')
        .select('*')
        .order('monthly_coin_cost', { ascending: true });

      if (error) throw error;
      setPlans(plansData || []);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpgrade = async (planId: string, coinCost: number) => {
    if (!profile) return;

    if (profile.coins != null && profile.coins < coinCost) {
      toast.error('Not enough coins. Please purchase more coins first.');
      return;
    }

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      await supabase
        .from('profiles')
        .update({ plan_type: planId })
        .eq('id', user.id);

      if (coinCost > 0 && profile.coins != null) {
        await supabase
          .from('profiles')
          .update({ coins: profile.coins - coinCost })
          .eq('id', user.id);
      }

      toast.success(`Upgraded to ${planId} plan.`);
      loadData();
    } catch (error) {
      console.error('Error upgrading plan:', error);
      toast.error('Error upgrading plan. Please try again.');
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/');
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 flex">
      <Sidebar profile={profile} onLogout={handleLogout} />
      
      <div className="flex-1 lg:ml-64 pt-12 pb-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-8"
          >
            <h1 className="text-4xl font-bold text-text-primary mb-2">Subscription Plans</h1>
            <p className="text-xl text-text-secondary">Choose the plan that fits your wellness journey</p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-6">
            {plans.map((plan, index) => {
              const isCurrentPlan = profile?.plan_type === plan.id;
              const canUpgrade = !isCurrentPlan && (plan.monthly_coin_cost === 0 || (profile?.coins || 0) >= plan.monthly_coin_cost);

              return (
                <motion.div
                  key={plan.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  whileHover={{ scale: 1.05, y: -5 }}
                  className={`relative bg-surface rounded-3xl shadow-xl border-2 overflow-hidden ${
                    isCurrentPlan ? 'border-primary' : 'border-gray-200'
                  }`}
                >
                  {isCurrentPlan && (
                    <div className="absolute top-4 right-4 px-3 py-1 bg-primary text-white rounded-full text-sm font-semibold">
                      Current Plan
                    </div>
                  )}

                  <div
                    className="h-2"
                    style={{ background: plan.color_hex }}
                  ></div>

                  <div className="p-8">
                    <h3 className="text-2xl font-bold text-text-primary mb-2">{plan.name}</h3>
                    <p className="text-text-secondary mb-6">{plan.description}</p>

                    <div className="mb-6">
                      <div className="flex items-baseline gap-2">
                        <span className="text-4xl font-bold text-text-primary">
                          {plan.monthly_coin_cost === 0 ? 'Free' : `${plan.monthly_coin_cost}`}
                        </span>
                        {plan.monthly_coin_cost > 0 && (
                          <span className="text-text-secondary">coins/month</span>
                        )}
                      </div>
                    </div>

                    <ul className="space-y-3 mb-8">
                      {plan.perks.map((perk, perkIndex) => (
                        <li key={perkIndex} className="flex items-start gap-2">
                          <svg className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </svg>
                          <span className="text-text-secondary">{perk}</span>
                        </li>
                      ))}
                    </ul>

                    <motion.button
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => handleUpgrade(plan.id, plan.monthly_coin_cost)}
                      disabled={!canUpgrade}
                      className={`w-full py-3 rounded-xl font-semibold transition-all ${
                        isCurrentPlan
                          ? 'bg-gray-200 text-gray-500 cursor-not-allowed'
                          : canUpgrade
                          ? 'gradient-primary text-white shadow-lg hover:shadow-xl'
                          : 'bg-gray-200 text-gray-500 cursor-not-allowed'
                      }`}
                    >
                      {isCurrentPlan
                        ? 'Current Plan'
                        : canUpgrade
                        ? 'Upgrade Now'
                        : 'Not Enough Coins'}
                    </motion.button>
                  </div>
                </motion.div>
              );
            })}
          </div>

          {/* Coins Info */}
          {profile && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="mt-8 bg-surface p-6 rounded-2xl shadow-xl border border-gray-100"
            >
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-xl font-bold text-text-primary mb-2">Your Coins</h3>
                  <p className="text-text-secondary">Purchase coins to unlock premium features</p>
                </div>
                <div className="flex items-center gap-3 px-6 py-3 bg-accent/10 rounded-xl border border-accent/20">
                  <span className="text-3xl">🪙</span>
                  <div>
                    <p className="text-2xl font-bold text-text-primary">{profile.coins || 0}</p>
                    <p className="text-sm text-text-secondary">coins available</p>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </div>
      </div>
    </div>
  );
}


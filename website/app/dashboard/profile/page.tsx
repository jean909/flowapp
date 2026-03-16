'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';
import { motion } from 'framer-motion';
import Image from 'next/image';
import Sidebar from '@/components/Sidebar';
import { useToast } from '@/components/Toast';

interface Profile {
  full_name?: string;
  email?: string;
  current_weight?: number;
  target_weight?: number;
  height?: number;
  age?: number;
  gender?: string;
  goal?: string;
  activity_level?: string;
  daily_calorie_target?: number;
  daily_water_target?: number;
  avatar_url?: string;
  coins?: number;
  plan_type?: string;
}

export default function ProfilePage() {
  const router = useRouter();
  const toast = useToast();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [formData, setFormData] = useState({
    full_name: '',
    current_weight: '',
    target_weight: '',
    height: '',
    age: '',
    goal: 'MAINTAIN',
    activity_level: 'SEDENTARY',
    daily_calorie_target: '',
    daily_water_target: '',
  });

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      router.push('/login');
      return;
    }
    loadProfile();
  };

  const loadProfile = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: profileData } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (profileData) {
        setProfile(profileData);
        setFormData({
          full_name: profileData.full_name || '',
          current_weight: profileData.current_weight?.toString() || '',
          target_weight: profileData.target_weight?.toString() || '',
          height: profileData.height?.toString() || '',
          age: profileData.age?.toString() || '',
          goal: profileData.goal || 'MAINTAIN',
          activity_level: profileData.activity_level || 'SEDENTARY',
          daily_calorie_target: profileData.daily_calorie_target?.toString() || '',
          daily_water_target: profileData.daily_water_target?.toString() || '2000',
        });
      }
    } catch (error) {
      console.error('Error loading profile:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    setIsSaving(true);
    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          full_name: formData.full_name,
          current_weight: formData.current_weight ? parseFloat(formData.current_weight) : null,
          target_weight: formData.target_weight ? parseFloat(formData.target_weight) : null,
          height: formData.height ? parseFloat(formData.height) : null,
          age: formData.age ? parseInt(formData.age) : null,
          goal: formData.goal,
          activity_level: formData.activity_level,
          daily_calorie_target: formData.daily_calorie_target ? parseInt(formData.daily_calorie_target) : null,
          daily_water_target: formData.daily_water_target ? parseInt(formData.daily_water_target) : null,
        })
        .eq('id', user.id);

      if (error) throw error;
      setIsEditing(false);
      await loadProfile();
      toast.success('Profile updated.');
    } catch (error) {
      console.error('Error saving profile:', error);
      toast.error('Failed to save profile. Please try again.');
    } finally {
      setIsSaving(false);
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

  const profileData = profile ? {
    full_name: profile.full_name,
    avatar_url: profile.avatar_url,
    coins: profile.coins || 0,
    plan_type: profile.plan_type || 'free',
  } : null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 flex">
      <Sidebar profile={profileData} onLogout={handleLogout} />
      
      <div className="flex-1 lg:ml-64 pt-12 pb-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-8"
          >
            <h1 className="text-4xl font-bold text-text-primary mb-2">Profile Settings</h1>
            <p className="text-xl text-text-secondary">Manage your personal information and goals</p>
          </motion.div>

          {/* Profile Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-surface rounded-3xl shadow-2xl border border-gray-100 overflow-hidden mb-8"
          >
            {/* Header with Avatar */}
            <div className="gradient-primary p-8 text-white relative overflow-hidden">
              <div className="absolute top-0 right-0 w-96 h-96 bg-white/10 rounded-full blur-3xl -mr-48 -mt-48"></div>
              <div className="relative z-10 flex items-center gap-6">
                <div className="relative">
                  {profile?.avatar_url ? (
                    <Image
                      src={profile.avatar_url}
                      alt="Profile"
                      width={100}
                      height={100}
                      className="rounded-full border-4 border-white shadow-xl"
                      unoptimized
                    />
                  ) : (
                    <div className="w-25 h-25 rounded-full bg-white/20 backdrop-blur-sm border-4 border-white flex items-center justify-center text-white text-4xl font-bold shadow-xl">
                      {profile?.full_name?.[0] || 'U'}
                    </div>
                  )}
                </div>
                <div className="flex-1">
                  <h2 className="text-3xl font-bold mb-2">{profile?.full_name || 'User'}</h2>
                  <p className="text-white/80">{profile?.email}</p>
                  <div className="flex items-center gap-4 mt-3">
                    <span className="px-4 py-1 bg-white/20 rounded-full text-sm backdrop-blur-sm">
                      {profile?.plan_type || 'free'} plan
                    </span>
                    {profile?.coins !== undefined && (
                      <span className="px-4 py-1 bg-white/20 rounded-full text-sm backdrop-blur-sm flex items-center gap-2">
                        🪙 {profile.coins} coins
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* Form */}
            <div className="p-8">
              {isEditing ? (
                <div className="space-y-6">
                  <div className="grid md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Full Name</label>
                      <input
                        type="text"
                        value={formData.full_name}
                        onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Age</label>
                      <input
                        type="number"
                        value={formData.age}
                        onChange={(e) => setFormData({ ...formData, age: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Current Weight (kg)</label>
                      <input
                        type="number"
                        step="0.1"
                        value={formData.current_weight}
                        onChange={(e) => setFormData({ ...formData, current_weight: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Target Weight (kg)</label>
                      <input
                        type="number"
                        step="0.1"
                        value={formData.target_weight}
                        onChange={(e) => setFormData({ ...formData, target_weight: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Height (cm)</label>
                      <input
                        type="number"
                        value={formData.height}
                        onChange={(e) => setFormData({ ...formData, height: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Goal</label>
                      <select
                        value={formData.goal}
                        onChange={(e) => setFormData({ ...formData, goal: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      >
                        <option value="LOSE">Lose Weight</option>
                        <option value="MAINTAIN">Maintain Weight</option>
                        <option value="GAIN">Gain Weight</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Activity Level</label>
                      <select
                        value={formData.activity_level}
                        onChange={(e) => setFormData({ ...formData, activity_level: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      >
                        <option value="SEDENTARY">Sedentary</option>
                        <option value="LIGHTLY_ACTIVE">Lightly Active</option>
                        <option value="MODERATELY_ACTIVE">Moderately Active</option>
                        <option value="VERY_ACTIVE">Very Active</option>
                        <option value="EXTRA_ACTIVE">Extra Active</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Daily Calorie Target</label>
                      <input
                        type="number"
                        value={formData.daily_calorie_target}
                        onChange={(e) => setFormData({ ...formData, daily_calorie_target: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-text-primary mb-2">Daily Water Target (ml)</label>
                      <input
                        type="number"
                        value={formData.daily_water_target}
                        onChange={(e) => setFormData({ ...formData, daily_water_target: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                    </div>
                  </div>
                  <div className="flex gap-4 pt-4">
                    <motion.button
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      onClick={handleSave}
                      disabled={isSaving}
                      className="px-8 py-3 gradient-primary text-white rounded-xl font-semibold shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {isSaving ? 'Saving...' : 'Save Changes'}
                    </motion.button>
                    <motion.button
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => setIsEditing(false)}
                      className="px-8 py-3 border-2 border-gray-200 text-text-primary rounded-xl font-semibold hover:border-primary transition-colors"
                    >
                      Cancel
                    </motion.button>
                  </div>
                </div>
              ) : (
                <div className="space-y-6">
                  <div className="grid md:grid-cols-2 gap-6">
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Current Weight</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.current_weight || 0} kg</p>
                    </div>
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Target Weight</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.target_weight || 0} kg</p>
                    </div>
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Height</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.height || 0} cm</p>
                    </div>
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Age</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.age || 0} years</p>
                    </div>
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Goal</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.goal || 'N/A'}</p>
                    </div>
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Activity Level</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.activity_level || 'N/A'}</p>
                    </div>
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Daily Calorie Target</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.daily_calorie_target || 2000} kcal</p>
                    </div>
                    <div className="bg-background p-6 rounded-xl border border-gray-200">
                      <p className="text-sm text-text-secondary mb-1">Daily Water Target</p>
                      <p className="text-2xl font-bold text-text-primary">{profile?.daily_water_target || 2000} ml</p>
                    </div>
                  </div>
                  <motion.button
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => setIsEditing(true)}
                    className="w-full px-8 py-3 gradient-primary text-white rounded-xl font-semibold shadow-lg"
                  >
                    Edit Profile
                  </motion.button>
                </div>
              )}
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}


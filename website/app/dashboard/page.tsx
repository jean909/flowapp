'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';
import { motion } from 'framer-motion';
import Sidebar from '@/components/Sidebar';

interface Profile {
  full_name?: string;
  current_weight?: number;
  target_weight?: number;
  daily_calorie_target?: number;
  daily_water_target?: number;
  avatar_url?: string;
  height?: number;
  age?: number;
  goal?: string;
  coins?: number;
  plan_type?: string;
}

interface Stats {
  todayCalories: number;
  todayWater: number;
  weeklyWorkouts: number;
  currentStreak: number;
  todayProtein: number;
  todayCarbs: number;
  todayFat: number;
}

interface RecentMeal {
  id: string;
  food_name: string;
  calories: number;
  meal_type: string;
  logged_at: string;
}

export default function DashboardPage() {
  const router = useRouter();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [stats, setStats] = useState<Stats>({
    todayCalories: 0,
    todayWater: 0,
    weeklyWorkouts: 0,
    currentStreak: 0,
    todayProtein: 0,
    todayCarbs: 0,
    todayFat: 0,
  });
  const [recentMeals, setRecentMeals] = useState<RecentMeal[]>([]);
  const [weightHistory, setWeightHistory] = useState<{ date: string; weight: number }[]>([]);
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
        .select('full_name, current_weight, target_weight, daily_calorie_target, daily_water_target, avatar_url, height, age, goal, coins, plan_type')
        .eq('id', user.id)
        .single();

      if (profileData) {
        setProfile(profileData);
      }

      // Load today's data
      const today = new Date().toISOString().split('T')[0];
      const { data: logs } = await supabase
        .from('daily_logs')
        .select('id, calories, protein, carbs, fat, meal_type, logged_at, food_id, custom_food_name')
        .eq('user_id', user.id)
        .gte('logged_at', `${today}T00:00:00`)
        .order('logged_at', { ascending: false })
        .limit(10);

      const totalCalories = logs?.reduce((sum, log) => sum + (Number(log.calories) || 0), 0) || 0;
      const totalProtein = logs?.reduce((sum, log) => sum + (Number(log.protein) || 0), 0) || 0;
      const totalCarbs = logs?.reduce((sum, log) => sum + (Number(log.carbs) || 0), 0) || 0;
      const totalFat = logs?.reduce((sum, log) => sum + (Number(log.fat) || 0), 0) || 0;

      // Get food names for recent meals
      const recentMealsData: RecentMeal[] = [];
      if (logs) {
        for (const log of logs.slice(0, 5)) {
          let foodName = log.custom_food_name || 'Unknown';
          if (log.food_id) {
            const { data: food } = await supabase
              .from('general_food_flow')
              .select('name')
              .eq('id', log.food_id)
              .single();
            if (food) foodName = food.name;
          }
          recentMealsData.push({
            id: log.id || '',
            food_name: foodName,
            calories: Number(log.calories) || 0,
            meal_type: log.meal_type || '',
            logged_at: log.logged_at || '',
          });
        }
      }
      setRecentMeals(recentMealsData);

      // Load today's water
      const { data: waterLogs } = await supabase
        .from('water_logs')
        .select('amount_ml')
        .eq('user_id', user.id)
        .gte('logged_at', `${today}T00:00:00`);

      const totalWater = waterLogs?.reduce((sum, log) => sum + (Number(log.amount_ml) || 0), 0) || 0;

      // Load weight history (last 7 days)
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      const { data: weightLogs } = await supabase
        .from('weight_logs')
        .select('weight, logged_at')
        .eq('user_id', user.id)
        .gte('logged_at', weekAgo.toISOString())
        .order('logged_at', { ascending: true });

      if (weightLogs) {
        setWeightHistory(weightLogs.map(log => ({
          date: log.logged_at,
          weight: Number(log.weight),
        })));
      }

      setStats({
        todayCalories: totalCalories,
        todayWater: totalWater,
        weeklyWorkouts: 0,
        currentStreak: 0,
        todayProtein: totalProtein,
        todayCarbs: totalCarbs,
        todayFat: totalFat,
      });
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
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
        <div className="max-w-7xl mx-auto">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-8"
          >
            <h1 className="text-4xl font-bold text-text-primary mb-2">Dashboard</h1>
            <p className="text-xl text-text-secondary">Here's your wellness overview</p>
          </motion.div>

          {/* Main Stats Grid */}
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {[
            {
              title: 'Today\'s Calories',
              value: Math.round(stats.todayCalories),
              target: profile?.daily_calorie_target || 2000,
              unit: 'kcal',
              icon: '🔥',
              color: 'primary',
            },
            {
              title: 'Water Intake',
              value: stats.todayWater,
              target: profile?.daily_water_target || 2000,
              unit: 'ml',
              icon: '💧',
              color: 'accent',
            },
            {
              title: 'Protein',
              value: Math.round(stats.todayProtein),
              target: Math.round((profile?.daily_calorie_target || 2000) * 0.3 / 4),
              unit: 'g',
              icon: '💪',
              color: 'blue',
            },
            {
              title: 'Current Weight',
              value: profile?.current_weight || 0,
              target: profile?.target_weight || 0,
              unit: 'kg',
              icon: '⚖️',
              color: 'purple',
            },
          ].map((stat, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ scale: 1.03, y: -5 }}
              className="bg-surface p-6 rounded-2xl shadow-xl border border-gray-100 relative overflow-hidden"
            >
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-primary/10 to-transparent rounded-full -mr-16 -mt-16"></div>
              <div className="relative">
                <div className="flex items-center justify-between mb-4">
                  <p className="text-text-secondary font-medium">{stat.title}</p>
                  <span className="text-3xl">{stat.icon}</span>
                </div>
                <p className="text-4xl font-bold text-text-primary mb-2">
                  {stat.value}
                  <span className="text-xl text-text-secondary ml-2">{stat.unit}</span>
                </p>
                {'target' in stat && stat.target && stat.target > 0 && (
                  <div className="mt-4">
                    <div className="w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
                      <motion.div
                        initial={{ width: 0 }}
                        animate={{ width: `${Math.min((stat.value / stat.target) * 100, 100)}%` }}
                        transition={{ duration: 1, delay: index * 0.1 }}
                        className={`h-full rounded-full ${
                          stat.color === 'primary' ? 'gradient-primary' :
                          stat.color === 'accent' ? 'gradient-accent' :
                          'bg-blue-500'
                        }`}
                      ></motion.div>
                    </div>
                    <p className="text-xs text-text-secondary mt-2">
                      {Math.round((stat.value / stat.target) * 100)}% of goal
                    </p>
                  </div>
                )}
              </div>
            </motion.div>
          ))}
          </div>

          <div className="grid lg:grid-cols-3 gap-6 mb-8">
          {/* Macronutrients */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="lg:col-span-2 bg-surface p-6 rounded-2xl shadow-xl border border-gray-100"
          >
            <h2 className="text-2xl font-bold text-text-primary mb-6">Macronutrients</h2>
            <div className="space-y-4">
              {[
                { label: 'Protein', value: stats.todayProtein, target: Math.round((profile?.daily_calorie_target || 2000) * 0.3 / 4), color: 'blue', unit: 'g' },
                { label: 'Carbs', value: stats.todayCarbs, target: Math.round((profile?.daily_calorie_target || 2000) * 0.4 / 4), color: 'orange', unit: 'g' },
                { label: 'Fat', value: stats.todayFat, target: Math.round((profile?.daily_calorie_target || 2000) * 0.3 / 9), color: 'yellow', unit: 'g' },
              ].map((macro, index) => (
                <div key={index}>
                  <div className="flex justify-between mb-2">
                    <span className="text-text-secondary font-medium">{macro.label}</span>
                    <span className="text-text-primary font-semibold">
                      {Math.round(macro.value)} / {macro.target} {macro.unit}
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-3">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${Math.min((macro.value / macro.target) * 100, 100)}%` }}
                      transition={{ duration: 1, delay: 0.5 + index * 0.1 }}
                      className={`h-3 rounded-full ${
                        macro.color === 'blue' ? 'bg-blue-500' :
                        macro.color === 'orange' ? 'bg-orange-500' :
                        'bg-yellow-500'
                      }`}
                    ></motion.div>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
          </div>

          {/* Recent Meals & Weight Progress */}
          <div className="grid lg:grid-cols-2 gap-6">
          {/* Recent Meals */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            className="bg-surface p-6 rounded-2xl shadow-xl border border-gray-100"
          >
            <h2 className="text-2xl font-bold text-text-primary mb-6">Recent Meals</h2>
            {recentMeals.length > 0 ? (
              <div className="space-y-3">
                {recentMeals.map((meal, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.7 + index * 0.1 }}
                    className="flex items-center justify-between p-4 bg-background rounded-xl border border-gray-200"
                  >
                    <div>
                      <p className="font-semibold text-text-primary">{meal.food_name}</p>
                      <p className="text-sm text-text-secondary">{meal.meal_type}</p>
                    </div>
                    <p className="font-bold text-primary">{Math.round(meal.calories)} kcal</p>
                  </motion.div>
                ))}
              </div>
            ) : (
              <p className="text-text-secondary text-center py-8">No meals logged today</p>
            )}
          </motion.div>

          {/* Weight Progress */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
            className="bg-surface p-6 rounded-2xl shadow-xl border border-gray-100"
          >
            <h2 className="text-2xl font-bold text-text-primary mb-6">Weight Progress</h2>
            {weightHistory.length > 0 ? (
              <div className="space-y-4">
                <div className="flex items-end justify-between h-48">
                  {weightHistory.map((entry, index) => {
                    const maxWeight = Math.max(...weightHistory.map(e => e.weight));
                    const minWeight = Math.min(...weightHistory.map(e => e.weight));
                    const range = maxWeight - minWeight || 1;
                    const height = ((entry.weight - minWeight) / range) * 100;
                    return (
                      <motion.div
                        key={index}
                        initial={{ height: 0 }}
                        animate={{ height: `${height}%` }}
                        transition={{ duration: 0.5, delay: 0.8 + index * 0.1 }}
                        className="flex-1 mx-1 bg-gradient-to-t from-primary to-primary/50 rounded-t-lg min-h-[20px]"
                        title={`${entry.weight}kg`}
                      ></motion.div>
                    );
                  })}
                </div>
                <div className="text-center">
                  <p className="text-3xl font-bold text-text-primary">
                    {profile?.current_weight || 0} kg
                  </p>
                  {profile?.target_weight && (
                    <p className="text-text-secondary">Target: {profile.target_weight} kg</p>
                  )}
                </div>
              </div>
            ) : (
              <div className="text-center py-8">
                <p className="text-text-secondary mb-4">No weight data available</p>
                <p className="text-sm text-text-secondary">Start tracking your weight to see progress</p>
              </div>
            )}
          </motion.div>
          </div>
        </div>
      </div>
    </div>
  );
}

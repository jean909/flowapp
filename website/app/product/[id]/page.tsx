'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';
import { motion } from 'framer-motion';
import Link from 'next/link';

interface FoodProduct {
  id: string;
  name: string;
  german_name?: string;
  calories?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  fiber?: number;
  sugar?: number;
  sodium?: number;
  saturated_fat?: number;
  vitamin_a?: number;
  vitamin_c?: number;
  vitamin_d?: number;
  vitamin_e?: number;
  vitamin_k?: number;
  vitamin_b1_thiamine?: number;
  vitamin_b2_riboflavin?: number;
  vitamin_b3_niacin?: number;
  vitamin_b5_pantothenic_acid?: number;
  vitamin_b6?: number;
  vitamin_b7_biotin?: number;
  vitamin_b9_folate?: number;
  vitamin_b12?: number;
  calcium?: number;
  iron?: number;
  magnesium?: number;
  phosphorus?: number;
  potassium?: number;
  zinc?: number;
  [key: string]: any;
}

export default function ProductDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [product, setProduct] = useState<FoodProduct | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isFavorite, setIsFavorite] = useState(false);

  useEffect(() => {
    loadProduct();
  }, [params.id]);

  useEffect(() => {
    if (product?.name) {
      document.title = `${product.name} - Flow`;
    }
  }, [product?.name]);

  const loadProduct = async () => {
    try {
      const { data, error } = await supabase
        .from('general_food_flow')
        .select('*')
        .eq('id', params.id)
        .single();

      if (error) throw error;
      setProduct(data);

      // Check if favorite
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: favorite } = await supabase
          .from('favorite_foods')
          .select('id')
          .eq('user_id', user.id)
          .eq('food_id', params.id)
          .single();
        setIsFavorite(!!favorite);
      }
    } catch (error) {
      console.error('Error loading product:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleFavorite = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      router.push('/login');
      return;
    }

    try {
      if (isFavorite) {
        await supabase
          .from('favorite_foods')
          .delete()
          .eq('user_id', user.id)
          .eq('food_id', params.id);
        setIsFavorite(false);
      } else {
        await supabase
          .from('favorite_foods')
          .insert({ user_id: user.id, food_id: params.id });
        setIsFavorite(true);
      }
    } catch (error) {
      console.error('Error toggling favorite:', error);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-text-primary mb-4">Product not found</h1>
          <Link href="/search" className="text-primary hover:underline">
            Back to search
          </Link>
        </div>
      </div>
    );
  }

  const macronutrients = [
    { label: 'Calories', value: product.calories, unit: 'kcal', color: 'from-red-400 to-red-600' },
    { label: 'Protein', value: product.protein, unit: 'g', color: 'from-blue-400 to-blue-600' },
    { label: 'Carbs', value: product.carbs, unit: 'g', color: 'from-orange-400 to-orange-600' },
    { label: 'Fat', value: product.fat, unit: 'g', color: 'from-yellow-400 to-yellow-600' },
  ].filter(item => item.value !== null && item.value !== undefined);

  const micronutrients = [
    { label: 'Fiber', value: product.fiber, unit: 'g' },
    { label: 'Sugar', value: product.sugar, unit: 'g' },
    { label: 'Sodium', value: product.sodium, unit: 'mg' },
    { label: 'Saturated Fat', value: product.saturated_fat, unit: 'g' },
  ].filter(item => item.value !== null && item.value !== undefined);

  const vitamins = [
    { label: 'Vitamin A', value: product.vitamin_a, unit: 'μg', description: 'Essential for vision, immune function, and cell growth' },
    { label: 'Vitamin C', value: product.vitamin_c, unit: 'mg', description: 'Antioxidant that supports immune system and collagen production' },
    { label: 'Vitamin D', value: product.vitamin_d, unit: 'μg', description: 'Important for bone health and calcium absorption' },
    { label: 'Vitamin E', value: product.vitamin_e, unit: 'mg', description: 'Antioxidant that protects cells from damage' },
    { label: 'Vitamin K', value: product.vitamin_k, unit: 'μg', description: 'Essential for blood clotting and bone metabolism' },
    { label: 'Vitamin B1 (Thiamine)', value: product.vitamin_b1_thiamine, unit: 'mg', description: 'Helps convert nutrients into energy' },
    { label: 'Vitamin B2 (Riboflavin)', value: product.vitamin_b2_riboflavin, unit: 'mg', description: 'Important for energy production and cell function' },
    { label: 'Vitamin B3 (Niacin)', value: product.vitamin_b3_niacin, unit: 'mg', description: 'Supports metabolism and nervous system' },
    { label: 'Vitamin B5 (Pantothenic Acid)', value: product.vitamin_b5_pantothenic_acid, unit: 'mg', description: 'Essential for synthesizing coenzyme A' },
    { label: 'Vitamin B6', value: product.vitamin_b6, unit: 'mg', description: 'Involved in amino acid metabolism and brain function' },
    { label: 'Vitamin B7 (Biotin)', value: product.vitamin_b7_biotin, unit: 'μg', description: 'Important for hair, skin, and nail health' },
    { label: 'Vitamin B9 (Folate)', value: product.vitamin_b9_folate, unit: 'μg', description: 'Crucial for DNA synthesis and cell division' },
    { label: 'Vitamin B12', value: product.vitamin_b12, unit: 'μg', description: 'Essential for nerve function and red blood cell formation' },
  ].filter(item => item.value !== null && item.value !== undefined);

  const minerals = [
    { label: 'Calcium', value: product.calcium, unit: 'mg', description: 'Essential for strong bones and teeth, muscle function' },
    { label: 'Iron', value: product.iron, unit: 'mg', description: 'Necessary for oxygen transport and energy production' },
    { label: 'Magnesium', value: product.magnesium, unit: 'mg', description: 'Supports muscle and nerve function, energy production' },
    { label: 'Phosphorus', value: product.phosphorus, unit: 'mg', description: 'Important for bone health and energy storage' },
    { label: 'Potassium', value: product.potassium, unit: 'mg', description: 'Regulates fluid balance and nerve signals' },
    { label: 'Sodium', value: product.sodium, unit: 'mg', description: 'Maintains fluid balance and nerve function' },
    { label: 'Zinc', value: product.zinc, unit: 'mg', description: 'Supports immune function and wound healing' },
  ].filter(item => item.value !== null && item.value !== undefined);

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 pt-24 pb-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-5xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-6"
        >
          <Link href="/search" className="text-primary hover:underline flex items-center gap-2">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back to search
          </Link>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-surface rounded-3xl shadow-2xl overflow-hidden border border-gray-100"
        >
          {/* Header */}
          <div className="gradient-primary p-8 text-white relative overflow-hidden">
            <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-32 -mt-32"></div>
            <div className="relative z-10 flex justify-between items-start">
              <div className="flex-1">
                <h1 className="text-4xl md:text-5xl font-bold mb-2">{product.name}</h1>
                {product.german_name && (
                  <p className="text-xl opacity-90">{product.german_name}</p>
                )}
              </div>
              <motion.button
                type="button"
                onClick={toggleFavorite}
                aria-label={isFavorite ? 'Remove from favorites' : 'Add to favorites'}
                className="p-4 bg-white/20 rounded-full hover:bg-white/30 transition-colors backdrop-blur-sm"
                whileHover={{ scale: 1.1, rotate: 5 }}
                whileTap={{ scale: 0.9 }}
              >
                <svg
                  className={`w-7 h-7 ${isFavorite ? 'fill-current' : ''}`}
                  fill={isFavorite ? 'currentColor' : 'none'}
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                </svg>
              </motion.button>
            </div>
          </div>

          {/* Main Content */}
          <div className="p-8">
            {/* Macronutrients - Large Cards */}
            <div className="mb-8">
              <h2 className="text-2xl font-bold text-text-primary mb-6">Macronutrients</h2>
              <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
                {macronutrients.map((macro, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: index * 0.1 }}
                    whileHover={{ scale: 1.05, y: -5 }}
                    className={`bg-gradient-to-br ${macro.color} p-6 rounded-2xl text-white shadow-lg`}
                  >
                    <p className="text-sm opacity-90 mb-2">{macro.label}</p>
                    <p className="text-3xl font-bold">
                      {macro.value}
                      <span className="text-lg ml-1 opacity-90">{macro.unit}</span>
                    </p>
                  </motion.div>
                ))}
              </div>
            </div>

            {/* Additional Nutrients */}
            {micronutrients.length > 0 && (
              <div className="mb-8">
                <h2 className="text-2xl font-bold text-text-primary mb-6">Additional Nutrients</h2>
                <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
                  {micronutrients.map((nutrient, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.2 + index * 0.05 }}
                      whileHover={{ scale: 1.05 }}
                      className="bg-background p-4 rounded-xl border border-gray-200"
                    >
                      <p className="text-sm text-text-secondary mb-1">{nutrient.label}</p>
                      <p className="text-xl font-bold text-text-primary">
                        {nutrient.value}
                        <span className="text-sm text-text-secondary ml-1">{nutrient.unit}</span>
                      </p>
                    </motion.div>
                  ))}
                </div>
              </div>
            )}

            {/* Vitamins & Minerals */}
            <div className="grid md:grid-cols-2 gap-6">
              {vitamins.length > 0 && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                  className="bg-background p-6 rounded-2xl border border-gray-200"
                >
                  <h3 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
                    <span>💊</span> Vitamins
                  </h3>
                  <div className="space-y-4">
                    {vitamins.map((vitamin, index) => (
                      <motion.div
                        key={index}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.3 + index * 0.05 }}
                        whileHover={{ x: 5 }}
                        className="py-3 border-b border-gray-100 last:border-0"
                      >
                        <div className="flex justify-between items-start mb-1">
                          <span className="text-text-primary font-semibold">{vitamin.label}</span>
                          <span className="font-bold text-primary text-lg">
                            {vitamin.value} {vitamin.unit}
                          </span>
                        </div>
                        {vitamin.description && (
                          <p className="text-xs text-text-secondary mt-1">{vitamin.description}</p>
                        )}
                      </motion.div>
                    ))}
                  </div>
                </motion.div>
              )}

              {minerals.length > 0 && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 }}
                  className="bg-background p-6 rounded-2xl border border-gray-200"
                >
                  <h3 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
                    <span>⚡</span> Minerals
                  </h3>
                  <div className="space-y-4">
                    {minerals.map((mineral, index) => (
                      <motion.div
                        key={index}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.4 + index * 0.05 }}
                        whileHover={{ x: 5 }}
                        className="py-3 border-b border-gray-100 last:border-0"
                      >
                        <div className="flex justify-between items-start mb-1">
                          <span className="text-text-primary font-semibold">{mineral.label}</span>
                          <span className="font-bold text-primary text-lg">
                            {mineral.value} {mineral.unit}
                          </span>
                        </div>
                        {mineral.description && (
                          <p className="text-xs text-text-secondary mt-1">{mineral.description}</p>
                        )}
                      </motion.div>
                    ))}
                  </div>
                </motion.div>
              )}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}

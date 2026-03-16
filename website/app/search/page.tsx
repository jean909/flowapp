'use client';

import { useState, useEffect, Suspense } from 'react';
import { supabase } from '@/lib/supabase/client';
import { motion } from 'framer-motion';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface FoodItem {
  id: string;
  name: string;
  german_name?: string;
  calories?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
}

function SearchContent() {
  const searchParams = useSearchParams();
  const [query, setQuery] = useState(searchParams.get('q') || '');
  const [results, setResults] = useState<FoodItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);

  useEffect(() => {
    if (query) {
      handleSearch();
    }
  }, []);

  const handleSearch = async () => {
    if (query.trim().length < 2) {
      setResults([]);
      setHasSearched(false);
      return;
    }

    setIsLoading(true);
    setHasSearched(true);

    try {
      const { data, error } = await supabase
        .from('general_food_flow')
        .select('id, name, german_name, calories, protein, carbs, fat')
        .or(`name.ilike.%${query}%,german_name.ilike.%${query}%`)
        .limit(50);

      if (error) throw error;
      setResults(data || []);
    } catch (error) {
      console.error('Search error:', error);
      setResults([]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background pt-24 pb-16 px-5 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-10"
        >
          <h1 className="text-4xl md:text-5xl font-bold text-text-primary mb-3">
            Search Products
          </h1>
          <p className="text-lg md:text-xl text-text-secondary leading-relaxed">
            Find nutritional information for thousands of foods
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="mb-10"
        >
          <div className="flex flex-col sm:flex-row gap-3">
            <input
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              placeholder="Search for food products..."
              className="flex-1 min-h-[52px] px-5 py-3.5 rounded-xl border-2 border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all text-base text-text-primary placeholder:text-text-secondary/70"
              aria-label="Search food products"
            />
            <motion.button
              type="button"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={handleSearch}
              disabled={isLoading}
              className="min-h-[52px] px-8 py-3.5 gradient-primary text-white rounded-xl font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 shadow-lg shrink-0"
            >
              {isLoading ? 'Searching...' : 'Search'}
            </motion.button>
          </div>
        </motion.div>

        {isLoading && (
          <div className="flex justify-center py-16">
            <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" aria-hidden />
          </div>
        )}

        {!isLoading && hasSearched && results.length === 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center py-14 px-6 bg-surface rounded-2xl border border-gray-100"
          >
            <p className="text-text-secondary text-base leading-relaxed">No results found. Try a different search term.</p>
          </motion.div>
        )}

        {!isLoading && results.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="space-y-5"
          >
            <p className="text-text-secondary text-sm mb-1">
              Found {results.length} {results.length === 1 ? 'result' : 'results'}
            </p>
            {results.map((item, index) => (
              <Link key={item.id} href={`/product/${item.id}`}>
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.05 }}
                  whileHover={{ scale: 1.02, y: -2 }}
                  className="bg-surface p-6 rounded-2xl shadow-lg border border-gray-100 hover:border-primary/20 transition-all cursor-pointer"
                >
                  <h3 className="text-xl font-bold text-text-primary mb-2">
                    {item.name}
                    {item.german_name && (
                      <span className="text-text-secondary text-base font-normal ml-2">
                        ({item.german_name})
                      </span>
                    )}
                  </h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
                    {item.calories !== null && (
                      <div>
                        <p className="text-sm text-text-secondary">Calories</p>
                        <p className="text-lg font-semibold text-text-primary">{item.calories} kcal</p>
                      </div>
                    )}
                    {item.protein !== null && (
                      <div>
                        <p className="text-sm text-text-secondary">Protein</p>
                        <p className="text-lg font-semibold text-text-primary">{item.protein}g</p>
                      </div>
                    )}
                    {item.carbs !== null && (
                      <div>
                        <p className="text-sm text-text-secondary">Carbs</p>
                        <p className="text-lg font-semibold text-text-primary">{item.carbs}g</p>
                      </div>
                    )}
                    {item.fat !== null && (
                      <div>
                        <p className="text-sm text-text-secondary">Fat</p>
                        <p className="text-lg font-semibold text-text-primary">{item.fat}g</p>
                      </div>
                    )}
                  </div>
                </motion.div>
              </Link>
            ))}
          </motion.div>
        )}
      </div>
    </div>
  );
}

export default function SearchPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
      </div>
    }>
      <SearchContent />
    </Suspense>
  );
}


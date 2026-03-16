'use client';

import Image from 'next/image';
import { motion } from 'framer-motion';

const showcases = [
  {
    title: 'Insights & Progress Dashboard',
    subtitle: 'Advanced Analytics at Your Fingertips',
    description: 'Get comprehensive insights into your health journey with our powerful analytics dashboard. Track micronutrients with radar charts, monitor weight evolution, and keep an eye on potentially harmful intakes with our Nasties Watchdog feature.',
    image: '/insights.jpg',
    features: [
      {
        icon: '📊',
        title: 'Micronutrient Radar',
        text: 'Visualize your coverage of essential vitamins and minerals with an interactive radar chart. See at a glance which nutrients you\'re getting enough of and which need attention.',
      },
      {
        icon: '⚖️',
        title: 'Weight Evolution',
        text: 'Track your weight progress over time with detailed charts. Compare actual vs theoretical weight based on your calorie intake from the last 7 days.',
      },
      {
        icon: '⚠️',
        title: 'Nasties Watchdog',
        text: 'Monitor potentially harmful intakes like sodium, sugar, saturated fat, and caffeine. Get real-time warnings when you exceed recommended limits with actionable advice.',
      },
      {
        icon: '📈',
        title: 'Weekly Calories',
        text: 'View your calorie intake across the week with beautiful bar charts. Identify patterns and make informed decisions about your nutrition.',
      },
    ],
  },
  {
    title: 'Comprehensive Nutrition Tracking',
    subtitle: 'Every Detail Matters',
    description: 'Log meals with complete nutritional information. Track not just calories and macros, but also vitamins, minerals, and micronutrients. Get detailed breakdowns for every food item.',
    image: '/highlydetailed nutrition.jpg',
    features: [
      {
        icon: '🍎',
        title: 'Complete Food Database',
        text: 'Access thousands of foods with detailed nutritional information. Search by name in multiple languages and find exactly what you need.',
      },
      {
        icon: '💊',
        title: 'Vitamin Tracking',
        text: 'Monitor all essential vitamins including A, C, D, E, K, and the complete B-complex. Know exactly what you\'re getting from each meal.',
      },
      {
        icon: '⚡',
        title: 'Mineral Analysis',
        text: 'Track important minerals like calcium, iron, magnesium, potassium, sodium, and zinc. Understand your mineral balance for optimal health.',
      },
      {
        icon: '📋',
        title: 'Meal Logging',
        text: 'Easily log meals by meal type (breakfast, lunch, dinner, snack). See your daily totals and progress towards your goals in real-time.',
      },
    ],
  },
  {
    title: 'Recipe Discovery & Planning',
    subtitle: 'Culinary Adventures Await',
    description: 'Discover healthy recipes from around the world. Filter by cuisine type, meal category, and dietary preferences. Save favorites and create personalized meal plans.',
    image: '/recipes.jpg',
    features: [
      {
        icon: '🌍',
        title: 'Global Cuisines',
        text: 'Explore recipes from Italian, Greek, Spanish, French, German, and many more cuisines. Experience authentic flavors from around the world.',
      },
      {
        icon: '🍽️',
        title: 'Meal Categories',
        text: 'Filter recipes by meal type - breakfast, lunch, dinner, or snacks. Find the perfect dish for any time of day.',
      },
      {
        icon: '❤️',
        title: 'Favorites & Collections',
        text: 'Save your favorite recipes for quick access. Build your personal recipe collection and never lose track of dishes you love.',
      },
      {
        icon: '🔥',
        title: 'Nutritional Info',
        text: 'Every recipe includes complete nutritional information. Know the calories, macros, and cooking time before you start.',
      },
    ],
  },
  {
    title: 'Personal Health Dashboard',
    subtitle: 'Your Wellness Command Center',
    description: 'Your complete health overview in one place. Monitor your health score, track streaks, get insights from Panda Coach, and manage your active diets and programs.',
    image: '/dashboard.jpg',
    features: [
      {
        icon: '⭐',
        title: 'Health Score',
        text: 'Get a comprehensive health score out of 10 based on your nutrition, activity, and wellness metrics. Track improvements over time.',
      },
      {
        icon: '🐼',
        title: 'Panda Coach',
        text: 'Receive daily motivation and insights from your AI-powered Panda Coach. Celebrate streaks and get personalized encouragement.',
      },
      {
        icon: '🥗',
        title: 'Diets & Programs',
        text: 'Manage your active diet plans and fitness programs. Track progress and stay committed to your chosen wellness path.',
      },
      {
        icon: '💪',
        title: 'Real-time Stats',
        text: 'See your daily progress at a glance - calories consumed, protein intake, water consumption, and more. Stay on top of your goals.',
      },
    ],
  },
];

export default function AppShowcase() {
  return (
    <section className="py-32 px-4 sm:px-6 lg:px-8 bg-background relative overflow-hidden">
      <div className="max-w-7xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <h2 className="text-5xl md:text-6xl font-bold text-text-primary mb-6">
            See Flow in Action
          </h2>
          <p className="text-xl md:text-2xl text-text-secondary max-w-3xl mx-auto">
            Discover how Flow helps you understand and improve every aspect of your wellness journey
          </p>
        </motion.div>

        <div className="space-y-32">
          {showcases.map((showcase, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 50 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
              className="relative"
            >
              <div className={`grid lg:grid-cols-2 gap-16 items-center ${index % 2 === 1 ? 'lg:grid-flow-dense' : ''}`}>
                {/* Image */}
                <motion.div
                  className={index % 2 === 1 ? 'lg:col-start-2' : ''}
                  whileHover={{ scale: 1.02 }}
                >
                  <div className="relative group">
                    <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-accent/20 rounded-3xl blur-2xl group-hover:blur-3xl transition-all"></div>
                    <div className="relative bg-surface rounded-3xl overflow-hidden shadow-2xl border border-gray-100">
                      <div className="aspect-[9/16] bg-gradient-to-br from-primary/10 to-accent/10 flex items-center justify-center">
                        <Image
                          src={showcase.image}
                          alt={showcase.title}
                          width={400}
                          height={700}
                          className="w-full h-full object-cover"
                          unoptimized
                          onError={(e) => {
                            e.currentTarget.style.display = 'none';
                            const parent = e.currentTarget.parentElement;
                            if (parent) {
                              parent.innerHTML = `<div class="w-full h-full flex items-center justify-center text-4xl text-text-secondary">${showcase.title[0]}</div>`;
                            }
                          }}
                        />
                      </div>
                    </div>
                  </div>
                </motion.div>

                {/* Content */}
                <motion.div
                  className={index % 2 === 1 ? 'lg:col-start-1 lg:row-start-1' : ''}
                  initial={{ opacity: 0, x: index % 2 === 0 ? -50 : 50 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8 }}
                >
                  <div className="inline-block mb-4 px-4 py-2 bg-primary/10 border border-primary/20 rounded-full">
                    <span className="text-primary font-semibold">{showcase.subtitle}</span>
                  </div>
                  <h3 className="text-4xl md:text-5xl font-bold text-text-primary mb-6">
                    {showcase.title}
                  </h3>
                  <p className="text-lg text-text-secondary mb-8 leading-relaxed">
                    {showcase.description}
                  </p>
                  
                  <div className="grid sm:grid-cols-2 gap-4">
                    {showcase.features.map((feature, fIndex) => (
                      <motion.div
                        key={fIndex}
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ delay: fIndex * 0.1 }}
                        whileHover={{ scale: 1.02, y: -2 }}
                        className="bg-surface p-5 rounded-2xl border border-gray-100 shadow-lg"
                      >
                        <div className="text-3xl mb-3">{feature.icon}</div>
                        <h4 className="font-bold text-text-primary mb-2">{feature.title}</h4>
                        <p className="text-sm text-text-secondary leading-relaxed">{feature.text}</p>
                      </motion.div>
                    ))}
                  </div>
                </motion.div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}


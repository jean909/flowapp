'use client';

import Image from 'next/image';
import { motion } from 'framer-motion';

const features = [
  {
    title: 'Insights & Progress',
    description: 'Advanced analytics with micronutrient radar charts, weight evolution tracking, and weekly calorie insights. Monitor your health score and get personalized recommendations.',
    image: '/insights.jpg',
    highlights: ['Micronutrient Radar', 'Weight Evolution', 'Nasties Watchdog', 'Health Score'],
  },
  {
    title: 'Nutrition Tracking',
    description: 'Comprehensive food database with detailed nutritional information. Track calories, macros, vitamins, and minerals for every meal. Get AI-powered insights on your eating habits.',
    image: '/highlydetailed nutrition.jpg',
    highlights: ['Food Database', 'Macro Tracking', 'Vitamin Analysis', 'Meal Logging'],
  },
  {
    title: 'Recipes & Meal Planning',
    description: 'Discover thousands of healthy recipes from around the world. Filter by cuisine, meal type, and dietary preferences. Save favorites and create your own meal plans.',
    image: '/recipes.jpg',
    highlights: ['Recipe Browser', 'Cuisine Filters', 'Meal Planning', 'Favorites'],
  },
  {
    title: 'Dashboard & Analytics',
    description: 'Your personal health command center. View health scores, track streaks, monitor Panda Coach insights, and manage your active diets and programs all in one place.',
    image: '/dashboard.jpg',
    highlights: ['Health Score', 'Panda Coach', 'Diets & Programs', 'Real-time Stats'],
  },
  {
    title: 'Workout Tracking',
    description: 'Log exercises, track workouts, and monitor your fitness progress. Access personalized workout plans and connect with a supportive community.',
    image: '/Alarms o nutrition.jpg',
    highlights: ['Exercise Logging', 'Workout Plans', 'Progress Tracking', 'Community'],
  },
  {
    title: 'Mood & Sleep Tracking',
    description: 'Monitor your emotional wellbeing and sleep patterns. Track mood throughout the day and understand how sleep quality affects your overall health.',
    image: '/Micronutrientradar.jpg',
    highlights: ['Mood Tracking', 'Sleep Analysis', 'Pattern Recognition', 'Wellness Insights'],
  },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.15,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 50 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.6,
    },
  },
};

export default function Features() {
  return (
    <section id="features" className="py-32 px-4 sm:px-6 lg:px-8 bg-surface relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute top-0 right-0 w-[800px] h-[800px] bg-primary/5 rounded-full blur-3xl"></div>
      <div className="absolute bottom-0 left-0 w-[800px] h-[800px] bg-accent/5 rounded-full blur-3xl"></div>
      
      <div className="relative max-w-7xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-20"
        >
          <h2 className="text-5xl md:text-6xl font-bold text-text-primary mb-6">
            Powerful Features
          </h2>
          <p className="text-xl md:text-2xl text-text-secondary max-w-3xl mx-auto">
            Everything you need to transform your health journey, all in one beautiful app
          </p>
        </motion.div>
        
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="space-y-24"
        >
          {features.map((feature, index) => (
            <motion.div
              key={index}
              variants={itemVariants}
              className={`flex flex-col ${index % 2 === 0 ? 'lg:flex-row' : 'lg:flex-row-reverse'} gap-12 items-center`}
            >
              {/* Image */}
              <motion.div
                whileHover={{ scale: 1.02 }}
                className="flex-1 relative group"
              >
                <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-accent/20 rounded-3xl blur-xl group-hover:blur-2xl transition-all"></div>
                <div className="relative bg-surface rounded-3xl overflow-hidden shadow-2xl border border-gray-100">
                  <div className="aspect-video bg-gradient-to-br from-primary/20 to-accent/20 flex items-center justify-center">
                    <Image
                      src={feature.image}
                      alt={feature.title}
                      width={600}
                      height={400}
                      className="w-full h-full object-cover"
                      unoptimized
                      onError={(e) => {
                        e.currentTarget.style.display = 'none';
                        const parent = e.currentTarget.parentElement;
                        if (parent) {
                          parent.innerHTML = `<div class="w-full h-full flex items-center justify-center text-6xl">${feature.title[0]}</div>`;
                        }
                      }}
                    />
                  </div>
                </div>
              </motion.div>

              {/* Content */}
              <div className="flex-1">
                <motion.h3
                  whileHover={{ x: 5 }}
                  className="text-4xl font-bold text-text-primary mb-4"
                >
                  {feature.title}
                </motion.h3>
                <p className="text-lg text-text-secondary mb-6 leading-relaxed">
                  {feature.description}
                </p>
                <div className="grid grid-cols-2 gap-3">
                  {feature.highlights.map((highlight, hIndex) => (
                    <motion.div
                      key={hIndex}
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: hIndex * 0.1 }}
                      className="flex items-center gap-2 p-3 bg-background rounded-xl border border-gray-200"
                    >
                      <div className="w-2 h-2 rounded-full bg-primary"></div>
                      <span className="text-text-primary font-medium">{highlight}</span>
                    </motion.div>
                  ))}
                </div>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}

'use client';

import { motion } from 'framer-motion';
import Image from 'next/image';

export default function About() {
  return (
    <section id="about" className="py-32 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-background via-surface to-background relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute top-0 left-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-3xl"></div>
      <div className="absolute bottom-0 right-0 w-[600px] h-[600px] bg-accent/5 rounded-full blur-3xl"></div>
      
      <div className="relative max-w-6xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-5xl md:text-6xl font-bold text-text-primary mb-6">
            Why Choose Flow?
          </h2>
          <p className="text-xl md:text-2xl text-text-secondary max-w-3xl mx-auto">
            A comprehensive wellness platform designed to help you achieve your health goals
          </p>
        </motion.div>
        
        <div className="grid md:grid-cols-3 gap-8 mb-16">
          {[
            {
              title: 'All-in-One Platform',
              description: 'Track nutrition, workouts, mood, sleep, and more in one beautiful app. No need to switch between multiple apps.',
              icon: '🎯',
              gradient: 'from-primary to-primary-dark',
            },
            {
              title: 'AI-Powered Insights',
              description: 'Get personalized recommendations and insights powered by advanced analytics. Understand your patterns and improve faster.',
              icon: '🤖',
              gradient: 'from-accent to-accent-dark',
            },
            {
              title: 'Supportive Community',
              description: 'Connect with thousands of users on the same journey. Share progress, get motivated, and achieve goals together.',
              icon: '👥',
              gradient: 'from-primary to-accent',
            },
          ].map((item, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ scale: 1.05, y: -10 }}
              className="bg-surface p-8 rounded-3xl shadow-xl border border-gray-100 relative overflow-hidden group"
            >
              <div className={`absolute inset-0 bg-gradient-to-br ${item.gradient} opacity-0 group-hover:opacity-10 transition-opacity`}></div>
              <div className="relative z-10">
                <div className="text-5xl mb-4">{item.icon}</div>
                <h3 className="text-2xl font-bold text-text-primary mb-3">{item.title}</h3>
                <p className="text-text-secondary leading-relaxed">{item.description}</p>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Panda Fitness Section */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="grid lg:grid-cols-2 gap-12 items-center bg-surface rounded-3xl p-12 shadow-2xl border border-gray-100"
        >
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-accent/20 rounded-3xl blur-2xl"></div>
            <div className="relative">
              <Image
                src="/panda_fitness.png"
                alt="Panda Fitness"
                width={500}
                height={500}
                className="mx-auto drop-shadow-2xl"
              />
            </div>
          </div>
          
          <div>
            <h3 className="text-4xl font-bold text-text-primary mb-6">
              Your Personal Fitness Coach
            </h3>
            <p className="text-lg text-text-secondary mb-8 leading-relaxed">
              Meet Panda Coach, your AI-powered wellness companion. Get daily motivation, track your streaks, and receive personalized insights to keep you on track with your health goals.
            </p>
            <ul className="space-y-4">
              {[
                'Daily motivation and streak tracking',
                'Personalized workout recommendations',
                'Real-time progress monitoring',
                'Community support and challenges',
              ].map((item, index) => (
                <motion.li
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: index * 0.1 }}
                  className="flex items-start"
                >
                  <div className="w-6 h-6 rounded-full gradient-primary flex items-center justify-center mr-3 mt-1 flex-shrink-0">
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  <span className="text-text-secondary text-lg">{item}</span>
                </motion.li>
              ))}
            </ul>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

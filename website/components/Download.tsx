'use client';

import Image from 'next/image';
import { motion } from 'framer-motion';

export default function Download() {
  return (
    <section id="download" className="relative py-32 px-4 sm:px-6 lg:px-8 overflow-hidden">
      {/* Background with gradient */}
      <div className="absolute inset-0 gradient-primary"></div>
      
      {/* Animated decorative elements */}
      <motion.div
        animate={{
          scale: [1, 1.2, 1],
          opacity: [0.1, 0.2, 0.1],
        }}
        transition={{
          duration: 6,
          repeat: Infinity,
          ease: "easeInOut",
        }}
        className="absolute top-0 right-0 w-[500px] h-[500px] bg-white/10 rounded-full blur-3xl"
      ></motion.div>
      <motion.div
        animate={{
          scale: [1, 1.2, 1],
          opacity: [0.1, 0.2, 0.1],
        }}
        transition={{
          duration: 6,
          repeat: Infinity,
          ease: "easeInOut",
          delay: 2,
        }}
        className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-accent/20 rounded-full blur-3xl"
      ></motion.div>
      
      <div className="relative max-w-6xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="text-center lg:text-left text-white z-10"
          >
            <h2 className="text-5xl md:text-6xl font-bold mb-6 leading-tight">
              Ready to Transform
              <br />
              Your Health?
            </h2>
            <p className="text-xl md:text-2xl text-white/90 mb-10 leading-relaxed">
              Join thousands of users who are already transforming their wellness journey with Flow. Download today and take the first step towards a healthier, happier you.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <motion.a
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
                href="https://play.google.com/store/apps/details?id=com.jean909.flow.flow"
                target="_blank"
                rel="noopener noreferrer"
                className="px-10 py-5 bg-white text-primary rounded-full font-bold text-xl hover:opacity-90 transition-all shadow-2xl"
              >
                Download on Google Play
              </motion.a>
            </div>
            <div className="mt-8 flex items-center gap-8 justify-center lg:justify-start">
              {[
                { icon: '⭐', text: '4.8 Rating' },
                { icon: '👥', text: '10K+ Users' },
                { icon: '🔥', text: '50K+ Meals' },
              ].map((stat, index) => (
                <div key={index} className="text-center">
                  <p className="text-2xl mb-1">{stat.icon}</p>
                  <p className="text-white/80 text-sm">{stat.text}</p>
                </div>
              ))}
            </div>
          </motion.div>
          
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="relative z-10"
          >
            <motion.div
              animate={{
                y: [0, -20, 0],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: "easeInOut",
              }}
              className="relative"
            >
              <Image
                src="/panda.png"
                alt="Flow Panda"
                width={500}
                height={500}
                className="mx-auto drop-shadow-2xl"
              />
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

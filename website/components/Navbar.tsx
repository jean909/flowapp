'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useState, useEffect } from 'react';
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';
import { supabase } from '@/lib/supabase/client';
import type { User } from '@supabase/supabase-js';

export default function Navbar() {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const { scrollY } = useScroll();

  const navBackground = useTransform(
    scrollY,
    [0, 100],
    ['rgba(255, 255, 255, 0.85)', 'rgba(255, 255, 255, 0.98)']
  );
  const navShadow = useTransform(
    scrollY,
    [0, 100],
    ['0px 2px 10px rgba(0, 0, 0, 0.05)', '0px 8px 30px rgba(46, 204, 113, 0.12)']
  );

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => setUser(session?.user ?? null));
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });
    return () => subscription.unsubscribe();
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setIsOpen(false);
    router.push('/');
  };

  const navItems = [
    { href: '/search', label: 'Search Products' },
    { href: '/#features', label: 'Features' },
    { href: '/#about', label: 'About' },
  ];

  return (
    <motion.nav
      style={{
        backgroundColor: navBackground,
        boxShadow: navShadow,
      }}
      className="fixed top-0 left-0 right-0 z-50 backdrop-blur-xl transition-all duration-500"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-20">
          {/* Logo Section */}
          <Link href="/" className="flex items-center space-x-3 group">
            <motion.div
              whileHover={{ scale: 1.08 }}
              whileTap={{ scale: 0.95 }}
              transition={{ type: "spring", stiffness: 400, damping: 17 }}
              className="relative"
            >
              <motion.div
                className="absolute inset-0 bg-primary/20 rounded-xl blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
              />
              <Image
                src="/logo.png"
                alt="Flow Logo"
                width={50}
                height={50}
                className="relative h-12 w-12 md:h-14 md:w-14 rounded-xl drop-shadow-lg"
                priority
              />
            </motion.div>
            <motion.span
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5 }}
              className="text-2xl md:text-3xl font-bold text-primary"
            >
              FLOW
            </motion.span>
          </Link>
          
          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-2">
            {navItems.map((item, index) => (
              <motion.div
                key={item.href}
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1, duration: 0.3 }}
              >
                <Link
                  href={item.href}
                  className="relative px-4 py-2 text-text-secondary hover:text-primary transition-colors font-medium text-sm lg:text-base rounded-lg group overflow-hidden"
                >
                  <span className="relative z-10">{item.label}</span>
                  <motion.div
                    className="absolute inset-0 bg-primary/5 rounded-lg"
                    initial={{ scale: 0, opacity: 0 }}
                    whileHover={{ scale: 1, opacity: 1 }}
                    transition={{ duration: 0.2 }}
                  />
                  <motion.div
                    className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary"
                    initial={{ scaleX: 0 }}
                    whileHover={{ scaleX: 1 }}
                    transition={{ duration: 0.3, ease: "easeOut" }}
                    style={{ transformOrigin: "left" }}
                  />
                </Link>
              </motion.div>
            ))}
            
            <div className="h-8 w-px bg-gray-300 mx-2"></div>

            {user ? (
              <>
                <Link
                  href="/dashboard"
                  className="relative px-6 py-2.5 gradient-primary text-white rounded-full font-semibold text-sm lg:text-base overflow-hidden group shadow-lg"
                >
                  <span className="relative z-10">Dashboard</span>
                </Link>
                <motion.button
                  type="button"
                  onClick={handleLogout}
                  className="px-5 py-2.5 border-2 border-primary/30 text-primary rounded-full font-semibold hover:border-primary hover:bg-primary/5 transition-all text-sm lg:text-base"
                >
                  Logout
                </motion.button>
              </>
            ) : (
              <>
                <Link
                  href="/login"
                  className="relative px-5 py-2.5 border-2 border-primary/30 text-primary rounded-full font-semibold hover:border-primary hover:bg-primary/5 transition-all text-sm lg:text-base overflow-hidden group"
                >
                  <span className="relative z-10">Login</span>
                  <motion.div
                    className="absolute inset-0 bg-primary/10 rounded-full"
                    initial={{ scale: 0 }}
                    whileHover={{ scale: 1 }}
                    transition={{ duration: 0.3 }}
                  />
                </Link>
                <motion.a
                  href="https://play.google.com/store/apps/details?id=com.jean909.flow.flow"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="relative px-6 py-2.5 gradient-primary text-white rounded-full font-semibold text-sm lg:text-base overflow-hidden group shadow-lg block"
                  whileHover={{ scale: 1.05, y: -2 }}
                  whileTap={{ scale: 0.95 }}
                  transition={{ type: "spring", stiffness: 400, damping: 17 }}
                >
                  <span className="relative z-10">Get Started</span>
                  <motion.div
                    className="absolute inset-0 bg-white/20 rounded-full"
                    initial={{ x: '-100%' }}
                    whileHover={{ x: '100%' }}
                    transition={{ duration: 0.5, ease: "easeInOut" }}
                  />
                </motion.a>
              </>
            )}
          </div>
          
          {/* Mobile menu button */}
          <motion.button
            type="button"
            whileTap={{ scale: 0.95 }}
            onClick={() => setIsOpen(!isOpen)}
            className="md:hidden min-h-[44px] min-w-[44px] flex items-center justify-center rounded-xl hover:bg-primary/10 transition-colors relative"
            aria-label="Toggle menu"
            aria-expanded={isOpen}
          >
            <motion.div
              animate={{ rotate: isOpen ? 180 : 0 }}
              transition={{ duration: 0.3, ease: "easeInOut" }}
            >
              <svg className="w-6 h-6 text-text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                {isOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                )}
              </svg>
            </motion.div>
          </motion.button>
        </div>
        
        {/* Mobile Navigation */}
        <AnimatePresence>
          {isOpen && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.3, ease: "easeInOut" }}
              className="md:hidden overflow-hidden"
            >
              <div className="py-5 px-1 border-t border-gray-200/50 flex flex-col gap-1">
                {navItems.map((item, index) => (
                  <motion.div
                    key={item.href}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1, duration: 0.3 }}
                  >
                    <Link
                      href={item.href}
                      className="flex items-center min-h-[48px] px-4 py-3 text-text-secondary hover:text-primary hover:bg-primary/5 rounded-xl transition-colors font-medium"
                      onClick={() => setIsOpen(false)}
                    >
                      {item.label}
                    </Link>
                  </motion.div>
                ))}
                <div className="pt-3 flex flex-col gap-2">
                  {user ? (
                    <>
                      <Link
                        href="/dashboard"
                        className="flex items-center justify-center min-h-[48px] px-6 py-3 gradient-primary text-white rounded-xl font-semibold hover:opacity-90 transition-opacity shadow-lg"
                        onClick={() => setIsOpen(false)}
                      >
                        Dashboard
                      </Link>
                      <button
                        type="button"
                        onClick={handleLogout}
                        className="flex items-center justify-center min-h-[48px] w-full px-6 py-3 border-2 border-primary/30 text-primary rounded-xl font-semibold hover:bg-primary/5 transition-colors"
                      >
                        Logout
                      </button>
                    </>
                  ) : (
                    <>
                      <Link
                        href="/login"
                        className="flex items-center justify-center min-h-[48px] px-6 py-3 border-2 border-primary/30 text-primary rounded-xl font-semibold hover:bg-primary/5 transition-colors"
                        onClick={() => setIsOpen(false)}
                      >
                        Login
                      </Link>
                      <a
                        href="https://play.google.com/store/apps/details?id=com.jean909.flow.flow"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center justify-center min-h-[48px] px-6 py-3 gradient-primary text-white rounded-xl font-semibold hover:opacity-90 transition-opacity shadow-lg"
                        onClick={() => setIsOpen(false)}
                      >
                        Get Started
                      </a>
                    </>
                  )}
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.nav>
  );
}

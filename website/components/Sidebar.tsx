'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import Image from 'next/image';
import { motion } from 'framer-motion';

interface SidebarProps {
  profile: {
    full_name?: string;
    avatar_url?: string;
    coins?: number;
    plan_type?: string;
  } | null;
  onLogout: () => void;
}

export default function Sidebar({ profile, onLogout }: SidebarProps) {
  const pathname = usePathname();
  const [isMobileOpen, setIsMobileOpen] = useState(false);

  const menuItems = [
    { href: '/dashboard', label: 'Dashboard', icon: '📊' },
    { href: '/search', label: 'Search Products', icon: '🔍' },
    { href: '/dashboard/plans', label: 'Subscription Plans', icon: '💎' },
    { href: '/dashboard/profile', label: 'Profile Settings', icon: '👤' },
  ];

  const isActive = (href: string) => pathname === href;

  return (
    <>
      {/* Mobile menu button */}
      <button
        onClick={() => setIsMobileOpen(!isMobileOpen)}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 bg-surface rounded-lg shadow-lg border border-gray-200"
      >
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      {/* Sidebar */}
      <motion.aside
        initial={false}
        animate={{ x: isMobileOpen ? 0 : (typeof window !== 'undefined' && window.innerWidth >= 1024 ? 0 : -300) }}
        className="fixed left-0 top-0 h-full w-64 bg-surface border-r border-gray-200 shadow-xl z-40 lg:translate-x-0"
      >
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center gap-3 mb-4">
              {profile?.avatar_url ? (
                <Image
                  src={profile.avatar_url}
                  alt="Profile"
                  width={48}
                  height={48}
                  className="rounded-full border-2 border-primary"
                  unoptimized
                />
              ) : (
                <div className="w-12 h-12 rounded-full gradient-primary flex items-center justify-center text-white font-bold">
                  {profile?.full_name?.[0] || 'U'}
                </div>
              )}
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-text-primary truncate">
                  {profile?.full_name || 'User'}
                </p>
                <p className="text-sm text-text-secondary">
                  {profile?.plan_type || 'free'} plan
                </p>
              </div>
            </div>
            {profile?.coins !== undefined && (
              <div className="flex items-center gap-2 px-3 py-2 bg-accent/10 rounded-lg border border-accent/20">
                <span className="text-xl">🪙</span>
                <span className="font-bold text-text-primary">{profile.coins}</span>
                <span className="text-sm text-text-secondary">coins</span>
              </div>
            )}
          </div>

          {/* Menu Items */}
          <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
            {menuItems.map((item, index) => (
              <Link key={index} href={item.href} onClick={() => setIsMobileOpen(false)}>
                <motion.div
                  whileHover={{ x: 5 }}
                  whileTap={{ scale: 0.98 }}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                    isActive(item.href)
                      ? 'bg-primary text-white shadow-lg'
                      : 'text-text-secondary hover:bg-background hover:text-primary'
                  }`}
                >
                  <span className="text-xl">{item.icon}</span>
                  <span className="font-medium">{item.label}</span>
                </motion.div>
              </Link>
            ))}
          </nav>

          {/* Footer */}
          <div className="p-4 border-t border-gray-200">
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={onLogout}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-error hover:bg-error/10 transition-colors"
            >
              <span>🚪</span>
              <span className="font-medium">Logout</span>
            </motion.button>
          </div>
        </div>
      </motion.aside>

      {/* Overlay for mobile */}
      {isMobileOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setIsMobileOpen(false)}
          className="fixed inset-0 bg-black/50 z-30 lg:hidden"
        />
      )}
    </>
  );
}


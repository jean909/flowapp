import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Set root directory to prevent scanning parent directories
  turbopack: {
    root: process.cwd(),
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'zoaeypxhumpllhpasgun.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },
};

export default nextConfig;

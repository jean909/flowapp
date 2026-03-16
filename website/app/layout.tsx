import type { Metadata } from "next";
import "./globals.css";
import { ToastProvider } from "@/components/Toast";

export const metadata: Metadata = {
  title: "Flow - Your All-in-One Wellness Companion",
  description: "Track nutrition, workouts, mood, and more. Transform your health journey with Flow.",
  keywords: ["health", "wellness", "fitness", "nutrition", "tracking", "app"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}

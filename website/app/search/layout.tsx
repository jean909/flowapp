import type { Metadata } from "next";
import Navbar from "@/components/Navbar";

export const metadata: Metadata = {
  title: "Search Products - Flow | Find Nutritional Information",
  description: "Search thousands of food products and get detailed nutritional information including calories, protein, carbs, and fat. Find the perfect foods for your wellness journey.",
  keywords: ["food search", "nutritional information", "calories", "protein", "carbs", "food database", "healthy foods"],
  openGraph: {
    title: "Search Products - Flow",
    description: "Search thousands of food products and get detailed nutritional information",
    type: "website",
  },
};

export default function SearchLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Navbar />
      {children}
    </>
  );
}


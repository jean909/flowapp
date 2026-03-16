-- Create coin_packages table
CREATE TABLE IF NOT EXISTS public.coin_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coins_amount INTEGER NOT NULL,
    price_value DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    is_popular BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create subscription_plans table
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id TEXT PRIMARY KEY, -- 'free', 'premium', 'creator'
    name TEXT NOT NULL,
    description TEXT,
    monthly_coin_cost INTEGER NOT NULL,
    perks JSONB DEFAULT '[]'::jsonb,
    color_hex TEXT DEFAULT '#808080'
);

-- Enable RLS
ALTER TABLE public.coin_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Allow public read access" ON public.coin_packages FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON public.subscription_plans FOR SELECT USING (true);


-- Storage for Avatars
-- Note: You must manually create the 'avatars' bucket in the Supabase Dashboard if it doesn't exist.

-- Policy: Public can view avatars
CREATE POLICY "Public Avatars" ON storage.objects FOR SELECT USING ( bucket_id = 'avatars' );

-- Policy: Users can upload their own avatar
CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own avatar
CREATE POLICY "Users can update own avatar" ON storage.objects FOR UPDATE USING (
    bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own avatar
CREATE POLICY "Users can delete own avatar" ON storage.objects FOR DELETE USING (
    bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Add avatar_url to profiles if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
    END IF;
END $$;

-- Insert default coin packages (USD)
INSERT INTO public.coin_packages (coins_amount, price_value, currency, is_popular) VALUES
(100, 1.99, 'USD', false),
(500, 7.99, 'USD', true),
(1000, 14.99, 'USD', false);

-- Insert default subscription plans
INSERT INTO public.subscription_plans (id, name, description, monthly_coin_cost, perks, color_hex) VALUES
('free', 'Free', 'Essential features for everyone', 0, '["Tracker", "Basic Stats"]', '#9E9E9E'),
('premium', 'Premium', 'Advanced analytics & all trackers', 100, '["All Trackers", "Advanced Stats", "No Ads"]', '#FFC107'),
('creator', 'Creator', 'Design & sell your own plans', 250, '["All Premium Features", "Plan Builder", "Sales Analytics"]', '#E040FB');

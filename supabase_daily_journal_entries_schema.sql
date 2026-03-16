-- Create daily_journal_entries table for Daily Journal feature
CREATE TABLE IF NOT EXISTS public.daily_journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    raw_text TEXT NOT NULL,
    structured_data JSONB,
    language TEXT DEFAULT 'en',
    audio_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.daily_journal_entries ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY IF NOT EXISTS "Users can insert their own journal entries"
ON public.daily_journal_entries FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can view their own journal entries"
ON public.daily_journal_entries FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update their own journal entries"
ON public.daily_journal_entries FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can delete their own journal entries"
ON public.daily_journal_entries FOR DELETE
USING (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_daily_journal_entries_user_id ON public.daily_journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_journal_entries_entry_date ON public.daily_journal_entries(entry_date);

COMMENT ON TABLE public.daily_journal_entries IS 'Daily journal entries with AI-processed structured data';
COMMENT ON COLUMN public.daily_journal_entries.raw_text IS 'Original text from user (transcribed or typed)';
COMMENT ON COLUMN public.daily_journal_entries.structured_data IS 'AI-processed structured data (workouts, meals, water, etc.)';


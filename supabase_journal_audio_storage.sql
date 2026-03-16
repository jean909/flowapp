-- Create journal_audio storage bucket for Daily Journal feature
-- Note: You must manually create the 'journal_audio' bucket in Supabase Dashboard if it doesn't exist.
-- IMPORTANT: Set the bucket to PUBLIC in Supabase Dashboard so Replicate can access the audio files.

-- Make bucket public (if not already)
UPDATE storage.buckets SET public = true WHERE id = 'journal_audio';

-- Policy: Users can upload their own journal audio
CREATE POLICY IF NOT EXISTS "Users can upload own journal audio" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'journal_audio' AND auth.uid() IS NOT NULL
);

-- Policy: Public can view journal audio (needed for Replicate to access)
CREATE POLICY IF NOT EXISTS "Public can view journal audio" ON storage.objects FOR SELECT USING (
    bucket_id = 'journal_audio'
);

-- Policy: Users can delete their own journal audio
CREATE POLICY IF NOT EXISTS "Users can delete own journal audio" ON storage.objects FOR DELETE USING (
    bucket_id = 'journal_audio' AND auth.uid() IS NOT NULL
);


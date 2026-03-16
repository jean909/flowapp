-- Add is_archived column to social_posts table

-- Add is_archived column to social_posts table
ALTER TABLE public.social_posts
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT false;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_social_posts_is_archived ON public.social_posts(is_archived) WHERE is_archived = false;


-- CORRECTED: Fix comment counts sync issue
-- This script first ensures the column exists, then sets up the triggers

-- 1. Ensure comments_count column exists in social_posts
ALTER TABLE public.social_posts
ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;

-- 2. Create the function to INCREMENT count
CREATE OR REPLACE FUNCTION handle_new_comment()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.social_posts 
  SET comments_count = COALESCE(comments_count, 0) + 1 
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create the trigger for INSERT
DROP TRIGGER IF EXISTS on_comment_added ON public.social_comments;
CREATE TRIGGER on_comment_added
  AFTER INSERT ON public.social_comments
  FOR EACH ROW EXECUTE PROCEDURE handle_new_comment();

-- 4. Create function to DECREMENT count
CREATE OR REPLACE FUNCTION handle_comment_deleted()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.social_posts 
  SET comments_count = GREATEST(0, COALESCE(comments_count, 0) - 1) 
  WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 5. Create the trigger for DELETE
DROP TRIGGER IF EXISTS on_comment_removed ON public.social_comments;
CREATE TRIGGER on_comment_removed
  AFTER DELETE ON public.social_comments
  FOR EACH ROW EXECUTE PROCEDURE handle_comment_deleted();

-- 6. INITIAL SYNC: Calculate current comment counts for all posts
UPDATE public.social_posts p
SET comments_count = (
  SELECT count(*) 
  FROM public.social_comments c 
  WHERE c.post_id = p.id
);
